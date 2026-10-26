<?php

namespace App\Http\Controllers\Api\Officer;

use App\Http\Controllers\Api\Concerns\RespondsWithErrors;
use App\Http\Controllers\Controller;
use App\Models\InspectionAssignment;
use App\Models\InspectionReport;
use App\Services\ReportPresenter;
use App\Services\ReportWorkflow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Laporan BA milik petugas yang masuk. Draf ada di server hanya saat dikirim. */
class ReportController extends Controller
{
    use RespondsWithErrors;

    public function __construct(
        private readonly ReportWorkflow $workflow,
        private readonly ReportPresenter $presenter,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $request->validate(['per_page' => ['nullable', 'integer', 'between:1,50']]);

        $page = InspectionReport::query()
            ->where('officer_id', $request->user()->id)
            ->with('photos')
            ->orderByDesc('updated_at')->orderByDesc('id')
            ->paginate($request->integer('per_page', 20));

        return response()->json([
            'data' => $page->getCollection()->map(fn ($r) => $this->presenter->summary($r))->all(),
            'meta' => ['page' => $page->currentPage(), 'per_page' => $page->perPage(), 'total' => $page->total()],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $key = (string) $request->header('Idempotency-Key');
        if (!preg_match('/^[0-9a-fA-F-]{36}$/', $key)) {
            return $this->error('ERR-010', 'Header Idempotency-Key (UUID) wajib diisi.', 422, [
                'fields' => ['idempotency_key' => ['Wajib berupa UUID.']],
            ]);
        }

        $officer = $request->user();
        $existing = InspectionReport::where('officer_id', $officer->id)->where('client_uuid', $key)->first();
        if ($existing) {
            return response()->json(['data' => $this->presenter->detail($existing)]);
        }

        $data = $request->validate([
            'assignment_id' => ['nullable', 'integer'],
            'submission_number' => ['nullable', 'string', 'max:20'],
            'nama_perumahan' => ['nullable', 'string', 'max:150'],
            'monitoring_date' => ['nullable', 'date'],
        ]);

        $assignment = $this->resolveAssignment($officer->id, $data);
        if (($data['assignment_id'] ?? $data['submission_number'] ?? null) && !$assignment) {
            abort(404);
        }

        // Satu draf per tugas: bila sudah ada, dikembalikan (bukan dibuat ganda).
        if ($assignment) {
            $open = InspectionReport::where('assignment_id', $assignment->id)->where('status', 'draft')->first();
            if ($open) {
                return response()->json(['data' => $this->presenter->detail($open)]);
            }
        }

        $submission = $assignment?->submission;
        $profile = $submission?->developer?->developerProfile;

        $report = InspectionReport::create([
            'client_uuid' => $key,
            'assignment_id' => $assignment?->id,
            'submission_id' => $submission?->id,
            'officer_id' => $officer->id,
            'monitoring_date' => $data['monitoring_date'] ?? now()->toDateString(),
            'nama_perumahan' => $data['nama_perumahan'] ?? $submission?->nama_perumahan ?? $profile?->nama_perumahan ?? '',
            'lokasi' => $submission?->alamat_proyek ?? $profile?->alamat_perumahan,
            'status' => 'draft',
            'version' => 1,
        ]);
        $report->forceFill(['tim_pelaksana' => $this->workflow->team($report->load('assignment', 'officer'))])->save();

        return response()->json(['data' => $this->presenter->detail($report)], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        return response()->json(['data' => $this->presenter->detail($this->own($request, $id))]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $report = $this->own($request, $id);

        $list = fn (int $max) => ['nullable', 'array', "max:$max"];
        $data = $request->validate([
            'version' => ['required', 'integer'],
            'monitoring_date' => ['nullable', 'date'],
            'nama_perumahan' => ['nullable', 'string', 'max:150'],
            'lokasi' => ['nullable', 'string', 'max:250'],
            'maksud_tujuan' => ['nullable', 'string', 'max:2000'],
            'temuan' => $list(20), 'temuan.*' => ['string', 'max:1000'],
            'kesimpulan' => $list(20), 'kesimpulan.*' => ['string', 'max:2000'],
            'kesepakatan' => $list(20), 'kesepakatan.*' => ['string', 'max:1000'],
            'rtl' => $list(20), 'rtl.*' => ['string', 'max:1000'],
            'status_hasil_evaluasi' => ['nullable', Rule::in(InspectionReport::EVALUASI)],
            'pihak_ditemui' => $list(10), 'pihak_ditemui.*.nama' => ['nullable', 'string', 'max:150'], 'pihak_ditemui.*.jabatan' => ['nullable', 'string', 'max:150'],
        ]);

        if (!$report->isDraft()) {
            return $this->error('ERR-011', 'Laporan yang sudah dikirim tidak dapat diubah.', 409);
        }
        if ($data['version'] !== $report->version) {
            return $this->versionConflict($report->version);
        }

        unset($data['version']);
        // Tim pelaksana ditetapkan server; isian klien (bila ada) diabaikan.
        $report->forceFill($data + ['tim_pelaksana' => $this->workflow->team($report), 'version' => $report->version + 1])->save();

        return response()->json(['data' => $this->presenter->detail($report->fresh())]);
    }

    public function submit(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
        ]);

        $report = $this->workflow->submit(
            $this->own($request, $id),
            (float) $data['latitude'],
            (float) $data['longitude'],
        );

        return response()->json(['data' => $this->presenter->detail($report->fresh())]);
    }

    /** @param array<string, mixed> $data */
    private function resolveAssignment(int $officerId, array $data): ?InspectionAssignment
    {
        $query = InspectionAssignment::where('officer_id', $officerId)
            ->whereIn('status', InspectionAssignment::OPEN)
            ->with('submission.developer.developerProfile');

        if (!empty($data['assignment_id'])) {
            return $query->whereKey($data['assignment_id'])->first();
        }
        if (!empty($data['submission_number'])) {
            return $query->whereHas('submission', fn ($s) => $s->where('number', $data['submission_number']))
                ->orderBy('scheduled_date')->first();
        }

        return null;
    }

    private function own(Request $request, int $id): InspectionReport
    {
        return InspectionReport::where('officer_id', $request->user()->id)->findOrFail($id);
    }
}

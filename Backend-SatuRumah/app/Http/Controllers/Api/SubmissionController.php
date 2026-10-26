<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\RespondsWithErrors;
use App\Http\Controllers\Controller;
use App\Models\Submission;
use App\Services\SubmissionPresenter;
use App\Services\SubmissionWorkflow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Pengajuan milik pengembang yang sedang masuk (objek orang lain → 404). */
class SubmissionController extends Controller
{
    use RespondsWithErrors;

    public const TIPE_PERUMAHAN = ['subsidi', 'komersil', 'subsidi_komersil'];

    public function __construct(
        private readonly SubmissionWorkflow $workflow,
        private readonly SubmissionPresenter $presenter,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'stage' => ['nullable', 'integer', 'between:1,6'],
            'sub_status' => ['nullable', 'string', 'max:30'],
            'q' => ['nullable', 'string', 'max:100'],
            'per_page' => ['nullable', 'integer', 'between:1,50'],
            'detail' => ['nullable', 'boolean'],
        ]);

        $query = Submission::query()
            ->where('developer_id', $request->user()->id)
            ->with('developer.developerProfile', 'currentFiles')
            ->when($request->filled('stage'), fn ($q) => $q->where('stage', $request->integer('stage')))
            ->when($request->filled('sub_status'), fn ($q) => $q->where('sub_status', $request->input('sub_status')))
            ->when($request->filled('q'), function ($q) use ($request) {
                $term = '%' . $request->input('q') . '%';
                $q->where(fn ($w) => $w->where('number', 'like', $term)
                    ->orWhereHas('developer.developerProfile', fn ($p) => $p->where('nama_perumahan', 'like', $term)));
            })
            ->orderByDesc('updated_at')
            ->orderByDesc('id');

        $page = $query->paginate($request->integer('per_page', 20));

        return response()->json([
            // detail=1: sertakan berkas aktif tiap pengajuan (satu panggilan untuk daftar lengkap).
            'data' => $page->getCollection()->map(fn (Submission $s) => $request->boolean('detail')
                ? $this->presenter->detail($s)
                : $this->presenter->summary($s))->all(),
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

        $existing = Submission::where('developer_id', $request->user()->id)->where('client_uuid', $key)->first();
        if ($existing) {
            return response()->json(['data' => $this->presenter->detail($existing)]);
        }

        // Nilai bawaan dari profil; pengembang bebas mengubahnya per pengajuan.
        $profile = $request->user()->developerProfile;

        $submission = Submission::create([
            'developer_id' => $request->user()->id,
            'client_uuid' => $key,
            'nama_perumahan' => $profile?->nama_perumahan,
            'alamat_proyek' => $profile?->alamat_perumahan,
            'tipe_pengajuan' => $profile?->tipe_pengajuan,
            'stage' => Submission::STAGE_DRAFT,
            'sub_status' => 'draft',
            'current_step' => 1,
            'version' => 1,
        ]);

        return response()->json(['data' => $this->presenter->detail($submission)], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        return response()->json(['data' => $this->presenter->detail($this->own($request, $id))]);
    }

    /** Riwayat peristiwa pengajuan untuk pemiliknya (terbaru dahulu). */
    public function timeline(Request $request, int $id): JsonResponse
    {
        $events = $this->own($request, $id)->events()->with('actor:id,name')->limit(200)->get();

        return response()->json(['data' => $events->map(fn ($e) => [
            'id' => $e->id,
            'type' => $e->type,
            'title' => $e->title,
            'description' => $e->description,
            'actor' => $e->actor?->name,
            'created_at' => $e->created_at?->toIso8601String(),
        ])->values()]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $submission = $this->own($request, $id);

        $data = $request->validate([
            'version' => ['required', 'integer'],
            'nama_perumahan' => ['nullable', 'string', 'max:150'],
            'alamat_proyek' => ['nullable', 'string', 'max:500'],
            'tipe_pengajuan' => ['nullable', 'string', 'max:40'],
            'daya_listrik' => ['nullable', 'string', 'max:20'],
            'npwp' => ['nullable', 'string', 'max:20'],
            'luas_lahan' => ['nullable', 'numeric', 'min:0'],
            'jumlah_unit' => ['nullable', 'integer', 'min:1'],
            'tipe_perumahan' => ['nullable', Rule::in(self::TIPE_PERUMAHAN)],
            'current_step' => ['nullable', 'integer', 'between:1,5'],
        ]);

        if (!$submission->isDraft()) {
            return $this->error('ERR-011', 'Pengajuan yang sudah dikirim tidak dapat diubah dari sini.', 409);
        }
        if ($data['version'] !== $submission->version) {
            return $this->versionConflict($submission->version);
        }

        $changes = array_intersect_key($data, array_flip([
            'nama_perumahan', 'alamat_proyek', 'tipe_pengajuan', 'daya_listrik',
            'npwp', 'luas_lahan', 'jumlah_unit', 'tipe_perumahan', 'current_step',
        ]));
        $submission->forceFill($changes + ['version' => $submission->version + 1])->save();

        return response()->json(['data' => $this->presenter->detail($submission->fresh())]);
    }

    public function submit(Request $request, int $id): JsonResponse
    {
        $submission = $this->workflow->submit($this->own($request, $id));

        return response()->json(['data' => $this->presenter->detail($submission->fresh())]);
    }

    public function resubmit(Request $request, int $id): JsonResponse
    {
        try {
            $submission = $this->workflow->resubmit($this->own($request, $id));
        } catch (\DomainException $e) {
            return $this->error('ERR-011', $e->getMessage(), 409);
        }

        return response()->json(['data' => $this->presenter->detail($submission->fresh())]);
    }

    private function own(Request $request, int $id): Submission
    {
        return Submission::where('developer_id', $request->user()->id)->findOrFail($id);
    }
}

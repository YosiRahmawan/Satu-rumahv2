<?php

namespace App\Http\Controllers\Api\Officer;

use App\Http\Controllers\Api\Concerns\RespondsWithErrors;
use App\Http\Controllers\Controller;
use App\Models\InspectionReport;
use App\Models\ReportSignature;
use App\Services\ReportPresenter;
use App\Services\SignatureService;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/** Persetujuan elektronik BA oleh Ketua Pengawas (petugas utama pemilik laporan). */
class ReportSignatureController extends Controller
{
    use RespondsWithErrors;

    public function __construct(
        private readonly SignatureService $signatures,
        private readonly ReportPresenter $presenter,
    ) {
    }

    public function sign(Request $request, int $id): JsonResponse
    {
        if (!preg_match('/^[0-9a-fA-F-]{36}$/', (string) $request->header('Idempotency-Key'))) {
            return $this->error('ERR-010', 'Header Idempotency-Key (UUID) wajib diisi.', 422, ['fields' => ['idempotency_key' => ['Wajib berupa UUID.']]]);
        }
        $data = $request->validate([
            'method' => ['required', 'in:draw,upload'],
            'password' => ['required', 'string'],
            'version' => ['required', 'integer'],
        ]);
        $report = InspectionReport::where('officer_id', $request->user()->id)->findOrFail($id);

        try {
            $this->signatures->sign(
                $report, $request->user(), ReportSignature::KETUA, $data['method'],
                $this->signatures->bytesFrom($request), $data['password'], (int) $data['version'], $request->ip(),
            );
        } catch (AuthorizationException $e) {
            return $this->error('ERR-022', $e->getMessage(), 403);
        } catch (\DomainException $e) {
            return $this->error('ERR-011', $e->getMessage(), 409);
        }

        return response()->json(['data' => $this->presenter->detail($report->fresh())]);
    }

    /** PDF final BA yang sudah diterbitkan, hanya untuk pemilik laporan. */
    public function pdf(Request $request, int $id)
    {
        $report = InspectionReport::where('officer_id', $request->user()->id)->findOrFail($id);
        abort_unless($report->published_at && $report->pdf_path && Storage::disk(SignatureService::DISK)->exists($report->pdf_path), 404);

        return Storage::disk(SignatureService::DISK)->download($report->pdf_path, 'BA-' . str_replace('/', '-', (string) $report->report_number) . '.pdf');
    }
}

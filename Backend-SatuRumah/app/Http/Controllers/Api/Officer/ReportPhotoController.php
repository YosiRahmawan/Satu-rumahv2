<?php

namespace App\Http\Controllers\Api\Officer;

use App\Http\Controllers\Api\Concerns\RespondsWithErrors;
use App\Http\Controllers\Controller;
use App\Models\InspectionReport;
use App\Models\Setting;
use App\Services\GeoStampVerifier;
use App\Services\ReportPresenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Foto geotag laporan. Berkas disimpan apa adanya (jangan dikompres ulang,
 * itu merusak tanda tangan); lokasi, waktu, dan alamat diambil dari tanda
 * tangan di dalam JPEG, bukan dari isian klien.
 */
class ReportPhotoController extends Controller
{
    use RespondsWithErrors;

    private const DISK = 'local';

    public function __construct(
        private readonly GeoStampVerifier $verifier,
        private readonly ReportPresenter $presenter,
    ) {
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $report = $this->own($request, $id);

        $data = $request->validate([
            'file' => ['required', 'file'],
            'source' => ['nullable', 'in:camera,gallery'],
        ]);

        if (!$report->isDraft()) {
            return $this->error('ERR-011', 'Foto laporan yang sudah dikirim tidak dapat diubah.', 409);
        }

        $max = Setting::getInt('upload.photo_max_count', 10);
        if ($report->photos()->count() >= $max) {
            return $this->error('ERR-012', "Maksimal {$max} foto per laporan.", 422);
        }

        $file = $data['file'];
        $maxMb = Setting::getInt('upload.photo_max_mb', 10);
        if ($file->getSize() > $maxMb * 1024 * 1024) {
            return $this->error('ERR-001', "Ukuran foto melebihi {$maxMb} MB.", 422);
        }

        $bytes = (string) file_get_contents($file->getRealPath());
        $check = $this->verifier->verify($bytes);
        if ($check['status'] !== GeoStampVerifier::OK) {
            return $this->error('ERR-012', match ($check['status']) {
                GeoStampVerifier::NOT_JPEG => 'Foto harus berformat JPEG dari kamera aplikasi.',
                GeoStampVerifier::MISSING => 'Tidak ada geotag Satu Rumah pada foto ini. Ambil fotonya lewat kamera aplikasi.',
                default => 'Foto diubah setelah diberi geotag, jadi tidak diterima.',
            }, 422);
        }

        $checksum = hash('sha256', $bytes);
        if ($report->photos()->where('checksum', $checksum)->exists()) {
            return $this->error('ERR-012', 'Foto ini sudah ada di laporan.', 422);
        }

        $stamp = $check['stamp'];
        $storedName = (string) Str::uuid() . '.jpg';
        $path = "reports/{$report->id}/{$storedName}";
        Storage::disk(self::DISK)->put($path, $bytes);

        $photo = $report->photos()->create([
            'position' => ($report->photos()->max('position') ?? 0) + 1,
            'stored_name' => $storedName,
            'storage_path' => $path,
            'size_bytes' => strlen($bytes),
            'checksum' => $checksum,
            'latitude' => $stamp['lat'],
            'longitude' => $stamp['lng'],
            'accuracy_m' => $stamp['acc'],
            'captured_at' => $stamp['captured_at'],
            'address' => $stamp['address'],
            'note' => $stamp['note'],
            'source' => $data['source'] ?? 'camera',
        ]);

        return response()->json(['data' => $this->presenter->photo($photo)], 201);
    }

    public function destroy(Request $request, int $id, int $photoId): JsonResponse
    {
        $report = $this->own($request, $id);
        $photo = $report->photos()->findOrFail($photoId);

        if (!$report->isDraft()) {
            return $this->error('ERR-011', 'Foto laporan yang sudah dikirim tidak dapat dihapus.', 409);
        }

        Storage::disk(self::DISK)->delete($photo->storage_path);
        $photo->delete();

        return response()->json(['message' => 'Foto dihapus.']);
    }

    public function file(Request $request, int $id, int $photoId): StreamedResponse
    {
        $photo = $this->own($request, $id)->photos()->findOrFail($photoId);

        abort_unless(Storage::disk(self::DISK)->exists($photo->storage_path), 404);

        return Storage::disk(self::DISK)->response($photo->storage_path, "foto-{$photo->position}.jpg", [
            'Content-Type' => 'image/jpeg',
        ]);
    }

    private function own(Request $request, int $id): InspectionReport
    {
        return InspectionReport::where('officer_id', $request->user()->id)->findOrFail($id);
    }
}

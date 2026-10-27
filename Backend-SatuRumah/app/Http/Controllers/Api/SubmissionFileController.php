<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\RespondsWithErrors;
use App\Http\Controllers\Controller;
use App\Models\Submission;
use App\Services\SubmissionFileValidator;
use App\Services\SubmissionPresenter;
use App\Services\SubmissionWorkflow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/** Berkas pengajuan. Disk privat: tidak ada URL publik, unduhan lewat endpoint ini. */
class SubmissionFileController extends Controller
{
    use RespondsWithErrors;

    private const DISK = 'local';

    public function __construct(
        private readonly SubmissionWorkflow $workflow,
        private readonly SubmissionFileValidator $validator,
        private readonly SubmissionPresenter $presenter,
    ) {
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $submission = $this->own($request, $id);

        $data = $request->validate([
            'slot_code' => ['required', 'string', 'max:5'],
            'file' => ['required', 'file'],
            'replaces_file_id' => ['nullable', 'integer'],
        ]);

        $slotCode = $data['slot_code'];
        $current = $submission->currentFiles()->where('slot_code', $slotCode)->get();

        // Saat revisi hanya slot yang diminta diperbaiki yang boleh diganti.
        if (!$submission->isDraft()) {
            $needsFix = $submission->isInRevision() && $current->contains('status', 'perlu_perbaikan');
            if (!$needsFix) {
                return $this->error('ERR-011', 'Berkas ini tidak dapat diubah pada tahap sekarang.', 409);
            }
        }

        $errors = $this->validator->validate($data['file'], $slotCode, $current->count());
        if ($errors) {
            return $this->error($errors[0]['code'], $errors[0]['message'], 422);
        }

        $file = $data['file'];
        $storedName = $this->validator->storedName($file);
        $dir = "submissions/{$submission->id}";
        $checksum = hash_file('sha256', $file->getRealPath());
        Storage::disk(self::DISK)->putFileAs($dir, $file, $storedName);

        $record = $this->workflow->attachFile($submission, $slotCode, [
            'original_name' => $this->validator->sanitizeOriginalName($file->getClientOriginalName()),
            'stored_name' => $storedName,
            'storage_path' => "{$dir}/{$storedName}",
            'file_type' => strtolower($file->getClientOriginalExtension()),
            'size_bytes' => $file->getSize(),
            'checksum' => $checksum,
        ], $request->user()->id, $data['replaces_file_id'] ?? null);

        return response()->json(['data' => $this->presenter->file($record)], 201);
    }

    public function destroy(Request $request, int $id, int $fileId): JsonResponse
    {
        $submission = $this->own($request, $id);
        $file = $submission->currentFiles()->findOrFail($fileId);

        if (!$submission->isDraft()) {
            return $this->error('ERR-011', 'Berkas pengajuan yang sudah dikirim tidak dapat dihapus.', 409);
        }

        Storage::disk(self::DISK)->delete($file->storage_path);
        $file->delete();

        return response()->json(['message' => 'Berkas dihapus.']);
    }

    public function download(Request $request, int $id, int $fileId): StreamedResponse
    {
        $file = $this->own($request, $id)->files()->findOrFail($fileId);

        abort_unless(Storage::disk(self::DISK)->exists($file->storage_path), 404);

        return Storage::disk(self::DISK)->download($file->storage_path, $file->original_name);
    }

    private function own(Request $request, int $id): Submission
    {
        return Submission::where('developer_id', $request->user()->id)->findOrFail($id);
    }
}

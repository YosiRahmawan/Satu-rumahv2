<?php

namespace App\Services;

use App\Models\Submission;
use App\Models\SubmissionFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Satu-satunya tempat aturan perpindahan tahap pengajuan. API (Flutter) dan
 * Web Admin harus memanggil kelas ini agar aturannya tidak ganda.
 */
class SubmissionWorkflow
{
    public function __construct(
        private readonly NumberGenerator $numbers,
        private readonly SubmissionFileValidator $files,
    ) {
    }

    /** @return array<string, array<string, mixed>> katalog slot (config) */
    public function slots(): array
    {
        return config('satu_rumah.slots');
    }

    /** Kode slot wajib yang belum punya berkas aktif. @return list<string> */
    public function missingSlots(Submission $submission): array
    {
        $filled = $submission->currentFiles()->pluck('slot_code')->unique()->all();

        return array_values(array_filter(
            array_keys($this->slots()),
            fn (string $code) => ($this->slots()[$code]['required'] ?? true) && !in_array($code, $filled, true)
        ));
    }

    /** Draf → Verifikasi Administrasi. Menerbitkan nomor pengajuan. */
    public function submit(Submission $submission): Submission
    {
        if ($submission->stage !== Submission::STAGE_DRAFT) {
            return $submission; // idempoten: sudah terkirim
        }

        $problems = [];

        $profile = $submission->developer->developerProfile;
        if (!$profile) {
            $problems['profile'] = ['Lengkapi profil perusahaan dan perumahan terlebih dahulu.'];
        }
        foreach (['npwp', 'luas_lahan', 'jumlah_unit', 'tipe_perumahan'] as $field) {
            if (blank($submission->{$field})) {
                $problems[$field] = ['Wajib diisi.'];
            }
        }

        $missing = $this->missingSlots($submission);
        if ($missing) {
            $problems['slots'] = $missing;
        }

        $sitePlan = $submission->currentFiles()->where('slot_code', 'S4-01')->pluck('file_type')->all();
        if ($sitePlan && ($error = $this->files->validateSitePlanSet($sitePlan))) {
            $problems['S4-01'] = [$error[0]['message']];
        }

        if ($problems) {
            throw ValidationException::withMessages($problems);
        }

        return DB::transaction(function () use ($submission) {
            $submission->forceFill([
                'number' => $this->numbers->submissionNumber(),
                'stage' => Submission::STAGE_ADMINISTRASI,
                'sub_status' => 'baru',
                'submitted_at' => now(),
                'stage_entered_at' => now(),
                'version' => $submission->version + 1,
            ])->save();

            return $submission;
        });
    }

    /** Berkas yang diminta diperbaiki Admin dan belum diganti. @return list<string> */
    public function unresolvedRevisionSlots(Submission $submission): array
    {
        return $submission->currentFiles()
            ->where('status', 'perlu_perbaikan')
            ->pluck('slot_code')->unique()->values()->all();
    }

    /** Perlu perbaikan → perbaikan terkirim; jam SLA berjalan lagi. */
    public function resubmit(Submission $submission): Submission
    {
        if (!$submission->isInRevision()) {
            throw new \DomainException('Pengajuan ini tidak sedang meminta perbaikan.');
        }

        $unresolved = $this->unresolvedRevisionSlots($submission);
        if ($unresolved) {
            throw ValidationException::withMessages(['slots' => $unresolved]);
        }

        $paused = $submission->sla_paused_at
            ? (int) abs(now()->diffInSeconds($submission->sla_paused_at))
            : 0;

        $submission->forceFill([
            'sub_status' => 'perbaikan_terkirim',
            'sla_paused_at' => null,
            'sla_paused_seconds' => $submission->sla_paused_seconds + $paused,
            'version' => $submission->version + 1,
        ])->save();

        return $submission;
    }

    /** Menyimpan berkas baru pada slot; versi lama non-aktif bila slot tunggal atau diganti. */
    public function attachFile(Submission $submission, string $slotCode, array $stored, int $userId, ?int $replacesId = null): SubmissionFile
    {
        return DB::transaction(function () use ($submission, $slotCode, $stored, $userId, $replacesId) {
            $slot = $this->slots()[$slotCode];
            $current = $submission->files()->where('slot_code', $slotCode)->where('is_current', true)->get();

            $replace = $slot['multiple']
                ? $current->where('id', $replacesId)
                : $current;

            $version = ($submission->files()->where('slot_code', $slotCode)->max('version') ?? 0) + 1;

            foreach ($replace as $old) {
                $old->forceFill(['is_current' => false, 'replaced_at' => now()])->save();
            }

            return $submission->files()->create($stored + [
                'slot_code' => $slotCode,
                'version' => $version,
                'is_current' => true,
                'status' => 'menunggu_telaah',
                'uploaded_by' => $userId,
            ]);
        });
    }
}

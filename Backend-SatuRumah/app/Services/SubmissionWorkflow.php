<?php

namespace App\Services;

use App\Models\InspectionAssignment;
use App\Models\InspectionReport;
use App\Models\Submission;
use App\Models\SubmissionFile;
use App\Models\User;
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
        private readonly Notifier $notifier,
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
        foreach (['nama_perumahan', 'alamat_proyek', 'tipe_pengajuan', 'npwp', 'luas_lahan', 'jumlah_unit', 'tipe_perumahan'] as $field) {
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

            $name = $submission->nama_perumahan ?? 'pengajuan';
            $this->notifier->event($submission, $submission->developer, 'submitted', 'Pengajuan dikirim', "Pengajuan {$submission->number} untuk {$name} dikirim pengembang.");
            $this->notifier->toVerifiers($submission, 'submitted', 'Pengajuan baru masuk', "{$submission->number} · {$name}");

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

        $name = $submission->nama_perumahan ?? 'pengajuan';
        $this->notifier->event($submission, $submission->developer, 'resubmitted', 'Perbaikan dikirim ulang', "Pengembang mengirim perbaikan berkas untuk {$submission->number}.");
        $this->notifier->toVerifiers($submission, 'resubmitted', 'Perbaikan berkas dikirim', "{$submission->number} · {$name}");

        return $submission;
    }


    // ------------------------------------------------------------------
    // Alur Admin (Verifikator)
    // ------------------------------------------------------------------

    private function ensureWorkable(Submission $s): void
    {
        if ($s->stage < Submission::STAGE_ADMINISTRASI || $s->stage >= Submission::STAGE_SELESAI
            || in_array($s->sub_status, ['selesai', 'ditolak'], true)) {
            throw new \DomainException('Pengajuan ini tidak sedang dalam proses verifikasi.');
        }
    }

    /** Menilai satu berkas aktif: sesuai atau perlu perbaikan (dengan catatan). */
    public function reviewFile(Submission $s, SubmissionFile $file, string $decision, ?string $note, User $reviewer): SubmissionFile
    {
        $this->ensureWorkable($s);
        if ($file->submission_id !== $s->id || !$file->is_current) {
            throw new \DomainException('Berkas ini bukan berkas aktif pengajuan.');
        }
        if (!in_array($decision, ['lolos', 'perlu_perbaikan'], true)) {
            throw new \DomainException('Keputusan berkas tidak dikenal.');
        }
        if ($decision === 'perlu_perbaikan' && blank($note)) {
            throw ValidationException::withMessages(['catatan' => ['Catatan wajib diisi untuk berkas yang perlu perbaikan.']]);
        }

        return DB::transaction(function () use ($s, $file, $decision, $note, $reviewer) {
            $file->forceFill([
                'status' => $decision,
                'decision_type' => $decision === 'lolos' ? null : 'revisi',
                'review_note' => $decision === 'lolos' ? null : trim((string) $note),
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now(),
            ])->save();

            if (in_array($s->sub_status, ['baru', 'perbaikan_terkirim'], true)) {
                $s->forceFill(['sub_status' => 'dalam_telaah'])->save();
            }

            $label = config("satu_rumah.slots.{$file->slot_code}.name", $file->slot_code);
            $this->notifier->event(
                $s, $reviewer, 'file_reviewed',
                $decision === 'lolos' ? "Berkas sesuai: {$label}" : "Berkas perlu perbaikan: {$label}",
                $decision === 'lolos' ? null : trim((string) $note),
                ['slot' => $file->slot_code, 'file_id' => $file->id, 'decision' => $decision],
            );

            return $file;
        });
    }

    /** Mengirim permintaan perbaikan ke pengembang; jam SLA berhenti. */
    public function requestRevision(Submission $s, User $reviewer): Submission
    {
        $this->ensureWorkable($s);
        if ($s->isInRevision()) {
            throw new \DomainException('Permintaan perbaikan sudah dikirim dan belum dijawab pengembang.');
        }

        $flagged = $s->currentFiles()->where('status', 'perlu_perbaikan')->get();
        if ($flagged->isEmpty()) {
            throw ValidationException::withMessages(['files' => ['Tandai minimal satu berkas "perlu perbaikan" sebelum meminta perbaikan.']]);
        }

        return DB::transaction(function () use ($s, $reviewer, $flagged) {
            $days = (int) \App\Models\Setting::getInt('revision.deadline_days', 14);
            $s->forceFill([
                'sub_status' => 'perlu_perbaikan',
                'sla_paused_at' => now(),
                'correction_deadline_at' => now()->addDays($days),
                'version' => $s->version + 1,
            ])->save();

            $names = $flagged->map(fn ($f) => config("satu_rumah.slots.{$f->slot_code}.name", $f->slot_code))->implode(', ');
            $this->notifier->event($s, $reviewer, 'revision_requested', 'Permintaan perbaikan dikirim', "{$flagged->count()} berkas: {$names}.");
            $this->notifier->toDeveloper(
                $s, 'revision_requested', 'Pengajuan perlu diperbaiki',
                "{$s->number}: {$flagged->count()} berkas perlu diperbaiki sebelum {$s->correction_deadline_at->translatedFormat('d F Y')}.",
            );

            return $s;
        });
    }

    /** Verifikasi administrasi selesai → Verifikasi Teknis. */
    public function approveAdministration(Submission $s, User $reviewer): Submission
    {
        $this->ensureWorkable($s);
        if ($s->stage !== Submission::STAGE_ADMINISTRASI || $s->isInRevision()) {
            throw new \DomainException('Verifikasi administrasi hanya dapat disetujui pada tahap administrasi.');
        }

        $this->requireSlotsApproved($s, 2);

        return DB::transaction(function () use ($s, $reviewer) {
            $s->forceFill([
                'stage' => Submission::STAGE_TEKNIS,
                'sub_status' => 'dalam_telaah',
                'stage_entered_at' => now(),
                'version' => $s->version + 1,
            ])->save();

            $this->notifier->event($s, $reviewer, 'stage_advanced', 'Verifikasi administrasi disetujui', 'Berkas administrasi sesuai. Lanjut verifikasi teknis.');
            $this->notifier->toDeveloper($s, 'stage_advanced', 'Verifikasi administrasi selesai', "{$s->number} lanjut ke verifikasi teknis.");

            return $s;
        });
    }

    /** @throws ValidationException bila ada slot wajib pada tahap itu yang belum sesuai */
    private function requireSlotsApproved(Submission $s, int $slotStage): void
    {
        $bySlot = $s->currentFiles()->get()->groupBy('slot_code');
        $notReady = [];
        foreach ($this->slots() as $code => $slot) {
            if (($slot['stage'] ?? 2) !== $slotStage || !($slot['required'] ?? true)) {
                continue;
            }
            $files = $bySlot->get($code);
            if (!$files || $files->contains(fn ($f) => $f->status !== 'lolos')) {
                $notReady[] = $code;
            }
        }
        if ($notReady) {
            throw ValidationException::withMessages(['slots' => $notReady]);
        }
    }

    /**
     * Menjadwalkan survei (atau menjadwal ulang/mengalihkan petugas bila sudah
     * dijadwalkan). Dari Verifikasi Teknis (semua berkas teknis sesuai) → Survei.
     */
    public function scheduleSurvey(Submission $s, User $officer, string $date, ?string $note, User $creator, ?string $reason = null): InspectionAssignment
    {
        $this->ensureWorkable($s);
        if (!in_array($s->stage, [Submission::STAGE_TEKNIS, Submission::STAGE_SURVEI], true) || $s->isInRevision()) {
            throw new \DomainException('Survei hanya dapat dijadwalkan setelah verifikasi teknis atau saat jadwal diubah.');
        }
        if ($officer->role !== 'tim_lapangan' || !$officer->is_active) {
            throw ValidationException::withMessages(['petugas' => ['Pilih petugas lapangan yang aktif.']]);
        }
        if ($s->stage === Submission::STAGE_TEKNIS) {
            $this->requireSlotsApproved($s, 2);
            $this->requireSlotsApproved($s, 3);
        }

        return DB::transaction(function () use ($s, $officer, $date, $note, $creator, $reason) {
            $previous = InspectionAssignment::where('submission_id', $s->id)
                ->whereIn('status', InspectionAssignment::OPEN)->get();
            foreach ($previous as $old) {
                $old->forceFill(['status' => 'dialihkan'])->save();
            }

            $assignment = InspectionAssignment::create([
                'submission_id' => $s->id,
                'officer_id' => $officer->id,
                'scheduled_date' => $date,
                'note' => $note,
                'status' => 'dijadwalkan',
                'reassigned_from_id' => $previous->last()?->id,
                'reassign_reason' => $previous->isNotEmpty() ? $reason : null,
                'created_by' => $creator->id,
            ]);

            $movingIn = $s->stage === Submission::STAGE_TEKNIS;
            $s->forceFill([
                'stage' => Submission::STAGE_SURVEI,
                'sub_status' => 'terjadwal',
                'stage_entered_at' => $movingIn ? now() : $s->stage_entered_at,
                'version' => $s->version + 1,
            ])->save();

            $tanggal = \Illuminate\Support\Carbon::parse($date)->translatedFormat('d F Y');
            $name = $s->nama_perumahan ?? 'pengajuan';
            $this->notifier->event(
                $s, $creator, $previous->isNotEmpty() ? 'survey_rescheduled' : 'survey_scheduled',
                $previous->isNotEmpty() ? 'Jadwal survei diubah' : 'Survei dijadwalkan',
                "{$tanggal} · {$officer->name}" . ($note ? " · {$note}" : ''),
                ['assignment_id' => $assignment->id],
            );
            $this->notifier->toUser($officer, $s, 'assignment', 'Tugas survei baru', "{$name} · {$tanggal}", ['assignment_id' => $assignment->id]);
            $this->notifier->toDeveloper($s, 'survey_scheduled', 'Survei lapangan dijadwalkan', "{$s->number}: survei pada {$tanggal}.");

            return $assignment;
        });
    }

    /** Laporan survei final diterima → Persetujuan. */
    public function acceptReports(Submission $s, User $reviewer): Submission
    {
        $this->ensureWorkable($s);
        if ($s->stage !== Submission::STAGE_SURVEI || $s->isInRevision()) {
            throw new \DomainException('Laporan survei hanya dapat diterima pada tahap survei.');
        }
        $report = InspectionReport::where('submission_id', $s->id)->where('status', 'final')->latest('submitted_at')->first();
        if (!$report) {
            throw ValidationException::withMessages(['report' => ['Belum ada laporan survei (BA) final dari petugas.']]);
        }

        return DB::transaction(function () use ($s, $reviewer, $report) {
            $s->forceFill([
                'stage' => Submission::STAGE_PERSETUJUAN,
                'sub_status' => 'menunggu_persetujuan',
                'stage_entered_at' => now(),
                'version' => $s->version + 1,
            ])->save();

            $this->notifier->event($s, $reviewer, 'stage_advanced', 'Laporan survei diterima', "BA {$report->report_number}. Menunggu keputusan akhir.", ['report_id' => $report->id]);
            $this->notifier->toDeveloper($s, 'stage_advanced', 'Survei selesai', "{$s->number} masuk tahap persetujuan.");

            return $s;
        });
    }

    /** Keputusan akhir: setuju (selesai, dengan nomor dan tanggal keputusan) atau tolak. */
    public function decide(Submission $s, bool $approve, ?string $number, ?string $date, ?string $note, User $reviewer): Submission
    {
        $this->ensureWorkable($s);
        if ($s->stage !== Submission::STAGE_PERSETUJUAN || $s->isInRevision()) {
            throw new \DomainException('Keputusan hanya dapat diambil pada tahap persetujuan.');
        }
        if ($approve && (blank($number) || blank($date))) {
            throw ValidationException::withMessages([
                'decision_number' => blank($number) ? ['Nomor keputusan wajib diisi.'] : [],
                'decision_date' => blank($date) ? ['Tanggal keputusan wajib diisi.'] : [],
            ]);
        }
        if (!$approve && blank($note)) {
            throw ValidationException::withMessages(['note' => ['Alasan penolakan wajib diisi.']]);
        }

        return DB::transaction(function () use ($s, $approve, $number, $date, $note, $reviewer) {
            if ($approve) {
                $s->forceFill([
                    'stage' => Submission::STAGE_SELESAI,
                    'sub_status' => 'selesai',
                    'decision_number' => trim((string) $number),
                    'decision_date' => $date,
                    'completed_at' => now(),
                    'stage_entered_at' => now(),
                    'version' => $s->version + 1,
                ])->save();
                $this->notifier->event($s, $reviewer, 'decided', 'Pengajuan disetujui', "Nomor keputusan {$s->decision_number}.");
                $this->notifier->toDeveloper($s, 'decided', 'Pengajuan disetujui', "{$s->number} disetujui. Nomor keputusan {$s->decision_number}.");
            } else {
                $s->forceFill([
                    'sub_status' => 'ditolak',
                    'completed_at' => now(),
                    'version' => $s->version + 1,
                ])->save();
                $this->notifier->event($s, $reviewer, 'decided', 'Pengajuan ditolak', trim((string) $note));
                $this->notifier->toDeveloper($s, 'decided', 'Pengajuan ditolak', "{$s->number}: " . trim((string) $note));
            }

            return $s;
        });
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

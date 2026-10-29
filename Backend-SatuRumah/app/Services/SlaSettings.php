<?php

namespace App\Services;

use App\Models\Setting;
use App\Models\Submission;
use Illuminate\Support\Carbon;

/**
 * Pembaca durasi SLA yang dinamis (database -> .env -> nilai bawaan config).
 * Perhitungan hari kerja dan hari libur nasional dibuat terpisah pada tahap berikutnya.
 */
class SlaSettings
{
    /** Batas SLA (hari kerja) untuk tahap 2-5; tahap lain tidak punya SLA. */
    public function daysForStage(int $stage): ?int
    {
        if ($stage < 2 || $stage > 5) {
            return null;
        }

        return Setting::getInt("sla.t{$stage}_days");
    }

    /**
     * Batas selesai tahap berjalan: hari kerja Senin-Jumat sejak masuk tahap, ditambah lama jeda perbaikan.
     * shortcut: hari libur nasional belum dihitung dan jeda diambil dari total jeda pengajuan (bukan per tahap);
     * rapikan bila Disperwaskim menetapkan kalender libur dan aturan SLA resmi.
     */
    public function dueAt(Submission $s): ?Carbon
    {
        $days = $this->daysForStage((int) $s->stage);
        $start = $s->stage_entered_at ?? $s->submitted_at;
        if (!$days || !$start || in_array($s->sub_status, ['perlu_perbaikan', 'selesai', 'ditolak'], true)) {
            return null;
        }

        return Carbon::instance($start)->addWeekdays($days)->addSeconds((int) $s->sla_paused_seconds);
    }

    /** `ok`, `mendekati`, atau `terlambat`; null bila tahap ini tidak punya SLA berjalan. */
    public function state(Submission $s): ?string
    {
        $due = $this->dueAt($s);
        if (!$due) {
            return null;
        }
        $start = Carbon::instance($s->stage_entered_at ?? $s->submitted_at);
        $total = max(1, $due->getTimestamp() - $start->getTimestamp());
        $ratio = (now()->getTimestamp() - $start->getTimestamp()) / $total;

        return match (true) {
            $ratio >= 1 => 'terlambat',
            $ratio * 100 >= $this->warningPercent() => 'mendekati',
            default => 'ok',
        };
    }

    /** Persentase batas waktu saat label "Mendekati Batas" aktif. */
    public function warningPercent(): int
    {
        return Setting::getInt('sla.warning_percent', 80);
    }

    /** Batas perbaikan oleh pengembang (hari kalender). */
    public function revisionDeadlineDays(): int
    {
        return Setting::getInt('revision.deadline_days', 14);
    }
}

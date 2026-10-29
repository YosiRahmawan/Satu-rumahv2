<?php

namespace App\Console\Commands;

use App\Models\AppNotification;
use App\Models\Submission;
use App\Services\Notifier;
use App\Services\SlaSettings;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

/** Pengingat harian: tenggat perbaikan pengembang dan batas waktu (SLA) tiap tahap. Tiap pengingat hanya sekali. */
class IngatkanTenggat extends Command
{
    protected $signature = 'pengajuan:ingatkan-tenggat';

    protected $description = 'Kirim pengingat tenggat perbaikan dan SLA tahap yang mendekati atau melewati batas.';

    private const HARI_PENGINGAT = 3;

    public function handle(Notifier $notifier, SlaSettings $sla): int
    {
        $terkirim = 0;

        // Tenggat perbaikan: pengingat H-3 ke pengembang; setelah lewat, kabari pengembang dan admin.
        Submission::where('sub_status', 'perlu_perbaikan')->whereNotNull('correction_deadline_at')->get()
            ->each(function (Submission $s) use ($notifier, &$terkirim) {
                $sisa = (int) now()->startOfDay()->diffInDays(Carbon::instance($s->correction_deadline_at)->startOfDay(), false);
                $tanggal = $s->correction_deadline_at->translatedFormat('d F Y');
                $sejak = $s->sla_paused_at ?? $s->updated_at;

                if ($sisa < 0 && $this->belumDikirim($s, 'deadline_overdue', $sejak)) {
                    $notifier->toDeveloper($s, 'deadline_overdue', 'Tenggat perbaikan terlewat', "{$s->number}: batas perbaikan {$tanggal} sudah lewat. Segera kirim perbaikan.");
                    $notifier->toVerifiers($s, 'deadline_overdue_admin', 'Tenggat perbaikan terlewat', "{$s->number} · {$s->nama_perumahan}: batas {$tanggal} lewat tanpa perbaikan.");
                    $terkirim += 2;
                } elseif ($sisa >= 0 && $sisa <= self::HARI_PENGINGAT && $this->belumDikirim($s, 'deadline_reminder', $sejak)) {
                    $teks = $sisa === 0 ? 'hari ini' : "{$sisa} hari lagi ({$tanggal})";
                    $notifier->toDeveloper($s, 'deadline_reminder', 'Batas perbaikan mendekat', "{$s->number}: batas perbaikan {$teks}.");
                    $terkirim++;
                }
            });

        // SLA tahap berjalan: kabari admin saat mendekati dan saat melewati batas.
        Submission::whereBetween('stage', [2, 5])->get()->each(function (Submission $s) use ($notifier, $sla, &$terkirim) {
            $state = $sla->state($s);
            $sejak = $s->stage_entered_at ?? $s->submitted_at;
            $judul = "{$s->number} · {$s->nama_perumahan} ({$s->tahapLabel()})";

            if ($state === 'terlambat' && $this->belumDikirim($s, 'sla_overdue', $sejak)) {
                $notifier->toVerifiers($s, 'sla_overdue', 'Melewati batas waktu (SLA)', $judul);
                $terkirim++;
            } elseif ($state === 'mendekati' && $this->belumDikirim($s, 'sla_warning', $sejak)) {
                $notifier->toVerifiers($s, 'sla_warning', 'Mendekati batas waktu (SLA)', $judul);
                $terkirim++;
            }
        });

        $this->info("Pengingat terkirim: {$terkirim}.");

        return self::SUCCESS;
    }

    private function belumDikirim(Submission $s, string $type, mixed $sejak): bool
    {
        return !AppNotification::where('submission_id', $s->id)->where('type', $type)
            ->when($sejak, fn ($q) => $q->where('created_at', '>=', $sejak))->exists();
    }
}

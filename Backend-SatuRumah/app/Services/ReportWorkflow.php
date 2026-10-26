<?php

namespace App\Services;

use App\Models\InspectionAssignment;
use App\Models\InspectionReport;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/** Aturan laporan BA: kirim (final) dan dampaknya pada penugasan. */
class ReportWorkflow
{
    public function __construct(
        private readonly NumberGenerator $numbers,
        private readonly Notifier $notifier,
    ) {
    }

    /** Draf → final. Menerbitkan nomor BA dan menutup penugasan. Idempoten. */
    public function submit(InspectionReport $report, float $latitude, float $longitude): InspectionReport
    {
        if (!$report->isDraft()) {
            return $report;
        }

        $problems = [];
        foreach (['nama_perumahan', 'maksud_tujuan', 'status_hasil_evaluasi'] as $field) {
            if (blank($report->{$field})) {
                $problems[$field] = ['Wajib diisi.'];
            }
        }
        $rtl = array_filter((array) $report->rtl, fn ($v) => trim((string) $v) !== '');
        if (in_array($report->status_hasil_evaluasi, InspectionReport::EVALUASI_WAJIB_RTL, true) && !$rtl) {
            $problems['rtl'] = ['Wajib minimal 1 poin untuk hasil evaluasi ini.'];
        }
        if ($problems) {
            throw ValidationException::withMessages($problems);
        }

        return DB::transaction(function () use ($report, $latitude, $longitude) {
            $report->forceFill([
                'report_number' => $this->numbers->reportNumber(),
                'status' => 'final',
                'submit_latitude' => $latitude,
                'submit_longitude' => $longitude,
                'submitted_at' => now(),
                'verification_token' => bin2hex(random_bytes(24)),
                'version' => $report->version + 1,
            ])->save();

            if ($report->assignment_id) {
                InspectionAssignment::whereKey($report->assignment_id)->update([
                    'status' => 'selesai',
                    'completed_at' => now(),
                ]);
            }

            if ($report->submission) {
                $this->notifier->event($report->submission, $report->officer, 'report_submitted', 'Laporan survei (BA) dikirim', "BA {$report->report_number} dikirim petugas.", ['report_id' => $report->id]);
                $this->notifier->toVerifiers($report->submission, 'report_submitted', 'Laporan survei dikirim', "{$report->report_number} · {$report->nama_perumahan}", ['report_id' => $report->id]);
            }

            return $report;
        });
    }
}

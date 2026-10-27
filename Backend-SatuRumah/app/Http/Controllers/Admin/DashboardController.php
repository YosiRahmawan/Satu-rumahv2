<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Submission;
use App\Services\DashboardSummary;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DashboardController extends Controller
{
    public function index(DashboardSummary $summary)
    {
        $pengajuans = Submission::with('developer.developerProfile')
            ->where('stage', '>=', Submission::STAGE_ADMINISTRASI)
            ->latest('updated_at')->paginate(5);

        return view('admin.dashboard', [
            'stats' => $summary->kpi(),
            'pengajuans' => $pengajuans,
            'sebaran' => $summary->sebaranKecamatan(),
            'jadwal' => $summary->jadwalTinjauan(),
        ]);
    }

    /** Kartu angka di bagian atas; dipanggil berkala oleh dashboard. */
    public function kpi(DashboardSummary $summary)
    {
        return view('admin.partials.kpi', ['stats' => $summary->kpi()]);
    }

    /** Dua kartu ringkasan saja; dipanggil berkala oleh dashboard agar angkanya ikut berubah. */
    public function ringkasan(DashboardSummary $summary)
    {
        return view('admin.partials.ringkasan', [
            'sebaran' => $summary->sebaranKecamatan(),
            'jadwal' => $summary->jadwalTinjauan(),
        ]);
    }

    public function exportCsv(): StreamedResponse
    {
        $name = 'Antrean_Pengajuan_SATURUMAH_' . date('Ymd_His') . '.csv';

        return response()->streamDownload(function () {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['No. Pengajuan', 'Pengembang', 'Perumahan', 'Tahap', 'Status', 'Diajukan', 'Terakhir Diperbarui']);
            Submission::with('developer.developerProfile')
                ->where('stage', '>=', Submission::STAGE_ADMINISTRASI)->orderBy('id')
                ->lazy()->each(fn (Submission $s) => fputcsv($out, [
                    $s->number,
                    $s->developer?->developerProfile?->nama_pt,
                    $s->nama_perumahan,
                    $s->tahapLabel(),
                    $s->statusLabel(),
                    $s->submitted_at?->format('d-m-Y H:i'),
                    $s->updated_at?->format('d-m-Y H:i'),
                ]));
            fclose($out);
        }, $name, ['Content-Type' => 'text/csv']);
    }
}

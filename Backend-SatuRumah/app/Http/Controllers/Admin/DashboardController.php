<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\InspectionAssignment;
use App\Models\Submission;
use Symfony\Component\HttpFoundation\StreamedResponse;

class DashboardController extends Controller
{
    public function index()
    {
        $active = Submission::whereBetween('stage', [2, 5])->where('sub_status', '!=', 'ditolak');

        $stats = [
            'pengajuan_baru' => (clone $active)->whereIn('sub_status', ['baru', 'perbaikan_terkirim'])->count(),
            'verifikasi_teknis' => (clone $active)->where('stage', Submission::STAGE_TEKNIS)->count(),
            'survey_terjadwal' => InspectionAssignment::whereIn('status', InspectionAssignment::OPEN)->count(),
            'perlu_tindak_lanjut' => (clone $active)->where('sub_status', 'perlu_perbaikan')->count(),
        ];

        $pengajuans = Submission::with('developer.developerProfile')
            ->where('stage', '>=', Submission::STAGE_ADMINISTRASI)
            ->latest('updated_at')->paginate(5);

        return view('admin.dashboard', compact('stats', 'pengajuans'));
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

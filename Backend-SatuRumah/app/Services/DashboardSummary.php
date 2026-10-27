<?php

namespace App\Services;

use App\Models\InspectionAssignment;
use App\Models\Setting;
use App\Models\Submission;

/** Ringkasan Web Admin yang dihitung langsung dari database (selalu data terkini). */
class DashboardSummary
{
    /** Kecamatan di Kota Tasikmalaya; dicocokkan dengan teks alamat proyek. */
    public const KECAMATAN = [
        'Mangkubumi', 'Kawalu', 'Cibeureum', 'Tamansari', 'Purbaratu',
        'Tawang', 'Cihideung', 'Indihiang', 'Bungursari', 'Cipedes',
    ];

    /** Angka kartu dashboard. `masuk`, `selesai`, `ditolak` dihitung untuk tahun berjalan. @return array<string, int> */
    public function kpi(): array
    {
        $active = Submission::whereBetween('stage', [2, 5])->where('sub_status', '!=', 'ditolak');
        $tahunIni = fn () => Submission::where('stage', '>=', Submission::STAGE_ADMINISTRASI)->whereYear('submitted_at', now()->year);

        return [
            'pengajuan_baru' => (clone $active)->whereIn('sub_status', ['baru', 'perbaikan_terkirim'])->count(),
            'verifikasi_teknis' => (clone $active)->where('stage', Submission::STAGE_TEKNIS)->count(),
            'survey_terjadwal' => InspectionAssignment::whereIn('status', InspectionAssignment::OPEN)->count(),
            'perlu_tindak_lanjut' => (clone $active)->where('sub_status', 'perlu_perbaikan')->count(),
            'masuk' => $tahunIni()->count(),
            'selesai' => $tahunIni()->where('sub_status', 'selesai')->count(),
            'ditolak' => $tahunIni()->where('sub_status', 'ditolak')->count(),
            'tahun' => now()->year,
        ];
    }

    /**
     * shortcut: kecamatan dibaca dari teks alamat (belum ada kolom khusus), jadi alamat
     * tanpa nama kecamatan dihitung "tanpa kecamatan"; ganti dengan kolom `kecamatan` bila
     * Disperwaskim mewajibkannya di formulir.
     */
    public function kecamatanOf(?string $alamat): ?string
    {
        foreach (self::KECAMATAN as $nama) {
            if ($alamat !== null && stripos($alamat, $nama) !== false) {
                return $nama;
            }
        }

        return null;
    }

    /**
     * Sebaran pengajuan tahun berjalan per kecamatan.
     *
     * @return array{tahun: int, triwulan: string, target: int, total: int, tanpa: int, rows: list<array{nama: string, jumlah: int, persen: int, lebar: int, prioritas: bool}>}
     */
    public function sebaranKecamatan(int $limit = 5): array
    {
        $target = max(1, Setting::getInt('dashboard.target_per_kecamatan', 10));

        $submissions = Submission::with('developer.developerProfile')
            ->where('stage', '>=', Submission::STAGE_ADMINISTRASI)
            ->where('sub_status', '!=', 'ditolak')
            ->whereYear('submitted_at', now()->year)
            ->get();

        $counts = [];
        $tanpa = 0;
        foreach ($submissions as $s) {
            $kec = $this->kecamatanOf($s->alamat_proyek) ?? $this->kecamatanOf($s->developer?->developerProfile?->alamat_perumahan);
            if ($kec === null) {
                $tanpa++;
                continue;
            }
            $counts[$kec] = ($counts[$kec] ?? 0) + 1;
        }
        arsort($counts);

        $rows = [];
        foreach (array_slice($counts, 0, $limit, true) as $nama => $jumlah) {
            $persen = (int) round($jumlah / $target * 100);
            $rows[] = [
                'nama' => $nama,
                'jumlah' => $jumlah,
                'persen' => $persen,
                'lebar' => min(100, $persen),
                'prioritas' => $rows === [], // yang terbanyak diberi warna prioritas
            ];
        }

        return [
            'tahun' => now()->year,
            'triwulan' => ['I', 'II', 'III', 'IV'][intdiv(now()->month - 1, 3)],
            'target' => $target,
            'total' => $submissions->count(),
            'tanpa' => $tanpa,
            'rows' => $rows,
        ];
    }

    /**
     * Penugasan survei yang masih berjalan: hari ini dan 7 hari ke depan.
     *
     * @return array{hari_ini: int, items: list<array<string, mixed>>}
     */
    public function jadwalTinjauan(int $limit = 5): array
    {
        $today = now()->startOfDay();
        $assignments = InspectionAssignment::with(['submission', 'officer', 'members'])
            ->whereIn('status', InspectionAssignment::OPEN)
            ->whereBetween('scheduled_date', [$today->toDateString(), $today->copy()->addDays(7)->toDateString()])
            ->orderBy('scheduled_date')->orderBy('id')
            ->get();

        $items = $assignments->take($limit)->map(fn (InspectionAssignment $a) => [
            'id' => $a->submission_id,
            'perumahan' => $a->submission?->nama_perumahan ?? '-',
            'nomor' => $a->submission?->number,
            'tanggal' => $a->scheduled_date,
            'hari_ini' => $a->scheduled_date->isSameDay($today),
            'tim' => collect($a->team())->pluck('nama')->implode(', '),
        ])->values()->all();

        return [
            'hari_ini' => $assignments->filter(fn ($a) => $a->scheduled_date->isSameDay($today))->count(),
            'items' => $items,
        ];
    }
}

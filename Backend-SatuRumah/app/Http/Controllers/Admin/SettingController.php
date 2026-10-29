<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

/** Halaman pengaturan: SLA, tenggat perbaikan, target dashboard, dan batas unggah. */
class SettingController extends Controller
{
    /** @return array<string, array<string, array{label: string, unit: string, min: int, max: int}>> */
    public static function fields(): array
    {
        return [
            'Batas waktu proses (hari kerja, Senin-Jumat)' => [
                'sla.t2_days' => ['label' => 'Verifikasi Administrasi', 'unit' => 'hari', 'min' => 1, 'max' => 60],
                'sla.t3_days' => ['label' => 'Verifikasi Teknis', 'unit' => 'hari', 'min' => 1, 'max' => 60],
                'sla.t4_days' => ['label' => 'Survei Lapangan', 'unit' => 'hari', 'min' => 1, 'max' => 60],
                'sla.t5_days' => ['label' => 'Persetujuan', 'unit' => 'hari', 'min' => 1, 'max' => 60],
                'sla.warning_percent' => ['label' => 'Label "Mendekati SLA" muncul pada', 'unit' => '% batas waktu', 'min' => 10, 'max' => 99],
            ],
            'Perbaikan oleh pengembang' => [
                'revision.deadline_days' => ['label' => 'Batas waktu perbaikan', 'unit' => 'hari kalender', 'min' => 1, 'max' => 90],
            ],
            'Dashboard' => [
                'dashboard.target_per_kecamatan' => ['label' => 'Target pengajuan per kecamatan', 'unit' => 'berkas', 'min' => 1, 'max' => 1000],
            ],
            'Batas unggah' => [
                'upload.pdf_max_mb' => ['label' => 'Ukuran maksimal PDF', 'unit' => 'MB', 'min' => 1, 'max' => 100],
                'upload.dwg_max_mb' => ['label' => 'Ukuran maksimal DWG', 'unit' => 'MB', 'min' => 1, 'max' => 200],
                'upload.max_files_per_slot' => ['label' => 'Berkas maksimal per persyaratan banyak-berkas', 'unit' => 'berkas', 'min' => 1, 'max' => 30],
                'upload.photo_max_mb' => ['label' => 'Ukuran maksimal foto lapangan', 'unit' => 'MB', 'min' => 1, 'max' => 30],
                'upload.photo_max_count' => ['label' => 'Foto maksimal per laporan', 'unit' => 'foto', 'min' => 1, 'max' => 30],
            ],
        ];
    }

    private static function name(string $key): string
    {
        return str_replace('.', '_', $key);
    }

    public function index()
    {
        return view('admin.pengaturan.index', [
            'groups' => self::fields(),
            'nilai' => collect(self::fields())->reduce(fn ($acc, $f) => $acc + collect($f)->map(fn ($_, $k) => Setting::getInt($k))->all(), []),
        ]);
    }

    public function update(Request $request)
    {
        $rules = [];
        $labels = [];
        foreach (self::fields() as $fields) {
            foreach ($fields as $key => $f) {
                $rules['nilai.' . self::name($key)] = ['required', 'integer', "min:{$f['min']}", "max:{$f['max']}"];
                $labels['nilai.' . self::name($key)] = strtolower($f['label']);
            }
        }
        $data = $request->validate($rules, [], $labels);

        foreach (self::fields() as $fields) {
            foreach ($fields as $key => $f) {
                Setting::set($key, (int) $data['nilai'][self::name($key)]);
            }
        }

        return redirect()->route('pengaturan.index')->with('success', 'Pengaturan disimpan.');
    }
}

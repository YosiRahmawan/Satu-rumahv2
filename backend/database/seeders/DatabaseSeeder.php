<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\DokumenType;
use App\Models\Pengajuan;
use App\Models\NotifikasiModel;
use Illuminate\Support\Facades\Hash;

/**
 * Katalog dokumen (data referensi) diperbarui terkontrol dengan
 * updateOrCreate. Akun, pengajuan, dan notifikasi contoh hanya dibuat di
 * environment `local` dan `testing`, dan tidak pernah menimpa data yang sudah
 * ada: id atau username yang sudah dipakai dilewati, bukan diubah.
 * Aman dijalankan berulang. Data contoh disamakan dengan seed Flutter.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->seedDokumenTypes();

        if (! app()->environment(['local', 'testing'])) {
            $this->warn('Seeder demo dilewati: environment bukan local/testing.');

            return;
        }

        $users = $this->seedDemoUsers();
        if ($users === null) {
            return;
        }

        $this->seedDemoPengajuan($users['pengembang']);
        $this->seedDemoNotifikasi($users);
    }

    private function warn(string $message): void
    {
        if ($this->command) {
            $this->command->warn($message);
        }
    }

    /** Aturan berkas mengikuti aplikasi: PDF maks 10 MB; site plan DWG/PDF maks 50 MB. */
    private function seedDokumenTypes(): void
    {
        $pdf = ['pdf'];
        $types = [
            ['key' => 'ktp', 'label' => 'KTP-Elektronik Pemohon', 'step' => 2, 'section' => 'Dokumen Perusahaan'],
            ['key' => 'nib', 'label' => 'Nomor Induk Berusaha (NIB)', 'step' => 2, 'section' => 'Dokumen Perusahaan'],
            ['key' => 'npwp_doc', 'label' => 'NPWP Perusahaan', 'step' => 2, 'section' => 'Dokumen Perusahaan'],
            ['key' => 'asosiasi', 'label' => 'Keanggotaan Asosiasi Pengembang', 'step' => 2, 'section' => 'Dokumen Perusahaan'],
            ['key' => 'legalitas', 'label' => 'Legalitas Perusahaan (Akta)', 'step' => 2, 'section' => 'Dokumen Perusahaan'],

            ['key' => 'surat_permohonan', 'label' => 'Surat permohonan persetujuan', 'step' => 3, 'section' => 'Legalitas & Perizinan'],
            ['key' => 'info_intensitas_ruang', 'label' => 'Informasi intensitas ruang', 'step' => 3, 'section' => 'Legalitas & Perizinan'],
            ['key' => 'bukti_kepemilikan_lahan', 'label' => 'Bukti kepemilikan lahan', 'step' => 3, 'section' => 'Legalitas & Perizinan'],
            ['key' => 'bukti_tpu', 'label' => 'Bukti penyediaan lahan TPU', 'step' => 3, 'section' => 'Legalitas & Perizinan'],

            ['key' => 'kkpr_doc', 'label' => 'Persetujuan KKPR', 'step' => 3, 'section' => 'Teknis & Rekomendasi'],
            ['key' => 'pbg_induk', 'label' => 'PBG Induk Perumahan', 'step' => 3, 'section' => 'Teknis & Rekomendasi'],
            ['key' => 'rekomendasi_lingkungan', 'label' => 'Rekomendasi Dokumen Lingkungan', 'step' => 3, 'section' => 'Teknis & Rekomendasi'],
            ['key' => 'pelepasan_lahan', 'label' => 'Rekomendasi Pelepasan Lahan (Kondisional)', 'step' => 3, 'section' => 'Teknis & Rekomendasi', 'is_mandatory' => false],

            ['key' => 'pernyataan_pelepasan', 'label' => 'Surat Pernyataan Pelepasan Hak', 'step' => 3, 'section' => 'Dokumen Pernyataan'],
            ['key' => 'pernyataan_keabsahan', 'label' => 'Surat Pernyataan Keabsahan Dokumen', 'step' => 3, 'section' => 'Dokumen Pernyataan'],
            ['key' => 'pernyataan_psu', 'label' => 'Surat Pernyataan Kesanggupan PSU', 'step' => 3, 'section' => 'Dokumen Pernyataan'],

            ['key' => 'site_plan_dwg', 'label' => 'Desain Layout Site Plan (DWG/PDF)', 'step' => 4, 'section' => 'Dokumen Teknis', 'formats' => ['dwg', 'pdf'], 'max' => 50],
            ['key' => 'drainase_doc', 'label' => 'Dokumen Kajian Teknis Drainase', 'step' => 4, 'section' => 'Dokumen Teknis', 'is_mandatory' => false],
        ];

        foreach ($types as $type) {
            DokumenType::updateOrCreate(
                ['key' => $type['key']],
                [
                    'label' => $type['label'],
                    'is_mandatory' => $type['is_mandatory'] ?? true,
                    'allowed_formats' => $type['formats'] ?? $pdf,
                    'max_size_mb' => $type['max'] ?? 10,
                    'step' => $type['step'],
                    'section' => $type['section'],
                ]
            );
        }
    }

    /**
     * Akun demo (kata sandi sama dengan layar login demo Flutter). Username
     * atau email yang sudah dipakai akun lain dianggap akun operasional: seluruh
     * data demo dilewati dan akun itu tidak disentuh.
     *
     * @return array<string, User>|null
     */
    private function seedDemoUsers(): ?array
    {
        $demo = [
            'pengembang' => [
                'username' => 'pt_tasik_indah',
                'password' => 'demo123',
                'nama' => 'PT. Tasik Indah Sentosa',
                'role' => 'pengembang',
                'email' => 'tasikindah@developer.com',
                'nama_pt' => 'PT. Tasik Indah Sentosa',
                'nama_direktur' => 'H. Tatang Sutisna',
                'nib' => '9120304958102',
                'npwp_perusahaan' => '09.123.456.7-423.000',
            ],
            'admin' => [
                'username' => 'admin_disperwaskim',
                'password' => 'admin123',
                'nama' => 'Rizki Pratama, S.T.',
                'role' => 'admin',
                'nip' => '19930512 202010 1 001',
                'jabatan' => 'Verifikator Administrasi',
                'email' => 'rizki.pratama@tasikmalayakota.go.id',
            ],
            'perwaskim' => [
                'username' => 'tim_monitoring_perwaskim',
                'password' => 'monitoring123',
                'nama' => 'Drs. Rian Hidayat, M.Si',
                'role' => 'perwaskim',
                'nip' => '19880512 201503 1 002',
                'jabatan' => 'Ketua Tim Monitoring & Evaluasi DPKP',
                'email' => 'rian.perwaskim@tasikmalayakota.go.id',
                'no_whatsapp' => '0812-3456-7890',
            ],
        ];

        $result = [];
        foreach ($demo as $key => $attributes) {
            $existing = User::where('username', $attributes['username'])
                ->orWhere('email', $attributes['email'])
                ->first();

            if ($existing !== null) {
                // Hanya akun demo yang sama persis (username + email) dipakai ulang.
                if ($existing->username !== $attributes['username']
                    || $existing->email !== $attributes['email']) {
                    $this->warn("Data demo dilewati: username/email {$attributes['username']} sudah dipakai akun lain.");

                    return null;
                }
                $result[$key] = $existing;

                continue;
            }

            $attributes['password'] = Hash::make($attributes['password']);
            $result[$key] = User::create($attributes);
        }

        return $result;
    }

    /** Tiga pengajuan contoh yang sama dengan seed Flutter (0084, 0142, 0038). */
    private function seedDemoPengajuan(User $pengembang): void
    {
        Pengajuan::firstOrCreate(['id' => 'REG-2026-0084'], [
            'user_id' => $pengembang->id,
            'nama_perumahan' => 'Mutiara Regency Tasik',
            'nama_pt' => 'PT. Tasik Indah Sentosa',
            'nama_direktur' => 'H. Tatang Sutisna',
            'npwp_perusahaan' => '09.123.456.7-423.000',
            'luas_lahan' => 24000.0,
            'jumlah_unit' => 165,
            'tipe_perumahan' => 'Komersil',
            'status' => 'Dalam Proses',
            'status_tahap' => 'verifikasiAdministrasi',
            'tanggal' => '04 Sep 2026',
            'uploaded_docs' => [
                'ktp' => 'ktp_direktur_tatang.pdf',
                'nib' => 'nib_tasik_indah.pdf',
                'npwp_doc' => 'npwp_tasik_indah.pdf',
            ],
            'verified_docs' => [],
            'dokumen_perlu_revisi' => [],
        ]);

        Pengajuan::firstOrCreate(['id' => 'REG-2026-0142'], [
            'user_id' => $pengembang->id,
            'nama_perumahan' => 'Perumahan Green Tasik',
            'nama_pt' => 'PT. Tasik Indah Sentosa',
            'nama_direktur' => 'H. Rahmat Hidayat, S.T.',
            'npwp_perusahaan' => '01.345.678.9-425.000',
            'luas_lahan' => 18500.0,
            'jumlah_unit' => 120,
            'tipe_perumahan' => 'Keduanya', // Flutter: "Subsidi & Komersil"
            'status' => 'Perlu Perbaikan',
            'status_tahap' => 'perluPerbaikan',
            'tahap_asal_perbaikan' => 'verifikasiTeknis',
            'tanggal' => '12 Sep 2026',
            'catatan_perbaikan' => 'Format site plan teknis belum mencantumkan koordinat UTM dan luasan RTH minimum 30%. Bukti kepemilikan tanah belum dilegalisir basah.',
            'uploaded_docs' => [
                'ktp' => 'ktp_direktur_rahmat.pdf',
                'nib' => 'nib_tasik_indah_sentosa.pdf',
                'npwp_doc' => 'npwp_perusahaan_tasik_indah.pdf',
                'bukti_kepemilikan_lahan' => 'sertifikat_shm_tanah_greentasik.pdf',
                'site_plan_dwg' => 'siteplan_topografi_v1.dwg',
            ],
            'verified_docs' => [
                'ktp' => true,
                'nib' => true,
                'npwp_doc' => true,
                'bukti_kepemilikan_lahan' => false,
                'site_plan_dwg' => false,
            ],
            'dokumen_perlu_revisi' => ['site_plan_dwg', 'bukti_kepemilikan_lahan'],
        ]);

        Pengajuan::firstOrCreate(['id' => 'REG-2026-0038'], [
            'user_id' => $pengembang->id,
            'nama_perumahan' => 'Grand Tasik Harmoni',
            'nama_pt' => 'PT. Tasik Indah Sentosa',
            'nama_direktur' => 'H. Rahmat Hidayat, S.T.',
            'npwp_perusahaan' => '01.345.678.9-425.000',
            'luas_lahan' => 12000.0,
            'jumlah_unit' => 85,
            'tipe_perumahan' => 'Komersil',
            'status' => 'Selesai',
            'status_tahap' => 'selesai',
            'tanggal' => '28 Agu 2026',
            'uploaded_docs' => [
                'ktp' => 'ktp_rahmat.pdf',
                'nib' => 'nib_tasik_indah.pdf',
                'npwp_doc' => 'npwp_tasik_indah.pdf',
            ],
            'verified_docs' => [],
            'dokumen_perlu_revisi' => [],
        ]);
    }

    /**
     * Notifikasi contoh dengan penerima dan pengajuan yang jelas, mengikuti
     * kebijakan aplikasi Flutter (Pengembang tidak melihat milik role lain).
     */
    private function seedDemoNotifikasi(array $users): void
    {
        NotifikasiModel::firstOrCreate(['id' => 'n1'], [
            'user_id' => null,
            'pengajuan_id' => 'REG-2026-0084',
            'penerima_role' => 'admin',
            'jenis' => 'pengajuanBaru',
            'judul' => 'Pengajuan Baru: Mutiara Regency Tasik',
            'deskripsi' => 'PT. Tasik Indah Sentosa telah mengajukan berkas pengesahan site plan baru.',
            'waktu' => now()->subHours(2),
            'is_read' => false,
            'target_route' => '/admin/pengajuan/detail/REG-2026-0084',
        ]);

        NotifikasiModel::firstOrCreate(['id' => 'n2'], [
            'user_id' => $users['pengembang']->id,
            'pengajuan_id' => 'REG-2026-0142',
            'penerima_role' => 'pengembang',
            'jenis' => 'perluRevisi',
            'judul' => 'Dokumen perlu diperbaiki',
            'deskripsi' => 'Verifikator meminta perbaikan berkas pada Perumahan Green Tasik (REG-2026-0142). Buka Perbarui Berkas untuk melihat catatan dan mengunggah berkas pengganti.',
            'waktu' => now()->subHours(5),
            'is_read' => false,
            'target_route' => '/pengajuan/detail/REG-2026-0142',
        ]);
    }
}

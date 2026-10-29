<?php

namespace Database\Seeders;

use App\Models\DeveloperProfile;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Akun tertutup untuk pengembangan dan demo, satu per role.
 * Kata sandi sementara wajib diganti saat masuk pertama (must_change_password).
 * Di luar local/testing, SEED_DEFAULT_PASSWORD harus diisi; tidak ada kata sandi bawaan.
 */
class AccountSeeder extends Seeder
{
    public function run(): void
    {
        $password = env('SEED_DEFAULT_PASSWORD');
        if (!$password) {
            if (!app()->environment('local', 'testing')) {
                throw new \RuntimeException('Isi SEED_DEFAULT_PASSWORD sebelum menjalankan AccountSeeder di luar local/testing.');
            }
            $password = 'SatuRumah#2026';
        }

        $accounts = [
            ['username' => 'admin', 'name' => 'Admin Disperwaskim', 'role' => 'admin', 'jabatan' => 'Admin', 'email' => 'admin@saturumah.go.id'],
            ['username' => 'pengembang', 'name' => 'PT Pengembang Contoh', 'role' => 'pengembang', 'jabatan' => 'Direktur', 'email' => 'pengembang@saturumah.go.id'],
            ['username' => 'tim_lapangan', 'name' => 'Petugas Lapangan Contoh', 'role' => 'tim_lapangan', 'jabatan' => 'Tim Perwaskim', 'email' => 'lapangan@saturumah.go.id'],
        ];

        foreach ($accounts as $account) {
            $user = User::updateOrCreate(
                ['username' => $account['username']],
                $account + ['password' => $password, 'is_active' => true, 'must_change_password' => true]
            );

            if ($account['role'] === 'pengembang') {
                DeveloperProfile::updateOrCreate(
                    ['user_id' => $user->id],
                    [
                        'nib' => '1234567890123',
                        'nama_perumahan' => 'Perumahan Contoh Asri',
                        'nama_pt' => 'PT Pengembang Contoh',
                        'nama_direktur' => 'Direktur Contoh',
                        'alamat_perumahan' => 'Jl. Contoh No. 1, Kota Tasikmalaya',
                        'alamat_pt' => 'Jl. Contoh No. 2, Kota Tasikmalaya',
                        'no_hp_direktur' => '081200000000',
                        'email_pt' => 'pt@saturumah.go.id',
                        'tipe_pengajuan' => 'site_plan_baru',
                    ]
                );
            }
        }
    }
}

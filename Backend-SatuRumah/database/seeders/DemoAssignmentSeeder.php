<?php

namespace Database\Seeders;

use App\Models\InspectionAssignment;
use App\Models\Submission;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Satu tugas survei contoh untuk akun tim_lapangan, supaya aplikasi Pengawas
 * punya data saat uji. Hanya untuk local/testing; penugasan nyata dibuat Admin
 * (Web Admin menyusul di Fase D).
 */
class DemoAssignmentSeeder extends Seeder
{
    public function run(): void
    {
        $developer = User::where('username', 'pengembang')->first();
        $officer = User::where('username', 'tim_lapangan')->first();
        $admin = User::where('role', 'admin')->first();
        if (!$developer || !$officer || !$admin) {
            return;
        }

        $profile = $developer->developerProfile;
        $submission = Submission::updateOrCreate(
            ['developer_id' => $developer->id, 'client_uuid' => '00000000-0000-4000-8000-000000000001'],
            [
                'number' => 'SR-' . now()->format('Y') . '-9001',
                'nama_perumahan' => $profile?->nama_perumahan ?? 'Perumahan Contoh Asri',
                'alamat_proyek' => $profile?->alamat_perumahan ?? 'Jl. Contoh No. 1, Kota Tasikmalaya',
                'tipe_pengajuan' => 'Pengajuan Site Plan Baru',
                'npwp' => '01.234.567.8-901.000',
                'luas_lahan' => 12000,
                'jumlah_unit' => 100,
                'tipe_perumahan' => 'subsidi',
                'stage' => Submission::STAGE_SURVEI,
                'sub_status' => 'terjadwal',
                'current_step' => 5,
                'submitted_at' => now()->subDays(10),
                'stage_entered_at' => now()->subDay(),
                'version' => 1,
            ]
        );

        InspectionAssignment::firstOrCreate(
            ['submission_id' => $submission->id, 'officer_id' => $officer->id],
            [
                'scheduled_date' => now()->addDay()->toDateString(),
                'note' => 'Periksa drainase, jalan lingkungan, dan RTH. Bawa gambar site plan.',
                'status' => 'dijadwalkan',
                'created_by' => $admin->id,
            ]
        );
    }
}

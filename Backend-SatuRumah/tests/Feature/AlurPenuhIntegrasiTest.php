<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\DeveloperProfile;
use App\Models\InspectionReport;
use App\Models\Submission;
use App\Models\SubmissionFile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** Satu alur utuh lewat pintu masing-masing role: API Pengembang, web Admin, API Pengawas. */
class AlurPenuhIntegrasiTest extends TestCase
{
    use RefreshDatabase;

    private const SANDI = 'Sandi-Uji-2026';

    private User $admin;
    private User $dev;
    private User $ketua;

    /** Catatan feedback yang diterima tiap pihak, dicetak di akhir sebagai bukti. */
    private array $jejak = [];

    private function mk(string $u, string $role, array $x = []): User
    {
        return User::factory()->create($x + [
            'username' => $u, 'email' => "{$u}@saturumah.go.id", 'role' => $role, 'password' => self::SANDI,
            'is_active' => true, 'must_change_password' => false,
        ]);
    }

    private function catat(string $langkah, User $penerima): void
    {
        $jenis = AppNotification::where('user_id', $penerima->id)->orderBy('id')->pluck('type')->all();
        $this->jejak[] = sprintf('%-46s -> %-10s notif: %s', $langkah, $penerima->username, implode(', ', $jenis) ?: '(kosong)');
    }

    private function jenis(User $u): array
    {
        return AppNotification::where('user_id', $u->id)->pluck('type')->all();
    }

    public function test_pengembang_ke_admin_ke_pengawas_sampai_ba_terbit(): void
    {
        Storage::fake('local');
        $this->admin = $this->mk('admin1', 'admin', ['name' => 'Admin Uji', 'jabatan' => 'Verifikator', 'nip' => '198501012010011002']);
        $this->dev = $this->mk('dev1', 'pengembang');
        $this->ketua = $this->mk('ketua1', 'tim_lapangan', ['name' => 'Ketua Uji', 'jabatan' => 'Ketua Tim', 'nip' => '198001012005011001']);
        $anggota = $this->mk('anggota1', 'tim_lapangan', ['name' => 'Anggota Uji', 'jabatan' => 'Staf']);
        DeveloperProfile::create([
            'user_id' => $this->dev->id, 'nib' => '1111111111111', 'nama_perumahan' => 'Griya Alur', 'nama_pt' => 'PT Uji',
            'nama_direktur' => 'Dir', 'alamat_perumahan' => 'Jl. Alur', 'alamat_pt' => 'Jl. B', 'no_hp_direktur' => '0812',
            'email_pt' => 'pt@uji.id', 'tipe_pengajuan' => 'site_plan_baru',
        ]);

        // 1. PENGEMBANG membuat dan mengirim pengajuan.
        Sanctum::actingAs($this->dev, ['*']);
        $id = $this->postJson('/api/v1/submissions', [], ['Idempotency-Key' => (string) Str::uuid()])->assertStatus(201)->json('data.id');
        $this->patchJson("/api/v1/submissions/{$id}", [
            'version' => 1, 'npwp' => '01.234.567.8-901.000', 'luas_lahan' => 1200, 'jumlah_unit' => 50, 'tipe_perumahan' => 'subsidi',
        ])->assertOk();
        $pdf = fn () => UploadedFile::fake()->createWithContent('b.pdf', "%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF\n");
        $this->postJson("/api/v1/submissions/{$id}/files", ['slot_code' => 'S2-01', 'file' => $pdf()])->assertStatus(201);
        foreach (config('satu_rumah.slots') as $code => $slot) {
            if (($slot['required'] ?? true) && $code !== 'S2-01') {
                foreach ($code === 'S4-01' ? ['pdf', 'dwg'] : ['pdf'] as $t) {
                    SubmissionFile::create([
                        'submission_id' => $id, 'slot_code' => $code, 'version' => 1, 'is_current' => true, 'original_name' => "{$code}.{$t}",
                        'stored_name' => "{$code}.{$t}", 'storage_path' => "x/{$code}.{$t}", 'file_type' => $t, 'size_bytes' => 10,
                        'status' => 'menunggu_telaah', 'uploaded_by' => $this->dev->id,
                    ]);
                }
            }
        }
        $this->postJson("/api/v1/submissions/{$id}/submit")->assertOk();
        $this->catat('1. Pengembang kirim pengajuan', $this->admin);
        $this->assertContains('submitted', $this->jenis($this->admin), 'Admin tidak diberi tahu pengajuan masuk');

        // 2. ADMIN menilai berkas, menyetujui administrasi, menjadwalkan survei.
        $this->app['auth']->shouldUse('web');
        $this->actingAs($this->admin);
        $this->get('/pengajuan')->assertOk()->assertSee('Griya Alur');
        SubmissionFile::where('submission_id', $id)->update(['status' => 'lolos']);
        $this->post("/pengajuan/{$id}/setujui-administrasi")->assertSessionHas('success');
        $this->post("/pengajuan/{$id}/jadwal", [
            'petugas_id' => $this->ketua->id, 'tanggal' => now()->addDay()->toDateString(), 'anggota' => [$anggota->id],
        ])->assertSessionHas('success');
        $this->catat('2a. Admin menjadwalkan survei', $this->ketua);
        $this->assertContains('assignment', $this->jenis($this->ketua), 'Ketua tidak diberi tahu ada tugas');
        $this->catat('2b. (pengembang diberi tahu tahapan)', $this->dev);

        // Pengembang melihat statusnya maju.
        Sanctum::actingAs($this->dev, ['*']);
        $this->getJson("/api/v1/submissions/{$id}")->assertOk()->assertJsonPath('data.stage', 4);

        // 3. PENGAWAS melihat tugas dan data proyek, membuat BA, foto bergeotag, kirim.
        Sanctum::actingAs($this->ketua, ['*']);
        $tugas = $this->getJson('/api/v1/officer/assignments')->assertOk()->json('data');
        $this->assertCount(1, $tugas);
        $this->assertSame('Griya Alur', $tugas[0]['submission']['nama_perumahan']);
        $this->postJson("/api/v1/officer/assignments/{$tugas[0]['id']}/accept")->assertOk();
        $r = $this->postJson('/api/v1/officer/reports', ['assignment_id' => $tugas[0]['id']], ['Idempotency-Key' => (string) Str::uuid()])->assertStatus(201)->json('data');
        $this->assertEqualsCanonicalizing(['Ketua Uji', 'Anggota Uji'], array_column($r['tim_pelaksana'], 'nama'));
        $this->putJson("/api/v1/officer/reports/{$r['id']}", [
            'version' => $r['version'], 'maksud_tujuan' => 'Pemeriksaan PSU', 'status_hasil_evaluasi' => 'sesuaiSiteplan',
            'temuan' => ['Saluran sesuai'], 'kesimpulan' => ['Sesuai site plan'],
        ])->assertOk();
        $foto = UploadedFile::fake()->createWithContent('f.jpg', file_get_contents(base_path('tests/Fixtures/geotag_ok.jpg')));
        $this->postJson("/api/v1/officer/reports/{$r['id']}/photos", ['file' => $foto, 'source' => 'camera'])->assertStatus(201);
        $kirim = $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", ['latitude' => -7.3274, 'longitude' => 108.2207])
            ->assertOk()->assertJsonPath('data.status', 'final');
        $nomor = $kirim->json('data.report_number');
        $this->assertNotEmpty($nomor);
        $this->catat('3. Pengawas kirim BA', $this->admin);
        $this->assertGreaterThanOrEqual(1, count(array_filter($this->jenis($this->admin), fn ($t) => str_contains($t, 'report'))), 'Admin tidak diberi tahu BA masuk');

        // Daftar BA Pengawas sudah memuat status tanda tangan (dipakai riwayat di aplikasi).
        $daftar = $this->getJson('/api/v1/officer/reports')->assertOk()->json('data');
        $this->assertFalse($daftar[0]['signatures']['ketua']['signed']);

        // 4. ADMIN menerima laporan; belum bisa terbit sebelum tanda tangan.
        $this->app['auth']->shouldUse('web');
        $this->actingAs($this->admin);
        $this->get("/pengajuan/{$id}?tab=monitoring")->assertOk()->assertSee($nomor);
        $this->post("/pengajuan/{$id}/terima-laporan")->assertSessionHas('success');
        $url = "/pengajuan/{$id}/laporan/{$r['id']}";
        $this->post("{$url}/terbitkan")->assertSessionHas('warning');
        $this->assertContains('report_accepted', $this->jenis($this->ketua), 'Ketua tidak diberi tahu BA diterima Admin');

        // 5. Ketua (HP) lalu Admin (web) menandatangani; Admin menerbitkan.
        $png = $this->gambar();
        Sanctum::actingAs($this->ketua, ['*']);
        $this->post("/api/v1/officer/reports/{$r['id']}/sign", [
            'password' => self::SANDI, 'version' => InspectionReport::find($r['id'])->version,
            'signature' => UploadedFile::fake()->createWithContent('ttd.png', $png),
        ], ['Idempotency-Key' => (string) Str::uuid(), 'Accept' => 'application/json'])->assertOk();
        $this->assertContains('report_signed_ketua', $this->jenis($this->admin), 'Admin tidak diberi tahu Ketua sudah tanda tangan');
        $this->app['auth']->shouldUse('web');
        $this->actingAs($this->admin)->post("{$url}/tanda-tangan", [
            'password' => self::SANDI, 'version' => InspectionReport::find($r['id'])->version,
            'signature' => UploadedFile::fake()->createWithContent('ttd.png', $png),
        ])->assertSessionHas('success');
        $this->assertContains('report_signed_admin', $this->jenis($this->ketua), 'Ketua tidak diberi tahu Admin sudah tanda tangan');
        $this->post("{$url}/terbitkan")->assertSessionHas('success');
        $this->assertNotNull(InspectionReport::find($r['id'])->published_at);

        // 6. FEEDBACK setelah terbit: Pengawas dan Pengembang diberi tahu, PDF resmi bisa diunduh.
        $this->catat('6a. Admin terbitkan BA', $this->ketua);
        $this->catat('6b. Admin terbitkan BA', $this->dev);
        $this->assertContains('report_published', $this->jenis($this->ketua), 'Pengawas tidak diberi tahu BA terbit');
        Sanctum::actingAs($this->ketua, ['*']);
        $pdf = $this->get("/api/v1/officer/reports/{$r['id']}/pdf")->assertOk();
        $this->assertStringStartsWith('%PDF', $pdf->streamedContent());
        $daftar = $this->getJson('/api/v1/officer/reports')->json('data');
        $this->assertNotNull($daftar[0]['published_at']);
        $this->assertTrue($daftar[0]['signatures']['ketua']['signed'] ?? true);
        $token = InspectionReport::find($r['id'])->verification_token;
        $this->get("/verifikasi/{$token}")->assertOk();

        // 7. ADMIN memutuskan; Pengembang diberi tahu hasil akhir.
        $this->app['auth']->shouldUse('web');
        $this->actingAs($this->admin)->post("/pengajuan/{$id}/keputusan", ['keputusan' => 'setuju', 'nomor' => 'SK-001/2026', 'tanggal' => '2026-11-10'])
            ->assertSessionHas('success');
        $this->catat('7. Admin putuskan setuju', $this->dev);
        $this->assertContains('decided', $this->jenis($this->dev), 'Pengembang tidak diberi tahu keputusan');
        Sanctum::actingAs($this->dev, ['*']);
        $this->getJson("/api/v1/submissions/{$id}")->assertOk()->assertJsonPath('data.stage', 6);
        $this->getJson('/api/v1/notifications')->assertOk();

        fwrite(STDERR, "\n=== JEJAK FEEDBACK ===\n" . implode("\n", $this->jejak) . "\n");
    }

    private function gambar(): string
    {
        $im = imagecreatetruecolor(300, 120);
        imagefill($im, 0, 0, imagecolorallocate($im, 255, 255, 255));
        imagesetthickness($im, 3);
        imageline($im, 10, 100, 290, 15, imagecolorallocate($im, 0, 0, 0));
        ob_start();
        imagepng($im);

        return (string) ob_get_clean();
    }
}

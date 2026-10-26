<?php

namespace Tests\Feature\Api;

use App\Models\DeveloperProfile;
use App\Models\InspectionAssignment;
use App\Models\InspectionReport;
use App\Models\Submission;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OfficerTest extends TestCase
{
    use RefreshDatabase;

    private User $officer;
    private User $developer;
    private Submission $submission;
    private InspectionAssignment $assignment;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');

        $this->officer = $this->makeUser('petugas1', 'tim_lapangan');
        $this->developer = $this->makeUser('dev1', 'pengembang');
        DeveloperProfile::create([
            'user_id' => $this->developer->id, 'nib' => '1111111111111', 'nama_perumahan' => 'Griya Profil',
            'nama_pt' => 'PT Uji', 'nama_direktur' => 'Dir', 'alamat_perumahan' => 'Jl. Profil',
            'alamat_pt' => 'Jl. B', 'no_hp_direktur' => '0812', 'email_pt' => 'pt@uji.id', 'tipe_pengajuan' => 'site_plan_baru',
        ]);
        $this->submission = Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(), 'number' => 'SR-2026-0001',
            'nama_perumahan' => 'Griya Mangkubumi', 'alamat_proyek' => 'Jl. Karikil', 'stage' => 4, 'sub_status' => 'terjadwal',
            'version' => 1,
        ]);
        $this->assignment = $this->assign($this->officer, $this->submission);

        Sanctum::actingAs($this->officer);
    }

    private function makeUser(string $username, string $role): User
    {
        return User::factory()->create([
            'username' => $username, 'role' => $role, 'password' => 'Sandi-Uji-2026',
            'is_active' => true, 'must_change_password' => false,
        ]);
    }

    private function assign(User $officer, Submission $s, string $status = 'dijadwalkan', string $date = '2026-11-02'): InspectionAssignment
    {
        return InspectionAssignment::create([
            'submission_id' => $s->id, 'officer_id' => $officer->id, 'scheduled_date' => $date,
            'note' => 'Bawa gambar site plan', 'status' => $status, 'created_by' => $this->developer->id,
        ]);
    }

    private function uuid(): string
    {
        return (string) Str::uuid();
    }

    private function fixture(string $name): UploadedFile
    {
        return UploadedFile::fake()->createWithContent("{$name}.jpg", file_get_contents(base_path("tests/Fixtures/{$name}.jpg")));
    }

    private function draftReport(array $body = ['submission_number' => 'SR-2026-0001']): array
    {
        return $this->postJson('/api/v1/officer/reports', $body, ['Idempotency-Key' => $this->uuid()])->json('data');
    }

    /** Laporan draf yang siap dikirim (dasar uji kirim). */
    private function readyReport(string $evaluasi = 'sesuaiSiteplan', array $extra = []): array
    {
        $report = $this->draftReport();
        $this->putJson("/api/v1/officer/reports/{$report['id']}", [
            'version' => $report['version'],
            'maksud_tujuan' => 'Memastikan kesesuaian pelaksanaan.',
            'status_hasil_evaluasi' => $evaluasi,
            'temuan' => ['Jalan selesai'],
        ] + $extra)->assertOk();

        return $report;
    }

    // ---- tugas ----

    public function test_daftar_tugas_hanya_milik_sendiri_dan_yang_terbuka(): void
    {
        $other = $this->makeUser('petugas2', 'tim_lapangan');
        $this->assign($other, $this->submission);
        $this->assign($this->officer, $this->submission, 'selesai', '2026-10-01');

        $open = $this->getJson('/api/v1/officer/assignments')->assertOk()->json('data');
        $this->assertCount(1, $open);
        $this->assertSame($this->assignment->id, $open[0]['id']);
        $this->assertSame('SR-2026-0001', $open[0]['submission']['number']);
        $this->assertSame('Griya Mangkubumi', $open[0]['submission']['nama_perumahan']);
        $this->assertSame('2026-11-02', $open[0]['scheduled_date']);

        $this->getJson('/api/v1/officer/assignments?status=all')->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/officer/assignments?status=selesai')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/officer/assignments?status=ngawur')->assertStatus(422);
    }

    public function test_terima_tugas(): void
    {
        $this->postJson("/api/v1/officer/assignments/{$this->assignment->id}/accept")
            ->assertOk()->assertJsonPath('data.status', 'diterima');
        $this->assertNotNull($this->assignment->fresh()->accepted_at);
        // Menerima ulang aman.
        $this->postJson("/api/v1/officer/assignments/{$this->assignment->id}/accept")->assertOk();

        $done = $this->assign($this->officer, $this->submission, 'selesai');
        $this->postJson("/api/v1/officer/assignments/{$done->id}/accept")->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');

        $foreign = $this->assign($this->makeUser('petugas2', 'tim_lapangan'), $this->submission);
        $this->postJson("/api/v1/officer/assignments/{$foreign->id}/accept")->assertStatus(404);
    }

    // ---- laporan ----

    public function test_buat_draf_laporan_dari_nomor_pengajuan_dan_idempoten(): void
    {
        $this->postJson('/api/v1/officer/reports', [])->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');

        $key = $this->uuid();
        $first = $this->postJson('/api/v1/officer/reports', ['submission_number' => 'SR-2026-0001'], ['Idempotency-Key' => $key])
            ->assertStatus(201)
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.assignment_id', $this->assignment->id)
            ->assertJsonPath('data.nama_perumahan', 'Griya Mangkubumi')
            ->assertJsonPath('data.lokasi', 'Jl. Karikil');
        $again = $this->postJson('/api/v1/officer/reports', ['submission_number' => 'SR-2026-0001'], ['Idempotency-Key' => $key])->assertOk();
        // Kunci lain untuk tugas yang sama: tetap satu draf.
        $third = $this->postJson('/api/v1/officer/reports', ['assignment_id' => $this->assignment->id], ['Idempotency-Key' => $this->uuid()])->assertOk();

        $this->assertSame($first->json('data.id'), $again->json('data.id'));
        $this->assertSame($first->json('data.id'), $third->json('data.id'));
        $this->assertSame(1, InspectionReport::count());
    }

    public function test_laporan_mandiri_dan_tugas_tak_dikenal(): void
    {
        $this->postJson('/api/v1/officer/reports', ['nama_perumahan' => 'Perumahan Mandiri'], ['Idempotency-Key' => $this->uuid()])
            ->assertStatus(201)->assertJsonPath('data.assignment_id', null)->assertJsonPath('data.nama_perumahan', 'Perumahan Mandiri');

        $this->postJson('/api/v1/officer/reports', ['submission_number' => 'SR-9999-0001'], ['Idempotency-Key' => $this->uuid()])
            ->assertStatus(404);

        $foreign = $this->assign($this->makeUser('petugas2', 'tim_lapangan'), $this->submission);
        $this->postJson('/api/v1/officer/reports', ['assignment_id' => $foreign->id], ['Idempotency-Key' => $this->uuid()])
            ->assertStatus(404);
    }

    public function test_ubah_laporan_memakai_version_dan_membatasi_isi(): void
    {
        $r = $this->draftReport();
        $url = "/api/v1/officer/reports/{$r['id']}";

        $this->putJson($url, ['version' => 1, 'maksud_tujuan' => 'Tujuan', 'temuan' => ['A', 'B'],
            'tim_pelaksana' => [['nama' => 'Rian', 'jabatan' => 'Ketua']], 'status_hasil_evaluasi' => 'sesuaiSiteplan'])
            ->assertOk()->assertJsonPath('data.version', 2)->assertJsonPath('data.temuan.1', 'B')
            ->assertJsonPath('data.tim_pelaksana.0.nama', 'Rian');

        $this->putJson($url, ['version' => 1, 'maksud_tujuan' => 'Lain'])
            ->assertStatus(409)->assertJsonPath('error.code', 'ERR-015')->assertJsonPath('error.current_version', 2);
        $this->putJson($url, ['version' => 2, 'status_hasil_evaluasi' => 'asal'])->assertStatus(422);
        $this->putJson($url, ['version' => 2, 'temuan' => array_fill(0, 21, 'x')])->assertStatus(422);
        $this->putJson($url, ['version' => 2, 'tim_pelaksana' => array_fill(0, 11, ['nama' => 'x'])])->assertStatus(422);
    }

    public function test_laporan_orang_lain_memberi_404(): void
    {
        $r = $this->draftReport();
        Sanctum::actingAs($this->makeUser('petugas2', 'tim_lapangan'));

        $this->getJson("/api/v1/officer/reports/{$r['id']}")->assertStatus(404);
        $this->putJson("/api/v1/officer/reports/{$r['id']}", ['version' => 1])->assertStatus(404);
        $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", ['latitude' => 1, 'longitude' => 1])->assertStatus(404);
        $this->postJson("/api/v1/officer/reports/{$r['id']}/photos", ['file' => $this->fixture('geotag_ok')])->assertStatus(404);
    }

    // ---- foto ----

    public function test_foto_bergeotag_sah_diterima_dan_data_diambil_dari_tanda_tangan(): void
    {
        $r = $this->draftReport();

        $res = $this->postJson("/api/v1/officer/reports/{$r['id']}/photos", ['file' => $this->fixture('geotag_ok'), 'source' => 'camera'])
            ->assertStatus(201)
            ->assertJsonPath('data.latitude', -7.3274)
            ->assertJsonPath('data.longitude', 108.2207)
            ->assertJsonPath('data.accuracy_m', 8.4)
            ->assertJsonPath('data.address', 'Jl. Contoh No. 1, Tasikmalaya')
            ->assertJsonPath('data.note', 'Saluran drainase')
            ->assertJsonPath('data.position', 1);
        $this->assertStringStartsWith('2026-10-20T02:30:15', $res->json('data.captured_at'));

        $stored = InspectionReport::find($r['id'])->photos()->first();
        Storage::disk('local')->assertExists($stored->storage_path);
        // Berkas disimpan apa adanya (tanda tangan harus tetap sah).
        $this->assertSame(file_get_contents(base_path('tests/Fixtures/geotag_ok.jpg')), Storage::disk('local')->get($stored->storage_path));
    }

    public function test_foto_ditolak_sesuai_alasan(): void
    {
        $r = $this->draftReport();
        $url = "/api/v1/officer/reports/{$r['id']}/photos";

        $this->postJson($url, ['file' => $this->fixture('geotag_none')])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-012')
            ->assertJsonPath('error.message', fn ($m) => str_contains($m, 'Tidak ada geotag'));
        $this->postJson($url, ['file' => $this->fixture('geotag_tampered')])
            ->assertStatus(422)->assertJsonPath('error.message', fn ($m) => str_contains($m, 'diubah'));
        $this->postJson($url, ['file' => UploadedFile::fake()->createWithContent('a.png', "\x89PNG\r\n\x1a\n")])
            ->assertStatus(422)->assertJsonPath('error.message', fn ($m) => str_contains($m, 'JPEG'));
        $this->postJson($url, ['file' => UploadedFile::fake()->create('besar.jpg', 11 * 1024)])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-001');
        $this->postJson($url, [])->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');

        $this->assertSame(0, InspectionReport::find($r['id'])->photos()->count());
    }

    public function test_foto_ganda_dan_batas_jumlah_ditolak(): void
    {
        $r = $this->draftReport();
        $url = "/api/v1/officer/reports/{$r['id']}/photos";

        $this->postJson($url, ['file' => $this->fixture('geotag_ok')])->assertStatus(201);
        $this->postJson($url, ['file' => $this->fixture('geotag_ok')])
            ->assertStatus(422)->assertJsonPath('error.message', 'Foto ini sudah ada di laporan.');

        $report = InspectionReport::find($r['id']);
        for ($i = 2; $i <= 10; $i++) {
            $report->photos()->create([
                'position' => $i, 'stored_name' => "x{$i}.jpg", 'storage_path' => "x/{$i}.jpg", 'size_bytes' => 1,
                'checksum' => str_repeat((string) ($i % 10), 64), 'latitude' => 1, 'longitude' => 1, 'captured_at' => now(),
            ]);
        }
        $this->postJson($url, ['file' => $this->fixture('geotag_none')])
            ->assertStatus(422)->assertJsonPath('error.message', 'Maksimal 10 foto per laporan.');
    }

    public function test_hapus_dan_unduh_foto_hanya_pemilik_dan_hapus_hanya_saat_draf(): void
    {
        $r = $this->draftReport();
        $pid = $this->postJson("/api/v1/officer/reports/{$r['id']}/photos", ['file' => $this->fixture('geotag_ok')])->json('data.id');

        $this->get("/api/v1/officer/reports/{$r['id']}/photos/{$pid}/file")->assertOk()->assertHeader('content-type', 'image/jpeg');

        $path = InspectionReport::find($r['id'])->photos()->first()->storage_path;
        $this->deleteJson("/api/v1/officer/reports/{$r['id']}/photos/{$pid}")->assertOk();
        Storage::disk('local')->assertMissing($path);

        $pid2 = $this->postJson("/api/v1/officer/reports/{$r['id']}/photos", ['file' => $this->fixture('geotag_ok')])->json('data.id');
        Sanctum::actingAs($this->makeUser('petugas2', 'tim_lapangan'));
        $this->getJson("/api/v1/officer/reports/{$r['id']}/photos/{$pid2}/file")->assertStatus(404);
    }

    // ---- kirim ----

    public function test_kirim_menolak_isian_kurang(): void
    {
        $r = $this->draftReport();
        $send = ['latitude' => -7.3, 'longitude' => 108.2];

        $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", $send)
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-010')
            ->assertJsonStructure(['error' => ['fields' => ['maksud_tujuan', 'status_hasil_evaluasi']]]);

        $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", [])->assertStatus(422)
            ->assertJsonStructure(['error' => ['fields' => ['latitude', 'longitude']]]);

        $tidakSesuai = $this->readyReport('tidakSesuaiSiteplan');
        $this->postJson("/api/v1/officer/reports/{$tidakSesuai['id']}/submit", $send)
            ->assertStatus(422)->assertJsonStructure(['error' => ['fields' => ['rtl']]]);
        $this->assertSame('draft', InspectionReport::find($r['id'])->status);
    }

    public function test_kirim_menerbitkan_nomor_bulanan_menutup_tugas_dan_idempoten(): void
    {
        $r = $this->readyReport();
        $roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'][(int) now()->format('n') - 1];
        $prefix = "600.2.5/BA-MON/{$roman}/" . now()->format('Y');

        $res = $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", ['latitude' => -7.3274, 'longitude' => 108.2207])
            ->assertOk()
            ->assertJsonPath('data.status', 'final')
            ->assertJsonPath('data.report_number', "{$prefix}/001")
            ->assertJsonPath('data.submit_latitude', -7.3274);
        $this->assertNotNull(InspectionReport::find($r['id'])->verification_token);
        $this->assertSame('selesai', $this->assignment->fresh()->status);
        $this->assertNotNull($this->assignment->fresh()->completed_at);

        // Kirim ulang: nomor tetap.
        $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", ['latitude' => 1, 'longitude' => 1])
            ->assertOk()->assertJsonPath('data.report_number', "{$prefix}/001");

        // Laporan berikutnya bulan yang sama: urut 002.
        $second = $this->assign($this->officer, $this->submission);
        $r2 = $this->draftReport(['assignment_id' => $second->id]);
        $this->putJson("/api/v1/officer/reports/{$r2['id']}", ['version' => 1, 'maksud_tujuan' => 'T', 'status_hasil_evaluasi' => 'sesuaiSiteplan'])->assertOk();
        $this->postJson("/api/v1/officer/reports/{$r2['id']}/submit", ['latitude' => 1, 'longitude' => 1])
            ->assertOk()->assertJsonPath('data.report_number', "{$prefix}/002");

        $this->assertSame('final', $res->json('data.status'));
    }

    public function test_laporan_final_tidak_bisa_diubah(): void
    {
        $r = $this->readyReport();
        $this->postJson("/api/v1/officer/reports/{$r['id']}/submit", ['latitude' => 1, 'longitude' => 1])->assertOk();
        $v = InspectionReport::find($r['id'])->version;

        $this->putJson("/api/v1/officer/reports/{$r['id']}", ['version' => $v, 'maksud_tujuan' => 'Ubah'])
            ->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');
        $this->postJson("/api/v1/officer/reports/{$r['id']}/photos", ['file' => $this->fixture('geotag_ok')])
            ->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');
    }

    public function test_daftar_laporan_hanya_milik_sendiri(): void
    {
        $this->draftReport();
        Sanctum::actingAs($other = $this->makeUser('petugas2', 'tim_lapangan'));
        $this->postJson('/api/v1/officer/reports', ['nama_perumahan' => 'Lain'], ['Idempotency-Key' => $this->uuid()])->assertStatus(201);

        $this->getJson('/api/v1/officer/reports')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('meta.total', 1);
        $this->assertSame($other->id, InspectionReport::latest('id')->first()->officer_id);
    }

    public function test_pengembang_tidak_boleh_memakai_jalur_pengawas(): void
    {
        Sanctum::actingAs($this->developer);

        $this->getJson('/api/v1/officer/assignments')->assertStatus(403)->assertJsonPath('error.code', 'ERR-022');
        $this->getJson('/api/v1/officer/reports')->assertStatus(403);
    }
}

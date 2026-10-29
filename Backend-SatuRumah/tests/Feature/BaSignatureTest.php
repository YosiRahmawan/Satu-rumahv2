<?php

namespace Tests\Feature;

use App\Models\InspectionReport;
use App\Models\InspectionReportPhoto;
use App\Models\ReportSignature;
use App\Models\Submission;
use App\Models\User;
use App\Services\SignatureService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BaSignatureTest extends TestCase
{
    use RefreshDatabase;

    private const SANDI = 'Sandi-Uji-2026';

    private User $admin;
    private User $developer;
    private User $ketua;
    private User $lain;
    private Submission $submission;
    private InspectionReport $report;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $mk = fn (string $u, string $r, array $x = []) => User::factory()->create($x + [
            'username' => $u, 'email' => "{$u}@saturumah.go.id", 'role' => $r, 'password' => self::SANDI,
            'is_active' => true, 'must_change_password' => false,
        ]);
        $this->admin = $mk('admin1', 'admin', ['name' => 'Admin Uji', 'jabatan' => 'Verifikator']);
        $this->developer = $mk('dev1', 'pengembang');
        $this->ketua = $mk('ketua1', 'tim_lapangan', ['name' => 'Ketua Uji', 'jabatan' => 'Ketua Tim Perwaskim']);
        $this->lain = $mk('petugas2', 'tim_lapangan');

        $this->submission = Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(), 'number' => 'SR-2026-0001',
            'nama_perumahan' => 'Griya Uji', 'alamat_proyek' => 'Jl. Uji, Kawalu', 'stage' => 5, 'sub_status' => 'menunggu_persetujuan',
            'version' => 1, 'submitted_at' => now(), 'stage_entered_at' => now(),
        ]);
        $this->report = InspectionReport::create([
            'submission_id' => $this->submission->id, 'officer_id' => $this->ketua->id, 'status' => 'final',
            'report_number' => '600.2.5/BA-MON/X/2026/001', 'nama_perumahan' => 'Griya Uji', 'lokasi' => 'Jl. Uji, Kawalu',
            'monitoring_date' => now()->toDateString(), 'maksud_tujuan' => 'Pemeriksaan PSU', 'temuan' => ['Saluran sesuai'],
            'kesimpulan' => ['Sesuai site plan'], 'status_hasil_evaluasi' => 'sesuaiSiteplan', 'submitted_at' => now(), 'version' => 2,
            'tim_pelaksana' => [['nama' => 'Ketua Uji', 'jabatan' => 'Ketua Tim']], 'verification_token' => bin2hex(random_bytes(24)),
        ]);
    }

    /** PNG/JPEG uji: garis hitam di atas latar putih (atau kosong bila $tinta false). */
    private function gambar(bool $tinta = true, int $w = 300, int $h = 120, string $tipe = 'png'): string
    {
        $im = imagecreatetruecolor($w, $h);
        imagefill($im, 0, 0, imagecolorallocate($im, 255, 255, 255));
        if ($tinta) {
            imagesetthickness($im, 3);
            imageline($im, 10, $h - 20, $w - 10, 15, imagecolorallocate($im, 0, 0, 0));
        }
        ob_start();
        $tipe === 'jpeg' ? imagejpeg($im) : imagepng($im);

        return (string) ob_get_clean();
    }

    private function apiSign(User $user, ?int $version = null, array $extra = [], ?string $bytes = null, string $key = null)
    {
        Sanctum::actingAs($user, ['*']);

        return $this->post("/api/v1/officer/reports/{$this->report->id}/sign", $extra + [
            'method' => 'upload', 'password' => self::SANDI, 'version' => $version ?? $this->report->fresh()->version,
            'signature' => UploadedFile::fake()->createWithContent('ttd.png', $bytes ?? $this->gambar()),
        ], ['Idempotency-Key' => $key ?? (string) Str::uuid(), 'Accept' => 'application/json']);
    }

    private function webSign(array $extra = [], ?string $bytes = null)
    {
        return $this->actingAs($this->admin)->post("/pengajuan/{$this->submission->id}/laporan/{$this->report->id}/tanda-tangan", $extra + [
            'method' => 'draw', 'password' => self::SANDI, 'version' => $this->report->fresh()->version,
            'signature_data' => 'data:image/png;base64,' . base64_encode($bytes ?? $this->gambar()),
        ]);
    }

    private function signature(string $role): ?ReportSignature
    {
        return ReportSignature::where('report_id', $this->report->id)->where('role', $role)->first();
    }

    public function test_ketua_yang_berwenang_menandatangani_dengan_unggah_dan_hasilnya_ternormalisasi(): void
    {
        $this->apiSign($this->ketua)->assertOk()
            ->assertJsonPath('data.signatures.ketua.signed', true)->assertJsonPath('data.signatures.admin.signed', false)
            ->assertJsonPath('data.signatures.provider', 'gambar');

        $sig = $this->signature('ketua');
        $this->assertSame($this->ketua->id, $sig->user_id);
        $this->assertSame('upload', $sig->method);
        $this->assertSame(2, $sig->report_version);
        $this->assertSame(64, strlen($sig->document_hash));
        // File privat berupa PNG hasil enkode ulang, bukan gambar mentah dari klien.
        $png = Storage::disk('local')->get($sig->signature_path);
        $this->assertSame(IMAGETYPE_PNG, getimagesizefromstring($png)[2]);
        // Latar putih menjadi transparan.
        $im = imagecreatefromstring($png);
        $this->assertSame(127, (imagecolorat($im, 2, 2) >> 24) & 0x7F);
    }

    public function test_ketua_menandatangani_dengan_gambar_langsung_data_url_dan_jpeg(): void
    {
        Sanctum::actingAs($this->ketua, ['*']);
        $this->post("/api/v1/officer/reports/{$this->report->id}/sign", [
            'method' => 'draw', 'password' => self::SANDI, 'version' => 2,
            'signature_data' => 'data:image/png;base64,' . base64_encode($this->gambar()),
        ], ['Idempotency-Key' => (string) Str::uuid(), 'Accept' => 'application/json'])->assertOk();
        $this->assertSame('draw', $this->signature('ketua')->method);

        // JPEG juga diterima dan dinormalkan menjadi PNG.
        $svc = app(SignatureService::class);
        $this->assertSame(IMAGETYPE_PNG, getimagesizefromstring($svc->normalize($this->gambar(true, 300, 120, 'jpeg')))[2]);
    }

    public function test_petugas_lain_pengembang_dan_tanpa_idempotency_key_ditolak(): void
    {
        $this->apiSign($this->lain)->assertNotFound(); // bukan pemilik laporan = bukan Ketua
        $this->apiSign($this->developer)->assertForbidden();
        $this->assertNull($this->signature('ketua'));

        Sanctum::actingAs($this->ketua, ['*']);
        $this->post("/api/v1/officer/reports/{$this->report->id}/sign", ['method' => 'upload', 'password' => self::SANDI, 'version' => 2], ['Accept' => 'application/json'])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');
    }

    public function test_sandi_salah_dan_metode_tidak_dikenal_ditolak(): void
    {
        $this->apiSign($this->ketua, extra: ['password' => 'salah'])->assertStatus(422)->assertJsonPath('error.fields.password.0', 'Sandi salah.');
        $this->apiSign($this->ketua, extra: ['method' => 'ttd'])->assertStatus(422);
        $this->assertNull($this->signature('ketua'));
    }

    public function test_berkas_rusak_tipe_terlarang_kosong_dan_ukuran_berlebih_ditolak(): void
    {
        $this->apiSign($this->ketua, bytes: 'bukan gambar')->assertStatus(422);
        $this->apiSign($this->ketua, bytes: "<?php echo 'x';")->assertStatus(422);
        $this->apiSign($this->ketua, bytes: $this->gambar(false))->assertStatus(422); // kosong
        $this->apiSign($this->ketua, bytes: $this->gambar(true, 40, 20))->assertStatus(422); // terlalu kecil
        $this->apiSign($this->ketua, bytes: $this->gambar(true, 4100, 100))->assertStatus(422); // terlalu lebar
        $this->apiSign($this->ketua, bytes: str_repeat("\0", 2 * 1024 * 1024 + 10))->assertStatus(422); // lebih dari 2 MB
        $gif = imagecreatetruecolor(120, 60);
        ob_start();
        imagegif($gif);
        $this->apiSign($this->ketua, bytes: (string) ob_get_clean())->assertStatus(422); // GIF tidak diizinkan
        $this->assertNull($this->signature('ketua'));
    }

    public function test_permintaan_berulang_idempoten_dan_versi_usang_ditolak(): void
    {
        $key = (string) Str::uuid();
        $this->apiSign($this->ketua, key: $key)->assertOk();
        $this->apiSign($this->ketua, key: $key)->assertOk(); // diulang (mis. retry jaringan)
        $this->assertSame(1, ReportSignature::where('report_id', $this->report->id)->where('role', 'ketua')->count());

        $this->apiSign($this->ketua, version: 1)->assertStatus(409); // versi BA yang dilihat sudah usang
    }

    public function test_draf_belum_dikirim_atau_sudah_diterbitkan_tidak_bisa_ditandatangani(): void
    {
        $this->report->forceFill(['status' => 'draft'])->save();
        $this->apiSign($this->ketua)->assertStatus(409);

        $this->report->forceFill(['status' => 'final', 'published_at' => now()])->save();
        $this->apiSign($this->ketua)->assertStatus(409);
    }

    public function test_admin_harus_menunggu_ketua_dan_hanya_admin_yang_boleh(): void
    {
        $this->webSign()->assertSessionHas('warning'); // Ketua belum menandatangani
        $this->assertNull($this->signature('admin'));

        $this->apiSign($this->ketua)->assertOk();
        $this->app['auth']->shouldUse('web'); // kembali ke sesi web setelah panggilan API
        $this->actingAs($this->ketua)->post("/pengajuan/{$this->submission->id}/laporan/{$this->report->id}/tanda-tangan", [
            'method' => 'draw', 'password' => self::SANDI, 'version' => 2, 'signature_data' => 'data:image/png;base64,' . base64_encode($this->gambar()),
        ])->assertRedirect('/login'); // petugas tidak boleh masuk Web Admin

        $this->webSign()->assertSessionHas('success');
        $this->assertSame('draw', $this->signature('admin')->method);
        $this->assertSame($this->admin->id, $this->signature('admin')->user_id);
    }

    public function test_terbitkan_terkunci_sampai_kedua_pihak_menandatangani(): void
    {
        $this->actingAs($this->admin);
        $url = "/pengajuan/{$this->submission->id}/laporan/{$this->report->id}/terbitkan";

        $this->post($url)->assertSessionHas('warning');
        $this->get("/pengajuan/{$this->submission->id}?tab=monitoring")->assertOk()->assertSee('Menunggu tanda tangan Ketua Pengawas');

        $this->apiSign($this->ketua)->assertOk();
        $this->app['auth']->shouldUse('web');
        $this->actingAs($this->admin)->post($url)->assertSessionHas('warning'); // admin belum
        $this->get("/pengajuan/{$this->submission->id}?tab=monitoring")->assertOk()->assertSee('Tanda tangani');

        $this->webSign()->assertSessionHas('success');
        $this->assertNull($this->report->fresh()->published_at);
        $this->post($url)->assertSessionHas('success');
        $this->assertNotNull($this->report->fresh()->published_at);
    }

    public function test_isi_ba_berubah_setelah_ketua_menandatangani_membatalkan_persetujuan(): void
    {
        $this->apiSign($this->ketua)->assertOk();
        $this->assertTrue(app(SignatureService::class)->status($this->report->fresh())['ketua']['signed']);

        // Perubahan isi (dan versi) membuat tanda tangan lama tidak berlaku lagi.
        $this->report->forceFill(['kesimpulan' => ['Diubah diam-diam'], 'version' => 3])->save();
        $this->assertFalse(app(SignatureService::class)->status($this->report->fresh())['ketua']['signed']);

        // Perubahan isi TANPA naik versi juga terdeteksi lewat hash.
        $this->report->forceFill(['kesimpulan' => ['Sesuai site plan'], 'version' => 2])->save();
        $this->assertTrue(app(SignatureService::class)->status($this->report->fresh())['ketua']['signed']);
        $this->report->forceFill(['kesimpulan' => ['Diubah lagi']])->save();
        $this->assertFalse(app(SignatureService::class)->status($this->report->fresh())['ketua']['signed']);

        $this->actingAs($this->admin)->post("/pengajuan/{$this->submission->id}/laporan/{$this->report->id}/terbitkan")->assertSessionHas('warning');
    }

    public function test_pdf_final_qr_dan_verifikasi_publik(): void
    {
        $foto = Storage::disk('local')->put('reports/1/photos/f.jpg', $this->gambar(true, 200, 100, 'jpeg'));
        InspectionReportPhoto::create([
            'report_id' => $this->report->id, 'position' => 1, 'stored_name' => 'f.jpg', 'storage_path' => 'reports/1/photos/f.jpg',
            'size_bytes' => 100, 'checksum' => hash('sha256', 'foto'), 'note' => 'Saluran', 'latitude' => -7.35, 'longitude' => 108.2, 'captured_at' => now(),
        ]);

        $this->apiSign($this->ketua)->assertOk();
        $this->webSign()->assertSessionHas('success');
        $this->actingAs($this->admin)->post("/pengajuan/{$this->submission->id}/laporan/{$this->report->id}/terbitkan")->assertSessionHas('success');

        $r = $this->report->fresh();
        $this->assertNotNull($r->pdf_path);
        $pdf = Storage::disk('local')->get($r->pdf_path);
        $this->assertStringStartsWith('%PDF', $pdf);
        $this->assertSame(hash('sha256', $pdf), $r->pdf_hash);

        // Unduh hanya untuk Admin dan pemilik laporan.
        $this->actingAs($this->admin)->get("/pengajuan/{$this->submission->id}/laporan/{$r->id}/pdf")->assertOk();
        Sanctum::actingAs($this->ketua, ['*']);
        $this->get("/api/v1/officer/reports/{$r->id}/pdf")->assertOk();
        Sanctum::actingAs($this->lain, ['*']);
        $this->get("/api/v1/officer/reports/{$r->id}/pdf")->assertNotFound();
        auth()->forgetGuards();

        // Halaman verifikasi QR: publik, status dasar, tanpa nama orang atau isi BA, ditandai template sementara.
        $this->get("/verifikasi/{$r->verification_token}")->assertOk()
            ->assertSee('600.2.5/BA-MON/X/2026/001')->assertSee('Diterbitkan')->assertSee('template sementara')
            ->assertDontSee('Ketua Uji')->assertDontSee('Admin Uji')->assertDontSee('Pemeriksaan PSU');
        $this->get('/verifikasi/' . str_repeat('a', 48))->assertNotFound();
    }

    public function test_detail_laporan_menampilkan_status_tanda_tangan_dan_alur_lama_tetap_jalan(): void
    {
        Sanctum::actingAs($this->ketua, ['*']);
        $this->get("/api/v1/officer/reports/{$this->report->id}", ['Accept' => 'application/json'])->assertOk()
            ->assertJsonPath('data.signatures.ketua.signed', false)->assertJsonPath('data.signatures.ready_to_publish', false);

        // Terima laporan tetap tidak digembok oleh tanda tangan (alur lama).
        $this->submission->forceFill(['stage' => 4, 'sub_status' => 'terjadwal'])->save();
        $this->actingAs($this->admin)->post("/pengajuan/{$this->submission->id}/terima-laporan")->assertSessionHas('success');
    }
}

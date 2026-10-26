<?php

namespace Tests\Feature\Api;

use App\Models\DeveloperProfile;
use App\Models\Submission;
use App\Models\SubmissionFile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SubmissionTest extends TestCase
{
    use RefreshDatabase;

    private User $dev;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $this->dev = $this->makeDeveloper('dev1', '1111111111111');
        Sanctum::actingAs($this->dev);
    }

    private function makeDeveloper(string $username, string $nib, string $role = 'pengembang'): User
    {
        $user = User::factory()->create([
            'username' => $username, 'role' => $role, 'password' => 'Sandi-Uji-2026',
            'is_active' => true, 'must_change_password' => false,
        ]);
        if ($role === 'pengembang') {
            DeveloperProfile::create([
                'user_id' => $user->id, 'nib' => $nib, 'nama_perumahan' => "Perumahan {$username}",
                'nama_pt' => 'PT Uji', 'nama_direktur' => 'Direktur', 'alamat_perumahan' => 'Jl. A',
                'alamat_pt' => 'Jl. B', 'no_hp_direktur' => '0812', 'email_pt' => 'pt@uji.id',
                'tipe_pengajuan' => 'site_plan_baru',
            ]);
        }

        return $user;
    }

    private function uuid(): string
    {
        return (string) \Illuminate\Support\Str::uuid();
    }

    private function draft(?User $owner = null, array $attrs = []): Submission
    {
        return Submission::create($attrs + [
            'developer_id' => ($owner ?? $this->dev)->id, 'client_uuid' => $this->uuid(),
            'stage' => 1, 'sub_status' => 'draft', 'current_step' => 1, 'version' => 1,
            'npwp' => '01.234.567.8-901.000', 'luas_lahan' => 1200.5, 'jumlah_unit' => 50,
            'tipe_perumahan' => 'subsidi',
        ]);
    }

    private function pdf(string $name = 'berkas.pdf'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, "%PDF-1.4\n1 0 obj\n<<>>\nendobj\n%%EOF\n");
    }

    private function dwg(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('siteplan.dwg', 'AC1027' . str_repeat("\0", 64));
    }

    /** Isi semua slot wajib langsung lewat basis data (cepat). */
    private function fillAllSlots(Submission $s, bool $withDwg = true): void
    {
        foreach (config('satu_rumah.slots') as $code => $slot) {
            if (!($slot['required'] ?? true)) {
                continue;
            }
            $types = $code === 'S4-01' ? ($withDwg ? ['pdf', 'dwg'] : ['pdf']) : ['pdf'];
            foreach ($types as $type) {
                SubmissionFile::create([
                    'submission_id' => $s->id, 'slot_code' => $code, 'version' => 1, 'is_current' => true,
                    'original_name' => "{$code}.{$type}", 'stored_name' => "{$code}.{$type}",
                    'storage_path' => "x/{$code}.{$type}", 'file_type' => $type, 'size_bytes' => 10,
                    'status' => 'menunggu_telaah', 'uploaded_by' => $s->developer_id,
                ]);
            }
        }
    }

    // ---- profil ----

    public function test_profil_dibuat_dan_dibaca_dan_nib_harus_unik(): void
    {
        $user = User::factory()->create(['username' => 'baru', 'role' => 'pengembang', 'is_active' => true, 'must_change_password' => false]);
        Sanctum::actingAs($user);

        $payload = [
            'nib' => '2222222222222', 'nama_perumahan' => 'Griya', 'nama_pt' => 'PT G', 'nama_direktur' => 'Dir',
            'alamat_perumahan' => 'A', 'alamat_pt' => 'B', 'no_hp_direktur' => '0812', 'email_pt' => 'g@g.id',
            'tipe_pengajuan' => 'site_plan_baru',
        ];

        $this->getJson('/api/v1/developer/profile')->assertOk()->assertJsonPath('data', null);
        $this->putJson('/api/v1/developer/profile', $payload)->assertOk()->assertJsonPath('data.nib', '2222222222222');
        $this->getJson('/api/v1/developer/profile')->assertJsonPath('data.nama_pt', 'PT G');

        $this->putJson('/api/v1/developer/profile', ['nib' => '123'] + $payload)
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');
        // NIB milik pengembang lain ditolak.
        $this->putJson('/api/v1/developer/profile', ['nib' => '1111111111111'] + $payload)
            ->assertStatus(422)->assertJsonPath('error.fields.nib.0', fn ($m) => is_string($m));
    }

    // ---- draf ----

    public function test_buat_draf_butuh_idempotency_key_dan_tidak_menggandakan(): void
    {
        $this->postJson('/api/v1/submissions')->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');

        $key = $this->uuid();
        $first = $this->postJson('/api/v1/submissions', [], ['Idempotency-Key' => $key])
            ->assertStatus(201)->assertJsonPath('data.status_tahap', 'draft');
        $again = $this->postJson('/api/v1/submissions', [], ['Idempotency-Key' => $key])->assertOk();

        $this->assertSame($first->json('data.id'), $again->json('data.id'));
        $this->assertSame(1, Submission::count());
    }

    public function test_daftar_hanya_milik_sendiri_dengan_filter_dan_paginasi(): void
    {
        $other = $this->makeDeveloper('dev2', '3333333333333');
        $this->draft();
        $this->draft(attrs: ['stage' => 2, 'sub_status' => 'baru', 'number' => 'SR-2026-0001']);
        $this->draft($other);

        $this->getJson('/api/v1/submissions')->assertOk()
            ->assertJsonCount(2, 'data')->assertJsonPath('meta.total', 2);
        $this->getJson('/api/v1/submissions?stage=2')->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status_tahap', 'pengajuanBaru');
        $this->getJson('/api/v1/submissions?q=SR-2026-0001')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/submissions?per_page=1')->assertJsonCount(1, 'data')->assertJsonPath('meta.total', 2);
    }

    public function test_pengajuan_orang_lain_memberi_404(): void
    {
        $other = $this->makeDeveloper('dev2', '3333333333333');
        $foreign = $this->draft($other);

        $this->getJson("/api/v1/submissions/{$foreign->id}")->assertStatus(404)->assertJsonPath('error.code', 'ERR-013');
        $this->patchJson("/api/v1/submissions/{$foreign->id}", ['version' => 1])->assertStatus(404);
        $this->postJson("/api/v1/submissions/{$foreign->id}/submit")->assertStatus(404);
        $this->postJson("/api/v1/submissions/{$foreign->id}/files", ['slot_code' => 'S2-01', 'file' => $this->pdf()])->assertStatus(404);
    }

    public function test_ubah_draf_memakai_version(): void
    {
        $s = $this->draft();

        $this->patchJson("/api/v1/submissions/{$s->id}", ['version' => 1, 'jumlah_unit' => 80, 'current_step' => 3])
            ->assertOk()->assertJsonPath('data.version', 2)->assertJsonPath('data.jumlah_unit', 80);

        $this->patchJson("/api/v1/submissions/{$s->id}", ['version' => 1, 'jumlah_unit' => 90])
            ->assertStatus(409)->assertJsonPath('error.code', 'ERR-015')->assertJsonPath('error.current_version', 2);

        $this->patchJson("/api/v1/submissions/{$s->id}", ['version' => 2, 'tipe_perumahan' => 'campuran'])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');
    }

    public function test_pengajuan_terkirim_tidak_bisa_diubah_lewat_patch(): void
    {
        $s = $this->draft(attrs: ['stage' => 2, 'sub_status' => 'baru']);

        $this->patchJson("/api/v1/submissions/{$s->id}", ['version' => 1, 'jumlah_unit' => 9])
            ->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');
    }

    // ---- berkas ----

    public function test_unggah_berkas_tersimpan_di_disk_privat(): void
    {
        $s = $this->draft();

        $res = $this->postJson("/api/v1/submissions/{$s->id}/files", ['slot_code' => 'S2-01', 'file' => $this->pdf('KTP asli.pdf')])
            ->assertStatus(201)
            ->assertJsonPath('data.slot_code', 'S2-01')
            ->assertJsonPath('data.status', 'menunggu_telaah')
            ->assertJsonPath('data.original_name', 'KTP asli.pdf');

        $file = SubmissionFile::find($res->json('data.id'));
        Storage::disk('local')->assertExists($file->storage_path);
        $this->assertNotSame('KTP asli.pdf', $file->stored_name);
        $this->assertSame(64, strlen($file->checksum));
    }

    public function test_unggah_berkas_ditolak_sesuai_kode_galat(): void
    {
        $s = $this->draft();
        $url = "/api/v1/submissions/{$s->id}/files";

        $this->postJson($url, ['slot_code' => 'S2-01', 'file' => UploadedFile::fake()->create('a.docx', 10)])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-002');
        $this->postJson($url, ['slot_code' => 'ZZ-99', 'file' => $this->pdf()])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-002');
        $this->postJson($url, ['slot_code' => 'S2-01', 'file' => UploadedFile::fake()->createWithContent('a.pdf', 'bukan pdf')])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-003');
        $this->postJson($url, ['slot_code' => 'S2-01', 'file' => UploadedFile::fake()->create('besar.pdf', 11 * 1024)])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-001');
        $this->postJson($url, ['slot_code' => 'S2-01'])
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');

        $this->assertSame(0, SubmissionFile::count());
    }

    public function test_slot_tunggal_diganti_dan_slot_jamak_bertambah(): void
    {
        $s = $this->draft();
        $url = "/api/v1/submissions/{$s->id}/files";

        $first = $this->postJson($url, ['slot_code' => 'S2-01', 'file' => $this->pdf()])->json('data.id');
        $second = $this->postJson($url, ['slot_code' => 'S2-01', 'file' => $this->pdf()])->json('data.id');
        $this->assertFalse(SubmissionFile::find($first)->is_current);
        $this->assertSame(2, SubmissionFile::find($second)->version);

        $this->postJson($url, ['slot_code' => 'S4-02', 'file' => $this->pdf()])->assertStatus(201);
        $this->postJson($url, ['slot_code' => 'S4-02', 'file' => $this->pdf()])->assertStatus(201);
        $this->assertSame(2, $s->currentFiles()->where('slot_code', 'S4-02')->count());

        $detail = $this->getJson("/api/v1/submissions/{$s->id}")->json('data.files');
        $this->assertCount(3, $detail); // hanya versi aktif
    }

    public function test_hapus_berkas_hanya_saat_draf(): void
    {
        $s = $this->draft();
        $id = $this->postJson("/api/v1/submissions/{$s->id}/files", ['slot_code' => 'S2-01', 'file' => $this->pdf()])->json('data.id');
        $path = SubmissionFile::find($id)->storage_path;

        $this->deleteJson("/api/v1/submissions/{$s->id}/files/{$id}")->assertOk();
        Storage::disk('local')->assertMissing($path);
        $this->assertNull(SubmissionFile::find($id));

        $sent = $this->draft(attrs: ['stage' => 2, 'sub_status' => 'baru']);
        $this->fillAllSlots($sent);
        $fid = $sent->currentFiles()->first()->id;
        $this->deleteJson("/api/v1/submissions/{$sent->id}/files/{$fid}")->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');
    }

    public function test_unduh_berkas_hanya_pemilik(): void
    {
        $s = $this->draft();
        $id = $this->postJson("/api/v1/submissions/{$s->id}/files", ['slot_code' => 'S2-01', 'file' => $this->pdf('ktp.pdf')])->json('data.id');

        $this->get("/api/v1/submissions/{$s->id}/files/{$id}/download")
            ->assertOk()->assertHeader('content-disposition');

        Sanctum::actingAs($this->makeDeveloper('dev2', '3333333333333'));
        $this->getJson("/api/v1/submissions/{$s->id}/files/{$id}/download")->assertStatus(404);
    }

    // ---- kirim ----

    public function test_kirim_gagal_bila_berkas_dan_profil_belum_lengkap(): void
    {
        $s = $this->draft(attrs: ['npwp' => null]);

        $res = $this->postJson("/api/v1/submissions/{$s->id}/submit")
            ->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');

        $this->assertContains('S2-01', $res->json('error.fields.slots'));
        $this->assertNotContains('S3-10', $res->json('error.fields.slots')); // opsional
        $this->assertArrayHasKey('npwp', $res->json('error.fields'));
        $this->assertSame('draft', $s->fresh()->sub_status);
        $this->assertNull($s->fresh()->number);
    }

    public function test_kirim_menolak_site_plan_tanpa_dwg(): void
    {
        $s = $this->draft();
        $this->fillAllSlots($s, withDwg: false);

        $this->postJson("/api/v1/submissions/{$s->id}/submit")
            ->assertStatus(422)->assertJsonPath('error.fields.S4-01.0', fn ($m) => str_contains($m, 'DWG'));
    }

    public function test_kirim_menerbitkan_nomor_berurutan_dan_idempoten(): void
    {
        $a = $this->draft();
        $this->fillAllSlots($a);
        $b = $this->draft();
        $this->fillAllSlots($b);
        $year = now()->format('Y');

        $this->postJson("/api/v1/submissions/{$a->id}/submit")->assertOk()
            ->assertJsonPath('data.number', "SR-{$year}-0001")
            ->assertJsonPath('data.stage', 2)
            ->assertJsonPath('data.status_tahap', 'pengajuanBaru');
        $this->postJson("/api/v1/submissions/{$b->id}/submit")->assertOk()
            ->assertJsonPath('data.number', "SR-{$year}-0002");

        // Kirim ulang tidak menerbitkan nomor baru.
        $this->postJson("/api/v1/submissions/{$a->id}/submit")->assertOk()
            ->assertJsonPath('data.number', "SR-{$year}-0001");
        $this->assertNotNull($a->fresh()->submitted_at);
    }

    // ---- perbaikan ----

    private function revisionSubmission(): array
    {
        $s = $this->draft(attrs: [
            'stage' => 2, 'sub_status' => 'perlu_perbaikan', 'number' => 'SR-2026-0007',
            'sla_paused_at' => now()->subHour(),
        ]);
        $this->fillAllSlots($s);
        $flagged = $s->currentFiles()->where('slot_code', 'S2-01')->first();
        $flagged->update(['status' => 'perlu_perbaikan', 'review_note' => 'Buram']);

        return [$s, $flagged];
    }

    public function test_kirim_ulang_hanya_saat_perbaikan_dan_semua_berkas_sudah_diganti(): void
    {
        $plain = $this->draft(attrs: ['stage' => 2, 'sub_status' => 'baru']);
        $this->postJson("/api/v1/submissions/{$plain->id}/resubmit")->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');

        [$s, $flagged] = $this->revisionSubmission();

        $this->postJson("/api/v1/submissions/{$s->id}/resubmit")
            ->assertStatus(422)->assertJsonPath('error.fields.slots.0', 'S2-01');

        $this->postJson("/api/v1/submissions/{$s->id}/files", ['slot_code' => 'S2-01', 'file' => $this->pdf()])
            ->assertStatus(201);
        $this->assertFalse($flagged->fresh()->is_current);

        $this->postJson("/api/v1/submissions/{$s->id}/resubmit")->assertOk()
            ->assertJsonPath('data.sub_status', 'perbaikan_terkirim');

        $fresh = $s->fresh();
        $this->assertNull($fresh->sla_paused_at);
        $this->assertGreaterThanOrEqual(3500, $fresh->sla_paused_seconds);
    }

    public function test_saat_perbaikan_slot_yang_tidak_diminta_tidak_boleh_diganti(): void
    {
        [$s] = $this->revisionSubmission();

        $this->postJson("/api/v1/submissions/{$s->id}/files", ['slot_code' => 'S2-02', 'file' => $this->pdf()])
            ->assertStatus(409)->assertJsonPath('error.code', 'ERR-011');
    }

    // ---- akses ----

    public function test_role_lain_dan_sandi_sementara_ditolak(): void
    {
        Sanctum::actingAs($this->makeDeveloper('lap1', '', 'tim_lapangan'));
        $this->getJson('/api/v1/submissions')->assertStatus(403)->assertJsonPath('error.code', 'ERR-022');

        $temp = $this->makeDeveloper('dev9', '9999999999999');
        $temp->update(['must_change_password' => true]);
        Sanctum::actingAs($temp);
        $this->getJson('/api/v1/submissions')->assertStatus(403)->assertJsonPath('error.code', 'ERR-022');
    }
}

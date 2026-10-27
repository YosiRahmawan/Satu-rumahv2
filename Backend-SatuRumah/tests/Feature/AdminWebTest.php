<?php

namespace Tests\Feature;

use App\Models\AppNotification;
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

class AdminWebTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $developer;
    private User $officer;
    private Submission $submission;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = $this->makeUser('verif1', 'verifikator');
        $this->developer = $this->makeUser('dev1', 'pengembang');
        $this->officer = $this->makeUser('petugas1', 'tim_lapangan');

        $this->submission = Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(), 'number' => 'SR-2026-0001',
            'nama_perumahan' => 'Griya Mangkubumi', 'alamat_proyek' => 'Jl. Karikil', 'stage' => 2, 'sub_status' => 'baru',
            'version' => 2, 'submitted_at' => now(),
        ]);
        foreach (config('satu_rumah.slots') as $code => $slot) {
            if (!($slot['required'] ?? true)) {
                continue;
            }
            $this->submission->files()->create([
                'slot_code' => $code, 'version' => 1, 'is_current' => true, 'original_name' => "{$code}.pdf",
                'stored_name' => "{$code}.pdf", 'storage_path' => "submissions/1/{$code}.pdf", 'file_type' => 'pdf',
                'size_bytes' => 1000, 'checksum' => str_repeat('a', 64), 'status' => 'menunggu_telaah',
                'uploaded_by' => $this->developer->id,
            ]);
        }
    }

    private function makeUser(string $username, string $role): User
    {
        return User::factory()->create([
            'username' => $username, 'role' => $role, 'password' => 'Sandi-Uji-2026',
            'is_active' => true, 'must_change_password' => false,
        ]);
    }

    private function approveAllFiles(): void
    {
        $this->submission->files()->update(['status' => 'lolos']);
    }

    public function test_halaman_admin_terbuka_untuk_verifikator(): void
    {
        $this->actingAs($this->admin);

        $this->get('/dashboard')->assertOk()->assertSee('Dashboard Pengawasan');
        $this->get('/pengajuan?search=Griya')->assertOk()->assertSee('SR-2026-0001');
        $this->get('/dashboard/export')->assertOk();
        foreach (['ringkasan', 'dokumen', 'monitoring', 'riwayat'] as $tab) {
            $this->get("/pengajuan/{$this->submission->id}?tab={$tab}")->assertOk()->assertSee('Griya Mangkubumi');
        }
        $this->get('/notifikasi')->assertOk();
    }

    public function test_notifikasi_menandai_sudah_dan_belum_dibaca_dengan_jenis_berbeda(): void
    {
        $this->actingAs($this->admin);
        $n = app(\App\Services\Notifier::class);
        $n->toUser($this->admin, $this->submission, 'submitted', 'Pengajuan baru masuk');
        $n->toUser($this->admin, $this->submission, 'report_submitted', 'Laporan survei dikirim')->forceFill(['read_at' => now()])->save();

        $this->get('/notifikasi')->assertOk()
            ->assertSee('Belum dibaca')->assertSee('Sudah dibaca')
            ->assertSee('Pengajuan Baru')->assertSee('Laporan Survei');
    }

    public function test_pengembang_tidak_bisa_membuka_web_admin(): void
    {
        $this->actingAs($this->developer)->get('/dashboard')->assertRedirect('/login');
    }

    public function test_perbaikan_wajib_ada_berkas_yang_ditandai_lalu_pengembang_diberi_tahu(): void
    {
        $this->actingAs($this->admin);
        $id = $this->submission->id;

        $this->post("/pengajuan/{$id}/perbaikan")->assertSessionHasErrors('files');

        $file = $this->submission->files()->first();
        $this->post("/pengajuan/{$id}/berkas/{$file->id}/nilai", ['decision' => 'perlu_perbaikan'])->assertSessionHasErrors('catatan');
        $this->post("/pengajuan/{$id}/berkas/{$file->id}/nilai", ['decision' => 'perlu_perbaikan', 'catatan' => 'Buram'])->assertSessionHasNoErrors();

        $this->post("/pengajuan/{$id}/perbaikan")->assertSessionHas('success');

        $s = $this->submission->fresh();
        $this->assertSame('perlu_perbaikan', $s->sub_status);
        $this->assertNotNull($s->correction_deadline_at);
        $this->assertNotNull($s->sla_paused_at);
        $this->assertSame(1, AppNotification::where('user_id', $this->developer->id)->where('type', 'revision_requested')->count());
        $this->assertDatabaseHas('submission_events', ['submission_id' => $id, 'type' => 'revision_requested']);

        // Saat menunggu perbaikan, tahap tidak bisa maju dan permintaan tidak bisa dikirim ganda.
        $this->post("/pengajuan/{$id}/perbaikan")->assertSessionHas('warning');
        $this->post("/pengajuan/{$id}/setujui-administrasi")->assertSessionHas('warning');
    }

    public function test_alur_penuh_sampai_keputusan_akhir(): void
    {
        $this->actingAs($this->admin);
        $id = $this->submission->id;

        // Berkas belum dinilai: belum boleh disetujui.
        $this->post("/pengajuan/{$id}/setujui-administrasi")->assertSessionHasErrors('slots');
        $this->assertStringContainsString('NIB', session('errors')->first('slots') . implode(' ', session('errors')->get('slots')));

        $this->approveAllFiles();
        $this->post("/pengajuan/{$id}/setujui-administrasi")->assertSessionHas('success');
        $this->assertSame(3, $this->submission->fresh()->stage);

        // Jadwal: petugas harus tim lapangan aktif.
        $this->post("/pengajuan/{$id}/jadwal", ['petugas_id' => $this->developer->id, 'tanggal' => now()->addDay()->toDateString()])
            ->assertSessionHasErrors('petugas');
        $this->post("/pengajuan/{$id}/jadwal", ['petugas_id' => $this->officer->id, 'tanggal' => now()->addDay()->toDateString()])
            ->assertSessionHas('success');
        $s = $this->submission->fresh();
        $this->assertSame([4, 'terjadwal'], [$s->stage, $s->sub_status]);
        $this->assertSame(1, AppNotification::where('user_id', $this->officer->id)->where('type', 'assignment')->count());

        // Anggota tim: hanya petugas lapangan aktif, dan tampil di tim penugasan.
        $anggota = $this->makeUser('petugas3', 'tim_lapangan');
        $this->post("/pengajuan/{$id}/jadwal", ['petugas_id' => $this->officer->id, 'tanggal' => now()->addDay()->toDateString(), 'anggota' => [$this->developer->id]])
            ->assertSessionHasErrors('anggota');
        $this->post("/pengajuan/{$id}/jadwal", ['petugas_id' => $this->officer->id, 'tanggal' => now()->addDay()->toDateString(), 'anggota' => [$anggota->id, $this->officer->id]])
            ->assertSessionHas('success');
        $this->assertSame(
            [$this->officer->name, $anggota->name],
            array_column(InspectionAssignment::whereIn('status', InspectionAssignment::OPEN)->latest('id')->first()->team(), 'nama')
        );
        $this->get("/pengajuan/{$id}?tab=monitoring")->assertOk()->assertSee($anggota->name);

        // Alihkan petugas: penugasan lama ditutup sebagai dialihkan.
        $other = $this->makeUser('petugas2', 'tim_lapangan');
        $this->post("/pengajuan/{$id}/jadwal", ['petugas_id' => $other->id, 'tanggal' => now()->addDays(2)->toDateString(), 'alasan' => 'Bentrok'])
            ->assertSessionHas('success');
        $this->assertSame(2, InspectionAssignment::where('submission_id', $id)->where('status', 'dialihkan')->count());
        $this->assertSame(1, InspectionAssignment::where('submission_id', $id)->whereIn('status', InspectionAssignment::OPEN)->count());

        // Tanpa laporan final belum bisa diterima.
        $this->post("/pengajuan/{$id}/terima-laporan")->assertSessionHasErrors('report');

        InspectionReport::create([
            'submission_id' => $id, 'officer_id' => $other->id, 'status' => 'final', 'report_number' => '600.2.5/BA-MON/X/2026/001',
            'nama_perumahan' => 'Griya Mangkubumi', 'monitoring_date' => now()->toDateString(), 'submitted_at' => now(), 'version' => 2,
        ]);
        $this->post("/pengajuan/{$id}/terima-laporan")->assertSessionHas('success');
        $this->assertSame(5, $this->submission->fresh()->stage);

        // Keputusan setuju wajib nomor dan tanggal.
        $this->post("/pengajuan/{$id}/keputusan", ['keputusan' => 'setuju'])->assertSessionHasErrors('decision_number');
        $this->post("/pengajuan/{$id}/keputusan", ['keputusan' => 'setuju', 'nomor' => 'SK-001/2026', 'tanggal' => '2026-11-10'])
            ->assertSessionHas('success');

        $s = $this->submission->fresh();
        $this->assertSame([6, 'selesai', 'SK-001/2026'], [$s->stage, $s->sub_status, $s->decision_number]);
        $this->assertNotNull($s->completed_at);
        $this->assertSame(1, AppNotification::where('user_id', $this->developer->id)->where('type', 'decided')->count());

        // Setelah selesai tidak ada tindakan lagi.
        $this->post("/pengajuan/{$id}/keputusan", ['keputusan' => 'tolak', 'catatan' => 'x'])->assertSessionHas('warning');
    }

    public function test_tolak_wajib_alasan(): void
    {
        $this->submission->forceFill(['stage' => 5, 'sub_status' => 'menunggu_persetujuan'])->save();
        $this->actingAs($this->admin);

        $this->post("/pengajuan/{$this->submission->id}/keputusan", ['keputusan' => 'tolak'])->assertSessionHasErrors('note');
        $this->post("/pengajuan/{$this->submission->id}/keputusan", ['keputusan' => 'tolak', 'catatan' => 'Tidak sesuai RTRW'])->assertSessionHas('success');
        $this->assertSame('ditolak', $this->submission->fresh()->sub_status);
    }

    public function test_siklus_revisi_admin_ke_pengembang_dan_kembali(): void
    {
        Storage::fake('local');
        $id = $this->submission->id;
        $file = $this->submission->files()->where('slot_code', 'S2-02')->first();

        // Admin menandai berkas lalu meminta perbaikan.
        $this->actingAs($this->admin);
        $this->post("/pengajuan/{$id}/berkas/{$file->id}/nilai", ['decision' => 'perlu_perbaikan', 'catatan' => 'NIB buram'])->assertSessionHasNoErrors();
        $this->post("/pengajuan/{$id}/perbaikan")->assertSessionHas('success');

        // Pengembang melihat berkas yang ditandai, mengganti, lalu kirim ulang.
        Sanctum::actingAs($this->developer);
        $detail = $this->getJson("/api/v1/submissions/{$id}")->assertOk()
            ->assertJsonPath('data.status_tahap', 'perluPerbaikan')->json('data');
        $flagged = collect($detail['files'])->firstWhere('status', 'perlu_perbaikan');
        $this->assertSame(['S2-02', 'NIB buram'], [$flagged['slot_code'], $flagged['review_note']]);
        $this->assertSame(1, AppNotification::where('user_id', $this->developer->id)->count());

        $this->postJson("/api/v1/submissions/{$id}/resubmit")->assertStatus(422); // belum diganti

        $this->post("/api/v1/submissions/{$id}/files", [
            'slot_code' => 'S2-02', 'replaces_file_id' => $flagged['id'],
            'file' => UploadedFile::fake()->createWithContent('nib-baru.pdf', "%PDF-1.4\n%%EOF\n"),
        ], ['Accept' => 'application/json'])->assertCreated();
        $this->postJson("/api/v1/submissions/{$id}/resubmit")->assertOk()->assertJsonPath('data.sub_status', 'perbaikan_terkirim');

        // Admin menerima kabar dan melihat riwayatnya.
        $this->assertSame(1, AppNotification::where('user_id', $this->admin->id)->where('type', 'resubmitted')->count());
        $this->actingAs($this->admin, 'web');
        $this->get("/pengajuan/{$id}?tab=riwayat")->assertOk()->assertSee('Perbaikan dikirim ulang')->assertSee('Permintaan perbaikan dikirim');
    }

    public function test_slot_berjamak_dengan_dua_berkas_bertanda_cukup_satu_pengganti(): void
    {
        Storage::fake('local');
        $id = $this->submission->id;
        $first = $this->submission->files()->where('slot_code', 'S3-05')->first();
        $second = $this->submission->files()->create([
            'slot_code' => 'S3-05', 'version' => 2, 'is_current' => true, 'original_name' => 'rek2.pdf', 'stored_name' => 'rek2.pdf',
            'storage_path' => 'submissions/1/rek2.pdf', 'file_type' => 'pdf', 'size_bytes' => 1000, 'checksum' => str_repeat('b', 64),
            'status' => 'menunggu_telaah', 'uploaded_by' => $this->developer->id,
        ]);

        $this->actingAs($this->admin);
        foreach ([$first, $second] as $f) {
            $this->post("/pengajuan/{$id}/berkas/{$f->id}/nilai", ['decision' => 'perlu_perbaikan', 'catatan' => 'Buram']);
        }
        $this->post("/pengajuan/{$id}/perbaikan")->assertSessionHas('success');

        Sanctum::actingAs($this->developer);
        $this->postJson("/api/v1/submissions/{$id}/resubmit")->assertStatus(422);
        $this->post("/api/v1/submissions/{$id}/files", [
            'slot_code' => 'S3-05', 'replaces_file_id' => $first->id,
            'file' => UploadedFile::fake()->createWithContent('rek-baru.pdf', "%PDF-1.4\n%%EOF\n"),
        ], ['Accept' => 'application/json'])->assertCreated();
        $this->postJson("/api/v1/submissions/{$id}/resubmit")->assertOk();

        $this->assertFalse($second->fresh()->is_current);
        $this->assertSame(1, $this->submission->currentFiles()->where('slot_code', 'S3-05')->count());
    }

    public function test_pratinjau_pdf_tampil_di_halaman_tanpa_unduh_dan_dwg_tidak_bisa(): void
    {
        Storage::fake('local');
        $id = $this->submission->id;
        $pdf = $this->submission->files()->where('slot_code', 'S2-01')->first();
        Storage::disk('local')->put($pdf->storage_path, "%PDF-1.4
%%EOF
");
        $dwg = $this->submission->files()->create([
            'slot_code' => 'S4-01', 'version' => 9, 'is_current' => false, 'original_name' => 'site.dwg', 'stored_name' => 'site.dwg',
            'storage_path' => 'submissions/1/site.dwg', 'file_type' => 'dwg', 'size_bytes' => 10, 'checksum' => str_repeat('c', 64),
            'status' => 'menunggu_telaah', 'uploaded_by' => $this->developer->id,
        ]);
        Storage::disk('local')->put($dwg->storage_path, 'AC1027');
        $this->actingAs($this->admin);

        // Pratinjau: tampil inline (bukan lampiran) bertipe PDF.
        $res = $this->get("/pengajuan/{$id}/berkas/{$pdf->id}/lihat")->assertOk();
        $this->assertSame('application/pdf', $res->headers->get('Content-Type'));
        $this->assertStringNotContainsString('attachment', (string) $res->headers->get('Content-Disposition'));

        // Unduh tetap lampiran; DWG tidak punya pratinjau.
        $this->assertStringContainsString('attachment', (string) $this->get("/pengajuan/{$id}/berkas/{$pdf->id}")->headers->get('Content-Disposition'));
        $this->get("/pengajuan/{$id}/berkas/{$dwg->id}/lihat")->assertNotFound();

        // Tab Dokumen memuat tombol pratinjau dan jendela penilaian.
        $this->get("/pengajuan/{$id}?tab=dokumen")->assertOk()
            ->assertSee('data-pratinjau', false)->assertSee('Simpan Status Dokumen')->assertSee('id="pdfFrame"', false);
    }

    public function test_pengajuan_draf_tidak_tampil_di_antrean(): void
    {
        $draft = Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(),
            'nama_perumahan' => 'Rahasia Draf', 'stage' => 1, 'sub_status' => 'draft', 'version' => 1,
        ]);
        $this->actingAs($this->admin);

        $this->get('/pengajuan')->assertDontSee('Rahasia Draf');
        $this->get("/pengajuan/{$draft->id}")->assertNotFound();
    }
}

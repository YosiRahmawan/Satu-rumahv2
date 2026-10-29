<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Setting;
use App\Models\Submission;
use App\Models\User;
use App\Services\SlaSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Tests\TestCase;

class TenggatPengaturanTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $developer;

    protected function setUp(): void
    {
        parent::setUp();
        $mk = fn (string $u, string $r) => User::factory()->create([
            'username' => $u, 'role' => $r, 'password' => 'Sandi-Uji-2026', 'is_active' => true, 'must_change_password' => false,
        ]);
        $this->admin = $mk('admin1', 'admin');
        $this->developer = $mk('dev1', 'pengembang');
    }

    private function pengajuan(array $attrs = []): Submission
    {
        return Submission::create($attrs + [
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(),
            'number' => 'SR-2026-' . str_pad((string) (Submission::count() + 1), 4, '0', STR_PAD_LEFT),
            'nama_perumahan' => 'Griya Uji', 'alamat_proyek' => 'Jl. Uji, Kawalu',
            'stage' => 2, 'sub_status' => 'dalam_telaah', 'version' => 1, 'submitted_at' => now(), 'stage_entered_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_sla_hari_kerja_ok_mendekati_dan_terlambat(): void
    {
        Setting::set('sla.t2_days', 5);
        Setting::set('sla.warning_percent', 80);
        $sla = new SlaSettings();

        Carbon::setTestNow('2026-11-02 08:00:00'); // Senin
        $s = $this->pengajuan(['stage_entered_at' => now()]);
        // 5 hari kerja dari Senin berakhir Senin berikutnya (akhir pekan dilewati).
        $this->assertSame('2026-11-09', $sla->dueAt($s)->toDateString());
        $this->assertSame('ok', $sla->state($s));

        Carbon::setTestNow('2026-11-08 08:00:00'); // Minggu, 6 dari 7 hari kalender lewat (86%)
        $this->assertSame('mendekati', $sla->state($s->fresh()));

        Carbon::setTestNow('2026-11-10 08:00:00');
        $this->assertSame('terlambat', $sla->state($s->fresh()));

        // Sedang menunggu perbaikan pengembang: jam SLA berhenti.
        $s->forceFill(['sub_status' => 'perlu_perbaikan'])->save();
        $this->assertNull($sla->state($s->fresh()));
    }

    public function test_pengingat_tenggat_perbaikan_dikirim_sekali_dan_tenggat_lewat_dikabarkan(): void
    {
        Carbon::setTestNow('2026-11-02 08:00:00');
        $s = $this->pengajuan(['sub_status' => 'perlu_perbaikan', 'sla_paused_at' => now()->subDays(11), 'correction_deadline_at' => now()->addDays(2)]);

        $this->artisan('pengajuan:ingatkan-tenggat')->assertSuccessful();
        $this->artisan('pengajuan:ingatkan-tenggat')->assertSuccessful(); // tidak dobel
        $this->assertSame(1, AppNotification::where('user_id', $this->developer->id)->where('type', 'deadline_reminder')->count());

        Carbon::setTestNow('2026-11-06 08:00:00'); // tenggat lewat
        $this->artisan('pengajuan:ingatkan-tenggat')->assertSuccessful();
        $this->artisan('pengajuan:ingatkan-tenggat')->assertSuccessful();
        $this->assertSame(1, AppNotification::where('user_id', $this->developer->id)->where('type', 'deadline_overdue')->count());
        $this->assertSame(1, AppNotification::where('user_id', $this->admin->id)->where('type', 'deadline_overdue_admin')->count());
    }

    public function test_pengingat_sla_ke_admin_saat_mendekati_dan_terlambat(): void
    {
        Setting::set('sla.t2_days', 5);
        Carbon::setTestNow('2026-11-02 08:00:00');
        $this->pengajuan();

        Carbon::setTestNow('2026-11-08 08:00:00');
        $this->artisan('pengajuan:ingatkan-tenggat');
        $this->assertSame(1, AppNotification::where('user_id', $this->admin->id)->where('type', 'sla_warning')->count());

        Carbon::setTestNow('2026-11-10 08:00:00');
        $this->artisan('pengajuan:ingatkan-tenggat');
        $this->artisan('pengajuan:ingatkan-tenggat');
        $this->assertSame(1, AppNotification::where('user_id', $this->admin->id)->where('type', 'sla_overdue')->count());
        $this->actingAs($this->admin)->get('/pengajuan')->assertOk()->assertSee('Lewat SLA');
    }

    public function test_halaman_pengaturan_menyimpan_nilai_dan_menolak_di_luar_batas(): void
    {
        $this->actingAs($this->admin)->get('/pengaturan')->assertOk()->assertSee('Pengaturan')->assertSee('Verifikasi Administrasi');

        $semua = ['sla_t2_days' => 6, 'sla_t3_days' => 8, 'sla_t4_days' => 9, 'sla_t5_days' => 4, 'sla_warning_percent' => 75,
            'revision_deadline_days' => 10, 'dashboard_target_per_kecamatan' => 30, 'upload_pdf_max_mb' => 12, 'upload_dwg_max_mb' => 60,
            'upload_max_files_per_slot' => 8, 'upload_photo_max_mb' => 9, 'upload_photo_max_count' => 12];

        $this->post('/pengaturan', ['nilai' => $semua])->assertSessionHas('success');
        $this->assertSame(6, Setting::getInt('sla.t2_days'));
        $this->assertSame(10, Setting::getInt('revision.deadline_days'));
        $this->assertSame(12, Setting::getInt('upload.photo_max_count'));

        $this->post('/pengaturan', ['nilai' => ['sla_t2_days' => 0] + $semua])->assertSessionHasErrors('nilai.sla_t2_days');
        $this->post('/pengaturan', ['nilai' => ['sla_warning_percent' => 100] + $semua])->assertSessionHasErrors('nilai.sla_warning_percent');
        $this->assertSame(6, Setting::getInt('sla.t2_days')); // tidak berubah
    }

    public function test_pengaturan_hanya_untuk_admin(): void
    {
        $this->actingAs($this->developer)->get('/pengaturan')->assertRedirect('/login');
    }
}

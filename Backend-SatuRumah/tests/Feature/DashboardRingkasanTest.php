<?php

namespace Tests\Feature;

use App\Models\InspectionAssignment;
use App\Models\Submission;
use App\Models\User;
use App\Services\DashboardSummary;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class DashboardRingkasanTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $developer;
    private User $officer;

    protected function setUp(): void
    {
        parent::setUp();
        $mk = fn (string $u, string $r) => User::factory()->create([
            'username' => $u, 'role' => $r, 'password' => 'Sandi-Uji-2026', 'is_active' => true, 'must_change_password' => false,
        ]);
        $this->admin = $mk('verif1', 'verifikator');
        $this->developer = $mk('dev1', 'pengembang');
        $this->officer = $mk('petugas1', 'tim_lapangan');
    }

    private function pengajuan(string $alamat, string $status = 'baru', int $stage = 2): Submission
    {
        return Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(),
            'number' => 'SR-' . now()->year . '-' . str_pad((string) (Submission::count() + 1), 4, '0', STR_PAD_LEFT),
            'nama_perumahan' => 'Griya ' . Str::random(4), 'alamat_proyek' => $alamat,
            'stage' => $stage, 'sub_status' => $status, 'version' => 1, 'submitted_at' => now(),
        ]);
    }

    public function test_kecamatan_dibaca_dari_alamat_tanpa_peduli_huruf_besar(): void
    {
        $s = new DashboardSummary();

        $this->assertSame('Kawalu', $s->kecamatanOf('Jl. Raya, KEC. KAWALU, Tasikmalaya'));
        $this->assertSame('Mangkubumi', $s->kecamatanOf('Kel. mangkubumi'));
        $this->assertNull($s->kecamatanOf('Jl. Tanpa Kecamatan'));
        $this->assertNull($s->kecamatanOf(null));
    }

    public function test_sebaran_menghitung_per_kecamatan_dan_mengabaikan_draf_dan_ditolak(): void
    {
        $this->pengajuan('Jl. A, Kawalu');
        $this->pengajuan('Jl. B, Kawalu');
        $this->pengajuan('Jl. C, Cibeureum');
        $this->pengajuan('Jl. D, Kawalu', 'ditolak', 5);
        $this->pengajuan('Jl. E, Kawalu', 'draft', 1);
        $this->pengajuan('Jl. F tanpa nama kecamatan');

        $r = (new DashboardSummary())->sebaranKecamatan();

        $this->assertSame(['Kawalu', 'Cibeureum'], array_column($r['rows'], 'nama'));
        $this->assertSame([2, 1], array_column($r['rows'], 'jumlah'));
        $this->assertTrue($r['rows'][0]['prioritas']);
        $this->assertFalse($r['rows'][1]['prioritas']);
        $this->assertSame(10, $r['rows'][0]['persen']); // 2 dari target bawaan 20
        $this->assertSame(1, $r['tanpa']);
    }

    public function test_jadwal_memuat_penugasan_hari_ini_dan_tujuh_hari_ke_depan_saja(): void
    {
        $a = $this->pengajuan('Jl. A, Kawalu', 'terjadwal', 4);
        $b = $this->pengajuan('Jl. B, Kawalu', 'terjadwal', 4);
        $c = $this->pengajuan('Jl. C, Kawalu', 'terjadwal', 4);
        $mk = fn (Submission $s, string $date, string $status = 'dijadwalkan') => InspectionAssignment::create([
            'submission_id' => $s->id, 'officer_id' => $this->officer->id, 'scheduled_date' => $date,
            'status' => $status, 'created_by' => $this->admin->id,
        ]);
        $mk($a, now()->toDateString());
        $mk($b, now()->addDays(3)->toDateString());
        $mk($c, now()->addDays(20)->toDateString()); // terlalu jauh
        $mk($c, now()->toDateString(), 'selesai');   // sudah selesai

        $r = (new DashboardSummary())->jadwalTinjauan();

        $this->assertSame(1, $r['hari_ini']);
        $this->assertCount(2, $r['items']);
        $this->assertTrue($r['items'][0]['hari_ini']);
        $this->assertSame($this->officer->name, $r['items'][0]['tim']);
    }

    public function test_dashboard_menampilkan_kedua_kartu_dan_ikut_berubah_saat_data_berubah(): void
    {
        $this->actingAs($this->admin);
        $this->pengajuan('Jl. A, Kawalu');

        $this->get('/dashboard')->assertOk()
            ->assertSee('Sebaran Audit Per Kecamatan')->assertSee('Kecamatan Kawalu')->assertSee('1 Berkas')
            ->assertSee('Jadwal Tinjauan Lapangan')->assertSee('id="ringkasan"', false);
        $this->get('/dashboard/ringkasan')->assertOk()->assertSee('data-lebar="5"', false); // 1 dari target 20

        // Data bertambah: panggilan berkala langsung menampilkan angka dan lebar batang baru.
        $this->pengajuan('Jl. B, Kawalu');
        $this->pengajuan('Jl. C, Kawalu');
        $this->get('/dashboard/ringkasan')->assertOk()
            ->assertSee('3 Berkas')->assertSee('data-lebar="15"', false)->assertSee('15% Target');
    }

    public function test_kartu_angka_menghitung_masuk_selesai_ditolak_tahun_ini_dan_ikut_berubah(): void
    {
        $this->actingAs($this->admin);
        $this->pengajuan('Jl. A, Kawalu');
        $this->pengajuan('Jl. B, Kawalu', 'selesai', 6);
        $this->pengajuan('Jl. C, Kawalu', 'ditolak', 5);
        $this->pengajuan('Jl. D, Kawalu', 'draft', 1); // draf tidak dihitung

        $k = (new DashboardSummary())->kpi();
        $this->assertSame([3, 1, 1], [$k['masuk'], $k['selesai'], $k['ditolak']]);

        $this->get('/dashboard/kpi')->assertOk()->assertSee('Dari 3 pengajuan masuk', false)->assertSee('1 ditolak');

        $this->pengajuan('Jl. E, Kawalu', 'selesai', 6);
        $this->get('/dashboard/kpi')->assertOk()->assertSee('Dari 4 pengajuan masuk', false);
        $this->get('/dashboard')->assertOk()->assertSee('id="kpi"', false)->assertSee('Disetujui');
    }

    public function test_ringkasan_hanya_untuk_verifikator_dan_administrator(): void
    {
        $this->actingAs($this->developer)->get('/dashboard/ringkasan')->assertRedirect('/login');
    }
}

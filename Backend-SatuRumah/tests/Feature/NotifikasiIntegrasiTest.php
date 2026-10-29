<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Submission;
use App\Models\User;
use App\Services\SubmissionWorkflow;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class NotifikasiIntegrasiTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private User $developer;
    private User $petugasA;
    private User $petugasB;
    private Submission $submission;

    protected function setUp(): void
    {
        parent::setUp();
        $mk = fn (string $u, string $r) => User::factory()->create([
            'username' => $u, 'email' => "$u@saturumah.go.id", 'role' => $r, 'password' => 'Sandi-Uji-2026', 'is_active' => true, 'must_change_password' => false,
        ]);
        $this->admin = $mk('admin1', 'admin');
        $this->developer = $mk('dev1', 'pengembang');
        $this->petugasA = $mk('petugas_a', 'tim_lapangan');
        $this->petugasB = $mk('petugas_b', 'tim_lapangan');
        $this->submission = Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(), 'number' => 'SR-2026-0001',
            'nama_perumahan' => 'Griya Uji', 'stage' => 4, 'sub_status' => 'terjadwal', 'version' => 1, 'submitted_at' => now(), 'stage_entered_at' => now(),
        ]);
    }

    private function jadwalkan(User $petugas, ?string $alasan = null): void
    {
        app(SubmissionWorkflow::class)->scheduleSurvey($this->submission, $petugas, now()->addDays(2)->toDateString(), null, $this->admin, $alasan);
    }

    private function jumlah(User $u, string $type): int
    {
        return AppNotification::where('user_id', $u->id)->where('type', $type)->count();
    }

    public function test_zona_waktu_aplikasi_wib_dan_bahasa_indonesia(): void
    {
        $this->assertSame('Asia/Jakarta', config('app.timezone'));
        $this->assertSame('id', app()->getLocale());

        // PHP memakai zona yang sama, sehingga jam yang ditulis server (now) sesuai dengan label WIB.
        $this->assertSame('Asia/Jakarta', date_default_timezone_get());
        $this->assertSame('+07:00', now()->format('P'));
        $this->assertSame('Kamis', \Illuminate\Support\Carbon::parse('2026-10-29 10:00:00')->translatedFormat('l'));
    }

    public function test_jadwal_baru_lalu_diubah_untuk_petugas_yang_sama_tidak_lagi_berjudul_tugas_baru(): void
    {
        $this->jadwalkan($this->petugasA);
        $this->assertSame(1, $this->jumlah($this->petugasA, 'assignment'));

        $this->jadwalkan($this->petugasA); // tanggal atau tim berubah, petugas sama
        $this->assertSame(1, $this->jumlah($this->petugasA, 'assignment'));
        $this->assertSame(1, $this->jumlah($this->petugasA, 'assignment_rescheduled'));
        $this->assertSame('Jadwal survei diubah', AppNotification::where('type', 'assignment_rescheduled')->value('title'));
        $this->assertSame(0, $this->jumlah($this->petugasA, 'assignment_reassigned')); // tidak dialihkan ke orang lain

        // Pengembang juga diberi tahu bahwa jadwal berubah (bukan dijadwalkan baru).
        $this->assertSame('Jadwal survei diubah', AppNotification::where('user_id', $this->developer->id)->where('type', 'survey_scheduled')->latest('id')->value('title'));
    }

    public function test_tugas_dialihkan_ke_petugas_lain_memberi_tahu_petugas_lama_dan_baru(): void
    {
        $this->jadwalkan($this->petugasA);
        $this->jadwalkan($this->petugasB, 'Bentrok jadwal');

        $lama = AppNotification::where('user_id', $this->petugasA->id)->where('type', 'assignment_reassigned')->first();
        $this->assertNotNull($lama);
        $this->assertSame('Tugas survei dialihkan', $lama->title);
        $this->assertStringContainsString('Bentrok jadwal', $lama->body);

        // Petugas baru menerima tugas baru; petugas lama tidak mendapat "tugas baru" lagi.
        $this->assertSame(1, $this->jumlah($this->petugasB, 'assignment'));
        $this->assertSame(1, $this->jumlah($this->petugasA, 'assignment'));
        $this->assertSame(0, $this->jumlah($this->petugasB, 'assignment_reassigned'));
    }

    public function test_lonceng_dan_antrean_web_dapat_diperbarui_tanpa_muat_ulang(): void
    {
        $this->actingAs($this->admin);
        $this->get('/dashboard')->assertOk()->assertSee('id="loncengDot"', false)->assertSee('id="antreanHitung"', false)->assertSee('notifikasi\/jumlah', false);

        $this->get('/notifikasi/jumlah')->assertOk()->assertExactJson(['belum_dibaca' => 0, 'antrean' => 0]);

        Submission::create([
            'developer_id' => $this->developer->id, 'client_uuid' => (string) Str::uuid(), 'number' => 'SR-2026-0002',
            'nama_perumahan' => 'Baru', 'stage' => 2, 'sub_status' => 'baru', 'version' => 1, 'submitted_at' => now(),
        ]);
        app(\App\Services\Notifier::class)->toUser($this->admin, $this->submission, 'submitted', 'Pengajuan baru masuk');

        $this->get('/notifikasi/jumlah')->assertOk()->assertExactJson(['belum_dibaca' => 1, 'antrean' => 1]);

        // Hanya admin.
        $this->actingAs($this->developer)->get('/notifikasi/jumlah')->assertRedirect('/login');
    }
}

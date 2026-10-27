<?php

namespace Tests\Feature\Api;

use App\Models\AppNotification;
use App\Models\Submission;
use App\Models\User;
use App\Services\Notifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    private User $dev;
    private User $other;
    private Submission $submission;

    protected function setUp(): void
    {
        parent::setUp();
        $mk = fn (string $u, string $r) => User::factory()->create([
            'username' => $u, 'role' => $r, 'password' => 'Sandi-Uji-2026', 'is_active' => true, 'must_change_password' => false,
        ]);
        $this->dev = $mk('dev1', 'pengembang');
        $this->other = $mk('dev2', 'pengembang');
        $this->submission = Submission::create([
            'developer_id' => $this->dev->id, 'client_uuid' => (string) Str::uuid(), 'number' => 'SR-2026-0001',
            'nama_perumahan' => 'Griya', 'stage' => 2, 'sub_status' => 'baru', 'version' => 1,
        ]);
        $n = app(Notifier::class);
        $n->toDeveloper($this->submission, 'revision_requested', 'Perlu diperbaiki', 'Ada berkas buram');
        $n->toUser($this->other, $this->submission, 'x', 'Milik orang lain');
        $n->event($this->submission, null, 'submitted', 'Pengajuan dikirim');
    }

    public function test_daftar_hanya_milik_akun_sendiri_dengan_jumlah_belum_dibaca(): void
    {
        Sanctum::actingAs($this->dev);

        $res = $this->getJson('/api/v1/notifications')->assertOk();
        $res->assertJsonCount(1, 'data')->assertJsonPath('meta.unread_count', 1)->assertJsonPath('data.0.read', false)->assertJsonPath('data.0.submission_number', 'SR-2026-0001');
    }

    public function test_tandai_dibaca_dan_tidak_bisa_menyentuh_milik_orang_lain(): void
    {
        $mine = AppNotification::where('user_id', $this->dev->id)->first();
        $theirs = AppNotification::where('user_id', $this->other->id)->first();
        Sanctum::actingAs($this->dev);

        $this->postJson("/api/v1/notifications/{$theirs->id}/read")->assertStatus(404)->assertJsonPath('error.code', 'ERR-013');
        $this->postJson("/api/v1/notifications/{$mine->id}/read")->assertOk();
        $this->getJson('/api/v1/notifications?unread=1')->assertJsonCount(0, 'data')->assertJsonPath('meta.unread_count', 0);
        $this->assertNull($theirs->fresh()->read_at);
    }

    public function test_timeline_hanya_untuk_pemilik(): void
    {
        Sanctum::actingAs($this->dev);
        $this->getJson("/api/v1/submissions/{$this->submission->id}/timeline")
            ->assertOk()->assertJsonPath('data.0.title', 'Pengajuan dikirim');

        Sanctum::actingAs($this->other);
        $this->getJson("/api/v1/submissions/{$this->submission->id}/timeline")->assertStatus(404);
    }
}

<?php

namespace Tests\Feature\Api;

use App\Models\DeveloperProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private const PASSWORD = 'Sandi-Uji-2026';

    private function makeUser(array $attributes = []): User
    {
        return User::factory()->create($attributes + [
            'username' => 'pengembang1',
            'role' => 'pengembang',
            'password' => self::PASSWORD,
            'is_active' => true,
            'must_change_password' => false,
        ]);
    }

    private function login(string $username = 'pengembang1', string $password = self::PASSWORD)
    {
        return $this->postJson('/api/v1/auth/login', [
            'username' => $username,
            'password' => $password,
            'device_name' => 'hp-uji',
        ]);
    }

    public function test_login_berhasil_mengembalikan_token_dan_profil(): void
    {
        $this->makeUser(['failed_login_attempts' => 3]);

        $this->login(' Pengembang1 ')
            ->assertOk()
            ->assertJsonPath('user.role', 'pengembang')
            ->assertJsonPath('user.username', 'pengembang1')
            ->assertJsonPath('must_change_password', false)
            ->assertJsonStructure(['token']);

        $this->assertSame(0, User::first()->failed_login_attempts);
    }

    public function test_username_tak_dikenal_dan_sandi_salah_memberi_jawaban_sama(): void
    {
        $this->makeUser();

        $a = $this->login('tidakada')->assertStatus(401)->assertJsonPath('error.code', 'ERR-020');
        $b = $this->login('pengembang1', 'salah')->assertStatus(401)->assertJsonPath('error.code', 'ERR-020');

        $this->assertSame($a->json('error.message'), $b->json('error.message'));
        $this->assertSame(1, User::first()->failed_login_attempts);
    }

    public function test_akun_terkunci_setelah_lima_kali_gagal(): void
    {
        $this->makeUser();

        for ($i = 0; $i < 4; $i++) {
            $this->login('pengembang1', 'salah')->assertStatus(401);
        }
        $this->login('pengembang1', 'salah')
            ->assertStatus(423)
            ->assertJsonPath('error.code', 'ERR-021')
            ->assertJsonStructure(['error' => ['locked_until']]);

        // Sandi benar pun ditolak selama terkunci (jendela laju 1 menit sudah lewat).
        $this->travel(61)->seconds();
        $this->login()->assertStatus(423)->assertJsonPath('error.code', 'ERR-021');
    }

    public function test_kunci_yang_sudah_lewat_tidak_menghalangi(): void
    {
        $this->makeUser(['locked_until' => now()->subMinute(), 'failed_login_attempts' => 0]);

        $this->login()->assertOk();
        $this->assertNull(User::first()->locked_until);
    }

    public function test_akun_nonaktif_ditolak(): void
    {
        $this->makeUser(['is_active' => false]);

        $this->login()->assertStatus(403)->assertJsonPath('error.code', 'ERR-022');
    }

    public function test_akun_web_admin_tidak_bisa_masuk_lewat_api(): void
    {
        $this->makeUser(['username' => 'verif1', 'role' => 'verifikator']);

        $this->login('verif1')->assertStatus(403)->assertJsonPath('error.code', 'ERR-022');
    }

    public function test_isian_login_kosong_memakai_format_galat_baku(): void
    {
        $this->postJson('/api/v1/auth/login', [])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'ERR-010')
            ->assertJsonStructure(['error' => ['fields' => ['username', 'password']]]);
    }

    public function test_login_dibatasi_laju_per_username(): void
    {
        for ($i = 0; $i < 5; $i++) {
            $this->login('tidakada')->assertStatus(401);
        }
        $this->login('tidakada')->assertStatus(429);
    }

    public function test_me_butuh_token_dan_memuat_profil_pengembang(): void
    {
        $user = $this->makeUser();
        DeveloperProfile::create([
            'user_id' => $user->id, 'nib' => '1234567890123', 'nama_perumahan' => 'Perumahan Uji',
            'nama_pt' => 'PT Uji', 'nama_direktur' => 'Direktur', 'alamat_perumahan' => 'Jl. A',
            'alamat_pt' => 'Jl. B', 'no_hp_direktur' => '0812', 'email_pt' => 'pt@uji.id',
            'tipe_pengajuan' => 'site_plan_baru',
        ]);

        $this->getJson('/api/v1/me')->assertStatus(401)->assertJsonPath('error.code', 'ERR-020');

        $token = $this->login()->json('token');
        $this->withToken($token)->getJson('/api/v1/me')
            ->assertOk()
            ->assertJsonPath('user.developer_profile.nib', '1234567890123');
    }

    public function test_logout_mencabut_token(): void
    {
        $this->makeUser();
        $token = $this->login()->json('token');

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/v1/me')->assertStatus(401);
    }

    public function test_login_ulang_di_perangkat_sama_mencabut_token_lama(): void
    {
        $this->makeUser();
        $old = $this->login()->json('token');
        $this->login()->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken($old)->getJson('/api/v1/me')->assertStatus(401);
    }

    public function test_sandi_sementara_memblokir_jalur_lain_sampai_diganti(): void
    {
        Route::middleware(['api', 'auth:sanctum', 'password.changed'])->get('/api/v1/_uji', fn () => ['ok' => true]);
        $this->makeUser(['must_change_password' => true]);

        $login = $this->login()->assertOk()->assertJsonPath('must_change_password', true);
        $token = $login->json('token');

        $this->withToken($token)->getJson('/api/v1/_uji')->assertStatus(403)->assertJsonPath('error.code', 'ERR-022');
        $this->withToken($token)->getJson('/api/v1/me')->assertOk();

        $this->withToken($token)->postJson('/api/v1/auth/change-password', [
            'current_password' => self::PASSWORD,
            'new_password' => 'Sandi-Baru-2026',
        ])->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/v1/_uji')->assertOk();
        $this->login('pengembang1', self::PASSWORD)->assertStatus(401);
        $this->login('pengembang1', 'Sandi-Baru-2026')->assertOk();
    }

    public function test_ganti_sandi_menolak_sandi_lama_salah_dan_sandi_lemah(): void
    {
        $this->makeUser();
        $token = $this->login()->json('token');

        $this->withToken($token)->postJson('/api/v1/auth/change-password', [
            'current_password' => 'salah',
            'new_password' => 'Sandi-Baru-2026',
        ])->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');

        $this->withToken($token)->postJson('/api/v1/auth/change-password', [
            'current_password' => self::PASSWORD,
            'new_password' => 'pendek',
        ])->assertStatus(422)->assertJsonPath('error.code', 'ERR-010');
    }

    public function test_ganti_sandi_mencabut_token_perangkat_lain(): void
    {
        $user = $this->makeUser();
        $other = $user->createToken('hp-lain')->plainTextToken;
        $token = $this->login()->json('token');

        $this->withToken($token)->postJson('/api/v1/auth/change-password', [
            'current_password' => self::PASSWORD,
            'new_password' => 'Sandi-Baru-2026',
        ])->assertOk();

        $this->app['auth']->forgetGuards();
        $this->withToken($other)->getJson('/api/v1/me')->assertStatus(401);
        $this->withToken($token)->getJson('/api/v1/me')->assertOk();
    }

    public function test_web_admin_menolak_akun_mobile(): void
    {
        $dev = $this->makeUser();

        $this->actingAs($dev)->get('/dashboard')->assertRedirect(route('login'));
    }
}

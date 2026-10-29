<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AccountManagementTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = $this->akun('admin1', 'admin');
    }

    private function akun(string $username, string $role, array $extra = []): User
    {
        return User::factory()->create($extra + [
            'username' => $username, 'email' => "{$username}@saturumah.go.id", 'role' => $role,
            'password' => 'Sandi-Uji-2026', 'is_active' => true, 'must_change_password' => false,
        ]);
    }

    public function test_admin_menambah_akun_dengan_sandi_sementara_yang_wajib_diganti(): void
    {
        $this->actingAs($this->admin)->post('/akun', [
            'name' => 'Petugas Baru', 'username' => 'petugas_baru', 'email' => 'baru@saturumah.go.id', 'role' => 'tim_lapangan',
        ])->assertSessionHas('success')->assertSessionHas('sandi_sementara');

        $baru = User::where('username', 'petugas_baru')->first();
        $this->assertTrue($baru->must_change_password);
        $this->assertTrue($baru->is_active);

        $sandi = session('sandi_sementara')['sandi'];
        $this->assertSame(12, strlen($sandi));
        $this->assertTrue(\Hash::check($sandi, $baru->password));
    }

    public function test_email_dan_username_harus_unik_dan_role_dibatasi(): void
    {
        $this->actingAs($this->admin)->post('/akun', [
            'name' => 'X', 'username' => 'admin1', 'email' => 'admin1@saturumah.go.id', 'role' => 'administrator',
        ])->assertSessionHasErrors(['username', 'email', 'role']);
    }

    public function test_reset_sandi_memaksa_ganti_dan_mencabut_token_aplikasi(): void
    {
        $petugas = $this->akun('petugas1', 'tim_lapangan');
        $petugas->createToken('hp');

        $this->actingAs($this->admin)->post("/akun/{$petugas->id}/reset-sandi")->assertSessionHas('sandi_sementara');

        $petugas->refresh();
        $this->assertTrue($petugas->must_change_password);
        $this->assertFalse(\Hash::check('Sandi-Uji-2026', $petugas->password));
        $this->assertSame(0, $petugas->tokens()->count());
    }

    public function test_akun_sendiri_tidak_bisa_direset_atau_dinonaktifkan(): void
    {
        $this->actingAs($this->admin);
        $this->post("/akun/{$this->admin->id}/reset-sandi")->assertSessionHas('warning');
        $this->post("/akun/{$this->admin->id}/status")->assertSessionHas('warning');
        $this->assertTrue($this->admin->fresh()->is_active);
    }

    public function test_akun_nonaktif_tidak_bisa_masuk_dan_sesinya_ditolak(): void
    {
        $petugas = $this->akun('petugas1', 'tim_lapangan');
        $petugas->createToken('hp');
        $kedua = $this->akun('admin2', 'admin');

        $this->actingAs($this->admin)->post("/akun/{$kedua->id}/status");
        $this->assertFalse($kedua->fresh()->is_active);

        // Sesi web yang masih hidup ditolak begitu akun dinonaktifkan.
        $this->actingAs($kedua->fresh())->get('/dashboard')->assertRedirect('/login');

        $this->actingAs($this->admin)->post("/akun/{$petugas->id}/status");
        $this->assertSame(0, $petugas->tokens()->count());
    }

    public function test_halaman_akun_dan_perintah_darurat(): void
    {
        $this->actingAs($this->admin)->get('/akun')->assertOk()->assertSee('Manajemen Akun')->assertSee('admin1@saturumah.go.id');
        $this->actingAs($this->akun('petugas1', 'tim_lapangan'))->get('/akun')->assertRedirect('/login');

        $this->artisan('akun:reset-sandi', ['email' => 'admin1@saturumah.go.id'])->assertSuccessful();
        $this->assertTrue($this->admin->fresh()->must_change_password);
        $this->artisan('akun:reset-sandi', ['email' => 'tidak@ada.id'])->assertFailed();
    }
}

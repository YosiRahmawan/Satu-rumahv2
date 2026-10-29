<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Manajemen akun: tambah, nonaktifkan, dan reset sandi. Akun tertutup, tidak ada pendaftaran mandiri. */
class AccountController extends Controller
{
    public const ROLES = ['admin' => 'Admin', 'tim_lapangan' => 'Petugas lapangan', 'pengembang' => 'Pengembang'];

    public function index(Request $request)
    {
        $users = User::query()
            ->when($request->query('role'), fn ($q, $v) => $q->where('role', $v))
            ->when($request->query('search'), fn ($q, $term) => $q->where(fn ($w) => $w
                ->where('name', 'like', "%{$term}%")->orWhere('email', 'like', "%{$term}%")->orWhere('username', 'like', "%{$term}%")))
            ->orderByRaw("case role when 'admin' then 0 when 'tim_lapangan' then 1 else 2 end")
            ->orderBy('name')->paginate(20)->withQueryString();

        return view('admin.akun.index', ['users' => $users, 'roles' => self::ROLES]);
    }

    public function store(Request $request)
    {
        $this->bersihkanNip($request);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'username' => ['required', 'alpha_dash', 'max:50', 'unique:users,username'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'role' => ['required', Rule::in(array_keys(self::ROLES))],
            'jabatan' => ['nullable', 'string', 'max:100'],
            'nip' => ['nullable', 'digits_between:8,25', 'unique:users,nip'],
        ]);

        $sandi = User::sandiSementara();
        User::create($data + [
            'password' => $sandi, 'is_active' => true, 'must_change_password' => true,
            'avatar_initials' => mb_strtoupper(mb_substr($data['name'], 0, 2)),
        ]);

        return back()->with('success', "Akun {$data['name']} dibuat.")
            ->with('sandi_sementara', ['nama' => $data['name'], 'email' => $data['email'], 'sandi' => $sandi]);
    }

    /** Mengubah nama, jabatan, dan NIP. Email, username, dan role tidak diubah dari sini. */
    public function update(Request $request, int $id)
    {
        $user = User::findOrFail($id);
        $this->bersihkanNip($request);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'jabatan' => ['nullable', 'string', 'max:100'],
            'nip' => ['nullable', 'digits_between:8,25', Rule::unique('users', 'nip')->ignore($user->id)],
        ]);
        $user->forceFill($data + ['nip' => null])->save(); // NIP kosong disimpan sebagai null

        return back()->with('success', "Data {$user->name} diperbarui.");
    }

    /** NIP sering ditulis dengan spasi atau titik; hanya angkanya yang disimpan. */
    private function bersihkanNip(Request $request): void
    {
        if ($request->filled('nip')) {
            $request->merge(['nip' => preg_replace('/\D+/', '', (string) $request->input('nip'))]);
        }
    }

    public function resetPassword(Request $request, int $id)
    {
        $user = User::findOrFail($id);
        if ($user->id === $request->user()->id) {
            return back()->with('warning', 'Untuk akun sendiri, gunakan menu Ganti Sandi.');
        }

        $sandi = $user->resetSandi();

        return back()->with('success', "Sandi {$user->name} direset.")
            ->with('sandi_sementara', ['nama' => $user->name, 'email' => $user->email, 'sandi' => $sandi]);
    }

    public function toggleActive(Request $request, int $id)
    {
        $user = User::findOrFail($id);

        if ($user->is_active) {
            // Pelaku selalu admin aktif, jadi melarang menonaktifkan diri sendiri sudah menjamin selalu ada admin aktif.
            if ($user->id === $request->user()->id) {
                return back()->with('warning', 'Akun yang sedang dipakai tidak bisa dinonaktifkan.');
            }
        }

        $user->forceFill(['is_active' => !$user->is_active])->save();
        if (!$user->is_active) {
            $user->tokens()->delete();
        }

        return back()->with('success', $user->is_active ? "Akun {$user->name} diaktifkan." : "Akun {$user->name} dinonaktifkan.");
    }
}

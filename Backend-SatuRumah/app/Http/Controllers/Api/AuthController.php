<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

/**
 * Autentikasi API untuk aplikasi Flutter (pengembang dan tim lapangan).
 * Akun bersifat tertutup: dibuat Administrator, tidak ada pendaftaran mandiri.
 * Verifikator dan Administrator memakai Web Admin, bukan API ini.
 */
class AuthController extends Controller
{
    /** Role yang boleh memakai aplikasi mobile. */
    public const MOBILE_ROLES = ['pengembang', 'tim_lapangan'];

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'username' => ['required', 'string', 'max:50'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::where('username', mb_strtolower(trim($data['username'])))->first();

        if (!$user) {
            // Waktu respons dibuat sama agar username yang ada tidak bisa ditebak.
            Hash::check($data['password'], '$2y$12$usesomesillystringforsaltuQ1m1o0eE5y0Yp4kKq6o5nq1xk9a');

            return $this->invalidCredentials();
        }

        if ($user->locked_until && $user->locked_until->isFuture()) {
            return $this->error('ERR-021', 'Akun terkunci sementara karena terlalu banyak percobaan masuk.', 423, [
                'locked_until' => $user->locked_until->toIso8601String(),
            ]);
        }

        if (!Hash::check($data['password'], $user->password)) {
            return $this->registerFailedAttempt($user);
        }

        if (!$user->is_active) {
            return $this->error('ERR-022', 'Akun tidak aktif. Hubungi Administrator.', 403);
        }

        if (!in_array($user->role, self::MOBILE_ROLES, true)) {
            return $this->error('ERR-022', 'Akun ini memakai Web Admin, bukan aplikasi mobile.', 403);
        }

        $user->forceFill(['failed_login_attempts' => 0, 'locked_until' => null])->save();

        $device = $data['device_name'] ?? 'mobile';
        // Satu token aktif per perangkat; masuk ulang di perangkat yang sama mencabut yang lama.
        $user->tokens()->where('name', $device)->delete();
        $token = $user->createToken($device)->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userPayload($user),
            'must_change_password' => $user->must_change_password,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil keluar.']);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();
        $payload = $this->userPayload($user);

        if ($user->role === 'pengembang') {
            $payload['developer_profile'] = $user->developerProfile;
        }

        return response()->json([
            'user' => $payload,
            'must_change_password' => $user->must_change_password,
        ]);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'different:current_password', Password::min(8)->letters()->numbers()],
        ]);

        $user = $request->user();

        if (!Hash::check($data['current_password'], $user->password)) {
            return $this->error('ERR-010', 'Kata sandi saat ini salah.', 422, [
                'fields' => ['current_password' => ['Kata sandi saat ini salah.']],
            ]);
        }

        $user->forceFill([
            'password' => $data['new_password'],
            'must_change_password' => false,
        ])->save();

        // Perangkat lain harus masuk ulang.
        $current = $request->user()->currentAccessToken()->getKey();
        $user->tokens()->where('id', '!=', $current)->delete();

        return response()->json(['message' => 'Kata sandi diperbarui.']);
    }

    private function registerFailedAttempt(User $user): JsonResponse
    {
        $max = Setting::getInt('auth.max_attempts', 5);
        $attempts = $user->failed_login_attempts + 1;

        if ($attempts >= $max) {
            $lockedUntil = now()->addMinutes(Setting::getInt('auth.lock_minutes', 15));
            $user->forceFill(['failed_login_attempts' => 0, 'locked_until' => $lockedUntil])->save();

            return $this->error('ERR-021', 'Akun terkunci sementara karena terlalu banyak percobaan masuk.', 423, [
                'locked_until' => $lockedUntil->toIso8601String(),
            ]);
        }

        $user->forceFill(['failed_login_attempts' => $attempts])->save();

        return $this->invalidCredentials();
    }

    private function invalidCredentials(): JsonResponse
    {
        return $this->error('ERR-020', 'Username atau kata sandi salah.', 401);
    }

    /** @return array<string, mixed> */
    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'username' => $user->username,
            'role' => $user->role,
            'jabatan' => $user->jabatan,
        ];
    }

    /** @param array<string, mixed> $extra */
    private function error(string $code, string $message, int $status, array $extra = []): JsonResponse
    {
        $fields = $extra['fields'] ?? null;
        unset($extra['fields']);

        return response()->json([
            'error' => array_filter(
                ['code' => $code, 'message' => $message, 'fields' => $fields] + $extra,
                fn ($v) => $v !== null
            ),
        ], $status);
    }
}

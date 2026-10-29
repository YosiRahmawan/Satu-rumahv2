<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function showLogin()
    {
        if (Auth::check()) {
            return redirect()->route('dashboard');
        }
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        // Batas percobaan per pasangan IP + email (5 per menit) agar sandi tidak bisa ditebak berulang.
        $key = 'login-web|' . $request->ip() . '|' . mb_strtolower($credentials['email']);
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $detik = RateLimiter::availableIn($key);

            return back()->withErrors([
                'email' => "Terlalu banyak percobaan masuk. Coba lagi dalam {$detik} detik.",
            ])->onlyInput('email');
        }

        if (Auth::attempt($credentials + ['is_active' => true], $request->boolean('remember'))) {
            RateLimiter::clear($key);
            $request->session()->regenerate();
            return redirect()->intended(route('dashboard'));
        }

        RateLimiter::hit($key, 60);

        return back()->withErrors([
            'email' => 'Email atau password yang Anda masukkan salah.',
        ])->onlyInput('email');
    }

    public function showChangePassword()
    {
        return view('auth.ganti-sandi');
    }

    public function changePassword(Request $request)
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'new_password' => ['required', 'string', 'confirmed', 'different:current_password', Password::min(10)->letters()->mixedCase()->numbers()],
        ], [], ['current_password' => 'sandi saat ini', 'new_password' => 'sandi baru']);

        $user = $request->user();
        if (!Hash::check($data['current_password'], $user->password)) {
            return back()->withErrors(['current_password' => 'Sandi saat ini salah.']);
        }

        $user->forceFill(['password' => $data['new_password'], 'must_change_password' => false])->save();
        $request->session()->regenerate();

        return redirect()->route('dashboard')->with('success', 'Sandi berhasil diganti.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }
}

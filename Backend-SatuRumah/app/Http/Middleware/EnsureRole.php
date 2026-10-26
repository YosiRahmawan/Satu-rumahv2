<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Membatasi route menurut role akun: `role:verifikator,administrator`.
 * Permintaan API mendapat galat JSON; permintaan web dialihkan ke login.
 */
class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if ($user && in_array($user->role, $roles, true)) {
            return $next($request);
        }

        if ($request->is('api/*') || $request->expectsJson()) {
            return response()->json([
                'error' => ['code' => 'ERR-022', 'message' => 'Akun ini tidak berhak mengakses sumber daya tersebut.'],
            ], 403);
        }

        auth()->logout();
        $request->session()->invalidate();

        return redirect()->route('login')->withErrors([
            'email' => 'Akun ini tidak memiliki akses ke Web Admin.',
        ]);
    }
}

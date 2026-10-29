<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Akun dengan kata sandi sementara harus menggantinya sebelum memakai API lain. */
class EnsurePasswordChanged
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user()?->must_change_password) {
            if (!$request->is('api/*') && !$request->expectsJson()) {
                return redirect()->route('sandi.ubah')->with('warning', 'Ganti sandi sementara Anda terlebih dahulu.');
            }

            return response()->json([
                'error' => ['code' => 'ERR-022', 'message' => 'Ganti kata sandi sementara Anda terlebih dahulu.'],
            ], 403);
        }

        return $next($request);
    }
}

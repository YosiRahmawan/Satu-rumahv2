<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

/**
 * Menjalankan pengingat tenggat dan SLA sendiri, sekali per jam, saat server menerima permintaan apa pun
 * (portal Admin, aplikasi HP). Tanpa ini pengingat butuh proses terpisah (`schedule:work` atau cron) yang
 * mudah terlupa. Perintahnya sudah mengirim tiap pengingat hanya sekali, jadi aman bila penjadwal sistem
 * ikut berjalan.
 */
class JalankanPengingatOtomatis
{
    public function handle(Request $request, Closure $next): Response
    {
        return $next($request);
    }

    /** Dijalankan setelah respons dikirim, jadi tidak memperlambat permintaan pengguna. */
    public function terminate(Request $request, Response $response): void
    {
        if (!config('satu_rumah.pengingat_otomatis') || $request->is('up')) {
            return;
        }
        // Cache::add atomik: hanya satu permintaan per jam yang mendapat giliran.
        if (!Cache::add('pengingat-otomatis', now()->toIso8601String(), now()->addHour())) {
            return;
        }
        try {
            Artisan::call('pengajuan:ingatkan-tenggat');
        } catch (\Throwable $e) {
            report($e);
        }
    }
}

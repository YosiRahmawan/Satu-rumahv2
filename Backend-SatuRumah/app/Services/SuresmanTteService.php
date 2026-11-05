<?php

namespace App\Services;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

/**
 * Mengambil gambar visualisasi TTE penanda tangan dari Suresman (Kota Tasikmalaya) berdasarkan NIP.
 * NIP selalu dari akun yang sedang masuk, bukan dari masukan bebas, sehingga tidak bisa dipakai
 * mengambil TTE milik orang lain. Hasil disimpan di disk privat agar Suresman tidak dibebani.
 */
class SuresmanTteService
{
    public function __construct(
        private readonly string $baseUrl = '',
        private readonly bool $verify = true,
        private readonly int $timeout = 15,
    ) {
    }

    public static function fromConfig(): self
    {
        return new self(
            rtrim((string) config('services.suresman.base_url'), '/'),
            (bool) config('services.suresman.verify'),
            (int) config('services.suresman.timeout'),
        );
    }

    /** @return string|null Isi gambar PNG, atau null bila pegawai tidak ditemukan atau Suresman tidak dapat dijangkau. */
    public function fetch(string $nip): ?string
    {
        $nip = preg_replace('/\D/', '', $nip) ?? '';
        if (strlen($nip) < 9) {
            return null;
        }

        $cache = "tte-cache/{$nip}.png";
        if (Storage::disk('local')->exists($cache)) {
            return Storage::disk('local')->get($cache);
        }

        try {
            $http = fn (): PendingRequest => Http::withOptions(['verify' => $this->verify])
                ->withHeaders(['User-Agent' => 'SatuRumah/2.0', 'Referer' => $this->baseUrl])
                ->timeout($this->timeout);
            // Cookie sesi dipakai bersama tiga langkah: buka halaman, cari NIP, unduh.
            $jar = new \GuzzleHttp\Cookie\CookieJar();

            $http()->withOptions(['cookies' => $jar])->get($this->baseUrl);
            $html = $http()->withOptions(['cookies' => $jar])->asForm()->post("{$this->baseUrl}/search", ['nip' => $nip])->body();

            $field = function (string $name) use ($html): string {
                return preg_match('/name="' . $name . '"\s+value="([^"]*)"/i', $html, $m) ? html_entity_decode($m[1]) : '';
            };
            if ($field('name') === '' && $field('position') === '') {
                Log::warning('Suresman: pegawai tidak ditemukan.', ['nip' => substr($nip, 0, 4) . '…']);

                return null;
            }

            $res = $http()->withOptions(['cookies' => $jar])->asForm()->post("{$this->baseUrl}/download", [
                'nip' => $nip, 'name' => $field('name'), 'position' => $field('position'),
                'category' => $field('category'), 'rank_text' => $field('rank_text'),
            ]);
            if (!str_contains((string) $res->header('Content-Type'), 'image') || $res->body() === '') {
                Log::warning('Suresman: respons unduh bukan gambar.');

                return null;
            }

            Storage::disk('local')->put($cache, $res->body());

            return $res->body();
        } catch (\Throwable $e) {
            Log::warning('Suresman tidak dapat dijangkau: ' . $e->getMessage());

            return null;
        }
    }
}

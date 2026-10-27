<?php

namespace App\Services;

/**
 * Memeriksa tanda geotag yang ditanam aplikasi Flutter di dalam JPEG
 * (lib/features/monitoring/utils/geo_stamp_signer.dart). Algoritmanya harus
 * identik: segmen COM berawalan "SATURUMAH-GEO1:" berisi `payload.tanda`,
 * tanda = HMAC-SHA256("payload.sha256(JPEG tanpa segmen itu)").
 *
 * Batasan yang jujur: kuncinya ada di dalam aplikasi, jadi ini mendeteksi foto
 * yang diubah, bukan membuktikan keaslian terhadap pihak yang membongkar
 * aplikasi. Bukti yang kuat memerlukan penandatanganan di server.
 */
class GeoStampVerifier
{
    public const OK = 'ok';
    public const NOT_JPEG = 'not_jpeg';
    public const MISSING = 'missing';
    public const TAMPERED = 'tampered';

    private const PREFIX = 'SATURUMAH-GEO1:';

    /**
     * @return array{status: string, stamp: array{lat: float, lng: float, acc: ?float, captured_at: \DateTimeImmutable, address: ?string, note: ?string}|null}
     */
    public function verify(string $bytes): array
    {
        if (!$this->isJpeg($bytes)) {
            return ['status' => self::NOT_JPEG, 'stamp' => null];
        }

        [$clean, $comment] = $this->strip($bytes);
        if ($comment === null) {
            return ['status' => self::MISSING, 'stamp' => null];
        }

        $dot = strrpos($comment, '.');
        if ($dot === false) {
            return ['status' => self::TAMPERED, 'stamp' => null];
        }

        $payload = substr($comment, 0, $dot);
        $signature = substr($comment, $dot + 1);
        if (!hash_equals($this->sign($payload, $clean), $signature)) {
            return ['status' => self::TAMPERED, 'stamp' => null];
        }

        $stamp = $this->decode($payload);

        return $stamp
            ? ['status' => self::OK, 'stamp' => $stamp]
            : ['status' => self::TAMPERED, 'stamp' => null];
    }

    private function sign(string $payload, string $cleanJpeg): string
    {
        $key = (string) config('satu_rumah.photo_stamp_key');

        return hash_hmac('sha256', $payload . '.' . hash('sha256', $cleanJpeg), $key);
    }

    /** @return array<string, mixed>|null */
    private function decode(string $payload): ?array
    {
        $b64 = strtr($payload, '-_', '+/');
        $b64 .= str_repeat('=', (4 - strlen($b64) % 4) % 4);
        $json = base64_decode($b64, true);
        $data = $json === false ? null : json_decode($json, true);

        if (!is_array($data) || !is_numeric($data['lat'] ?? null) || !is_numeric($data['lng'] ?? null)) {
            return null;
        }
        $lat = (float) $data['lat'];
        $lng = (float) $data['lng'];
        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            return null;
        }
        try {
            $at = new \DateTimeImmutable((string) ($data['t'] ?? ''));
        } catch (\Throwable) {
            return null;
        }

        return [
            'lat' => $lat,
            'lng' => $lng,
            'acc' => is_numeric($data['acc'] ?? null) ? (float) $data['acc'] : null,
            'captured_at' => $at,
            'address' => is_string($data['addr'] ?? null) ? $data['addr'] : null,
            'note' => is_string($data['note'] ?? null) ? $data['note'] : null,
        ];
    }

    private function isJpeg(string $b): bool
    {
        return strlen($b) > 4 && $b[0] === "\xFF" && $b[1] === "\xD8" && $b[2] === "\xFF";
    }

    /** @return array{0: string, 1: ?string} [JPEG tanpa segmen tanda, isi komentar] */
    private function strip(string $jpeg): array
    {
        $len = strlen($jpeg);
        $i = 2;
        while ($i + 4 <= $len) {
            if ($jpeg[$i] !== "\xFF") {
                break;
            }
            $marker = ord($jpeg[$i + 1]);
            if ($marker === 0xFF) {
                $i++;
                continue;
            }
            if ($marker === 0x01 || ($marker >= 0xD0 && $marker <= 0xD7)) {
                $i += 2;
                continue;
            }
            if ($marker === 0xDA || $marker === 0xD9) {
                break;
            }
            $segment = (ord($jpeg[$i + 2]) << 8) | ord($jpeg[$i + 3]);
            if ($segment < 2 || $i + 2 + $segment > $len) {
                break;
            }
            if ($marker === 0xFE) {
                $text = substr($jpeg, $i + 4, $segment - 2);
                if (str_starts_with($text, self::PREFIX)) {
                    return [substr($jpeg, 0, $i) . substr($jpeg, $i + 2 + $segment), substr($text, strlen(self::PREFIX))];
                }
            }
            $i += 2 + $segment;
        }

        return [$jpeg, null];
    }
}

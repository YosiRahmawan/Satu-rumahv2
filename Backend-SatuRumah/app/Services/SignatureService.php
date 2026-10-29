<?php

namespace App\Services;

use App\Models\InspectionReport;
use App\Models\ReportSignature;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

/**
 * Persetujuan elektronik BA (Ketua Pengawas lalu Admin). Gambar tanda tangan hanya penanda visual di PDF;
 * keabsahannya bertumpu pada akun yang masuk, konfirmasi sandi, dan hash isi BA yang dicatat server.
 * Ini BUKAN tanda tangan elektronik tersertifikasi (TTE).
 */
class SignatureService
{
    public const DISK = 'local';
    public const MAX_BYTES = 2 * 1024 * 1024;

    public function __construct(private readonly Notifier $notifier)
    {
    }

    /** Sidik isi BA: isian, tim, versi, dan checksum foto. Berubah bila isi berubah. */
    public function documentHash(InspectionReport $r): string
    {
        $r->loadMissing('photos');
        $payload = [
            'nomor' => $r->report_number,
            'pengajuan' => $r->submission_id,
            'penugasan' => $r->assignment_id,
            'versi' => (int) $r->version,
            'tanggal' => $r->monitoring_date?->toDateString(),
            'nama_perumahan' => $r->nama_perumahan,
            'lokasi' => $r->lokasi,
            'maksud_tujuan' => $r->maksud_tujuan,
            'temuan' => $r->temuan ?? [],
            'kesimpulan' => $r->kesimpulan ?? [],
            'kesepakatan' => $r->kesepakatan ?? [],
            'rtl' => $r->rtl ?? [],
            'hasil' => $r->status_hasil_evaluasi,
            'tim' => $r->tim_pelaksana ?? [],
            'ditemui' => $r->pihak_ditemui ?? [],
            'foto' => $r->photos->pluck('checksum')->all(),
        ];

        return hash('sha256', json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
    }

    /** Persetujuan terbaru satu pihak yang masih cocok dengan isi BA sekarang; null bila belum atau sudah kedaluwarsa. */
    public function validSignature(InspectionReport $r, string $role): ?ReportSignature
    {
        $sig = ReportSignature::where('report_id', $r->id)->where('role', $role)->orderByDesc('report_version')->first();

        return $sig && $sig->report_version === (int) $r->version && hash_equals($sig->document_hash, $this->documentHash($r)) ? $sig : null;
    }

    /** @return array<string, mixed> Status untuk API/web (tanpa gambar atau hash). */
    public function status(InspectionReport $r): array
    {
        $one = function (string $role) use ($r) {
            $sig = $this->validSignature($r, $role);

            return ['signed' => (bool) $sig, 'signed_at' => $sig?->signed_at?->toIso8601String(), 'method' => $sig?->method, 'signer' => $sig?->signer?->name];
        };

        $ketua = $one(ReportSignature::KETUA);
        $admin = $one(ReportSignature::ADMIN);

        return [
            'ketua' => $ketua, 'admin' => $admin,
            'provider' => 'gambar', // persetujuan elektronik berbasis akun; bukan TTE tersertifikasi
            'ready_to_publish' => $ketua['signed'] && $admin['signed'],
        ];
    }

    /** Menyatukan gambar dari berkas unggahan (`signature`) atau data URL kanvas (`signature_data`). */
    public function bytesFrom(Request $request): string
    {
        if ($request->hasFile('signature')) {
            $file = $request->file('signature');
            if (!$file->isValid() || $file->getSize() > self::MAX_BYTES) {
                throw ValidationException::withMessages(['signature' => ['Berkas tanda tangan tidak valid atau lebih dari 2 MB.']]);
            }

            return (string) file_get_contents($file->getRealPath());
        }

        $data = (string) $request->input('signature_data', '');
        if (!preg_match('#^data:image/(png|jpeg);base64,([A-Za-z0-9+/=\\s]+)$#', $data, $m)) {
            throw ValidationException::withMessages(['signature' => ['Tanda tangan wajib berupa gambar PNG atau JPEG.']]);
        }
        $bytes = base64_decode($m[2], true);
        if ($bytes === false || strlen($bytes) > self::MAX_BYTES) {
            throw ValidationException::withMessages(['signature' => ['Gambar tanda tangan rusak atau lebih dari 2 MB.']]);
        }

        return $bytes;
    }

    /**
     * Validasi isi gambar lalu normalkan: hanya PNG/JPEG asli, 80..4000 px, dienkode ulang menjadi PNG
     * (metadata dan muatan tersembunyi hilang), diperkecil maks 600x250, putih menjadi transparan.
     */
    public function normalize(string $bytes): string
    {
        $info = strlen($bytes) > 0 ? @getimagesizefromstring($bytes) : false;
        if (!$info || !in_array($info[2], [IMAGETYPE_PNG, IMAGETYPE_JPEG], true)) {
            throw ValidationException::withMessages(['signature' => ['Tanda tangan harus berupa gambar PNG atau JPEG yang valid.']]);
        }
        [$w, $h] = $info;
        if ($w < 80 || $h < 40 || $w > 4000 || $h > 4000) {
            throw ValidationException::withMessages(['signature' => ['Ukuran gambar harus antara 80x40 dan 4000x4000 piksel.']]);
        }

        $src = @imagecreatefromstring($bytes);
        if (!$src) {
            throw ValidationException::withMessages(['signature' => ['Gambar tanda tangan rusak.']]);
        }

        $scale = min(1, 600 / $w, 250 / $h);
        $nw = max(1, (int) round($w * $scale));
        $nh = max(1, (int) round($h * $scale));
        $dst = imagecreatetruecolor($nw, $nh);
        imagealphablending($dst, false);
        imagesavealpha($dst, true);
        imagefill($dst, 0, 0, imagecolorallocatealpha($dst, 0, 0, 0, 127));
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        imagedestroy($src);

        $tinta = 0;
        for ($y = 0; $y < $nh; $y++) {
            for ($x = 0; $x < $nw; $x++) {
                $c = imagecolorat($dst, $x, $y);
                $a = ($c >> 24) & 0x7F;
                $r = ($c >> 16) & 0xFF; $g = ($c >> 8) & 0xFF; $b = $c & 0xFF;
                if ($a < 127 && $r >= 235 && $g >= 235 && $b >= 235) {
                    imagesetpixel($dst, $x, $y, imagecolorallocatealpha($dst, 0, 0, 0, 127));
                } elseif ($a < 100) {
                    $tinta++;
                }
            }
        }
        if ($tinta < max(20, (int) ($nw * $nh * 0.001))) {
            imagedestroy($dst);
            throw ValidationException::withMessages(['signature' => ['Tanda tangan kosong. Gambar tanda tangan Anda terlebih dahulu.']]);
        }

        ob_start();
        imagepng($dst);
        $png = (string) ob_get_clean();
        imagedestroy($dst);

        return $png;
    }

    /**
     * Menandatangani satu versi BA. Idempoten: pengulangan untuk laporan, peran, dan versi yang sama
     * mengembalikan persetujuan yang sudah ada. Isian peran, waktu, dan hash selalu dari server.
     */
    public function sign(InspectionReport $r, User $user, string $role, string $method, string $imageBytes, string $password, int $version, ?string $ip = null): ReportSignature
    {
        if (!in_array($method, ['draw', 'upload'], true)) {
            throw ValidationException::withMessages(['method' => ['Metode harus draw atau upload.']]);
        }
        $this->authorize($r, $user, $role);
        if (!Hash::check($password, $user->password)) {
            throw ValidationException::withMessages(['password' => ['Sandi salah.']]);
        }
        if ($r->status !== 'final') {
            throw new \DomainException('BA harus sudah dikirim sebelum ditandatangani.');
        }
        if ($r->published_at) {
            throw new \DomainException('BA sudah diterbitkan.');
        }
        if ($version !== (int) $r->version) {
            throw new \DomainException('Isi BA telah berubah. Muat ulang BA lalu periksa kembali sebelum menandatangani.');
        }

        $png = $this->normalize($imageBytes);

        return DB::transaction(function () use ($r, $user, $role, $method, $png, $version, $ip) {
            $r = InspectionReport::lockForUpdate()->findOrFail($r->id);
            if ((int) $r->version !== $version) {
                throw new \DomainException('Isi BA telah berubah. Muat ulang BA lalu periksa kembali sebelum menandatangani.');
            }

            $existing = ReportSignature::where('report_id', $r->id)->where('role', $role)->where('report_version', $version)->first();
            if ($existing) {
                return $existing;
            }
            if ($role === ReportSignature::ADMIN && !$this->validSignature($r, ReportSignature::KETUA)) {
                throw new \DomainException('Ketua Pengawas harus menandatangani lebih dulu.');
            }

            $path = "reports/{$r->id}/signatures/{$role}-v{$version}.png";
            Storage::disk(self::DISK)->put($path, $png);

            $sig = ReportSignature::create([
                'report_id' => $r->id, 'role' => $role, 'user_id' => $user->id, 'method' => $method,
                'signature_path' => $path, 'document_hash' => $this->documentHash($r), 'report_version' => $version,
                'signed_at' => now(), 'provider' => 'gambar', 'ip' => $ip,
            ]);

            if ($r->submission) {
                $label = $role === ReportSignature::KETUA ? 'Ketua Pengawas' : 'Admin';
                $this->notifier->event($r->submission, $user, "report_signed_{$role}", "BA ditandatangani {$label}", "BA {$r->report_number} versi {$version}.", ['report_id' => $r->id, 'method' => $method]);
                if ($role === ReportSignature::KETUA) {
                    $this->notifier->toVerifiers($r->submission, 'report_signed_ketua', 'BA ditandatangani Ketua', "{$r->report_number} · {$r->nama_perumahan}", ['report_id' => $r->id]);
                }
            }

            return $sig;
        });
    }

    private function authorize(InspectionReport $r, User $user, string $role): void
    {
        $ok = match ($role) {
            // Ketua = petugas utama pemilik laporan (ditetapkan Admin saat penjadwalan).
            ReportSignature::KETUA => $user->role === 'tim_lapangan' && $r->officer_id === $user->id,
            ReportSignature::ADMIN => $user->role === 'admin' && $user->is_active,
            default => false,
        };
        if (!$ok) {
            throw new AuthorizationException('Akun ini tidak berwenang menandatangani BA sebagai ' . $role . '.');
        }
    }
}

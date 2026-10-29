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
 * Tanda tangan BA oleh Ketua Pengawas lalu Admin. Keduanya mengunggah visualisasi TTE dari Suresman
 * (suresman.tasikmalayakota.go.id/visualcustom, dibuat dari NIP masing-masing); gambar itu ditempel di PDF
 * final. Server memastikan akun berwenang dan ber-NIP, konfirmasi sandi, dan mengunci isi BA dengan hash.
 * Keputusan Disperwaskim (29 Okt 2026): PDF dengan visualisasi TTE ini sah, tanpa penandatanganan ulang BSrE.
 */
class SignatureService
{
    public const DISK = 'local';
    public const MAX_BYTES = 4 * 1024 * 1024;

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

            return ['signed' => (bool) $sig, 'signed_at' => $sig?->signed_at?->toIso8601String(), 'signer' => $sig?->signer?->name];
        };

        $ketua = $one(ReportSignature::KETUA);
        $admin = $one(ReportSignature::ADMIN);

        return [
            'ketua' => $ketua, 'admin' => $admin,
            'provider' => 'visualisasi_tte', // unggahan visualisasi TTE Suresman; titik sambung bila API penyedia tersedia
            'ready_to_publish' => $ketua['signed'] && $admin['signed'],
        ];
    }

    /** Berkas visualisasi TTE yang diunggah (`signature`); maksimal 4 MB. */
    public function bytesFrom(Request $request): string
    {
        $file = $request->file('signature');
        if (!$file || !$file->isValid() || $file->getSize() > self::MAX_BYTES) {
            throw ValidationException::withMessages(['signature' => ['Pilih gambar visualisasi TTE (PNG atau JPEG, maksimal 4 MB).']]);
        }

        return (string) file_get_contents($file->getRealPath());
    }

    /**
     * Validasi isi gambar lalu normalkan: hanya PNG/JPEG asli, 40x20 sampai 5000x5000 piksel, dienkode ulang
     * menjadi PNG (metadata dan muatan tersembunyi hilang). Isi dipertahankan apa adanya (warna dan latar tidak
     * diubah) agar QR visualisasi tetap terbaca; hanya diperkecil bila melebihi 1600x1000. PDF menyesuaikan ukuran tampil.
     */
    public function normalize(string $bytes): string
    {
        $info = strlen($bytes) > 0 ? @getimagesizefromstring($bytes) : false;
        if (!$info || !in_array($info[2], [IMAGETYPE_PNG, IMAGETYPE_JPEG], true)) {
            throw ValidationException::withMessages(['signature' => ['Tanda tangan harus berupa gambar PNG atau JPEG yang valid.']]);
        }
        [$w, $h] = $info;
        if ($w < 40 || $h < 20 || $w > 5000 || $h > 5000) {
            throw ValidationException::withMessages(['signature' => ['Ukuran gambar harus antara 40x20 dan 5000x5000 piksel.']]);
        }

        $src = @imagecreatefromstring($bytes);
        if (!$src) {
            throw ValidationException::withMessages(['signature' => ['Gambar tanda tangan rusak.']]);
        }

        $scale = min(1, 1600 / $w, 1000 / $h);
        $nw = max(1, (int) round($w * $scale));
        $nh = max(1, (int) round($h * $scale));
        $dst = imagecreatetruecolor($nw, $nh);
        imagealphablending($dst, false);
        imagesavealpha($dst, true);
        imagefill($dst, 0, 0, imagecolorallocatealpha($dst, 0, 0, 0, 127));
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        imagedestroy($src);

        // Tolak gambar polos (semua piksel sama).
        $dasar = imagecolorat($dst, 0, 0);
        $beda = 0;
        for ($y = 0; $y < $nh && $beda < 20; $y++) {
            for ($x = 0; $x < $nw && $beda < 20; $x++) {
                if (imagecolorat($dst, $x, $y) !== $dasar) {
                    $beda++;
                }
            }
        }
        if ($beda < 20) {
            imagedestroy($dst);
            throw ValidationException::withMessages(['signature' => ['Gambar kosong atau polos. Pilih gambar visualisasi TTE yang benar.']]);
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
    public function sign(InspectionReport $r, User $user, string $role, string $imageBytes, string $password, int $version, ?string $ip = null): ReportSignature
    {
        $this->authorize($r, $user, $role);
        if (blank($user->nip)) {
            // Visualisasi TTE dibuat dari NIP; akun penanda tangan harus memilikinya.
            throw ValidationException::withMessages(['nip' => [$role === ReportSignature::ADMIN
                ? 'Lengkapi NIP akun Anda di menu Akun (Ubah) sebelum menandatangani.'
                : 'NIP akun Anda belum diisi. Minta admin melengkapinya di menu Akun.']]);
        }
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

        return DB::transaction(function () use ($r, $user, $role, $png, $version, $ip) {
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
                'report_id' => $r->id, 'role' => $role, 'user_id' => $user->id, 'method' => 'upload',
                'signature_path' => $path, 'document_hash' => $this->documentHash($r), 'report_version' => $version,
                'signed_at' => now(), 'provider' => 'visualisasi_tte', 'ip' => $ip,
            ]);

            if ($r->submission) {
                $label = $role === ReportSignature::KETUA ? 'Ketua Pengawas' : 'Admin';
                $this->notifier->event($r->submission, $user, "report_signed_{$role}", "BA ditandatangani {$label}", "BA {$r->report_number} versi {$version}.", ['report_id' => $r->id]);
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

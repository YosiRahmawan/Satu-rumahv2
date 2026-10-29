<?php

namespace App\Services;

use App\Models\InspectionReport;
use App\Models\ReportSignature;
use chillerlan\QRCode\Output\QRGdImagePNG;
use chillerlan\QRCode\QRCode;
use chillerlan\QRCode\QROptions;
use Dompdf\Dompdf;
use Dompdf\Options;
use Illuminate\Support\Facades\Storage;

/**
 * PDF BA final dibuat server dari data BA, memuat gambar tanda tangan Ketua dan Admin serta QR verifikasi.
 * Template masih SEMENTARA (config satu_rumah.ba_template_resmi = false) sampai Disperwaskim menyetujui format resmi.
 */
class BaPdfService
{
    public function __construct(private readonly SignatureService $signatures)
    {
    }

    public static function resmi(): bool
    {
        return (bool) config('satu_rumah.ba_template_resmi', false);
    }

    public function verificationUrl(InspectionReport $r): string
    {
        return route('verifikasi', ['token' => $r->verification_token]);
    }

    /** Membuat PDF, menyimpannya di penyimpanan privat, dan mencatat path serta hash PDF. */
    public function generate(InspectionReport $r): string
    {
        if (blank($r->verification_token)) { // BA lama tanpa token (dikirim sebelum QR ada)
            $r->forceFill(['verification_token' => bin2hex(random_bytes(24))])->save();
        }
        $r->loadMissing('photos', 'officer', 'submission');
        $ketua = $this->signatures->validSignature($r, ReportSignature::KETUA);
        $admin = $this->signatures->validSignature($r, ReportSignature::ADMIN);
        $disk = Storage::disk(SignatureService::DISK);

        $html = view('ba.pdf', [
            'r' => $r,
            'resmi' => self::resmi(),
            'qr' => $this->qr($this->verificationUrl($r)),
            'verifyUrl' => $this->verificationUrl($r),
            'ketua' => $ketua ? ['sig' => $ketua] + $this->tandaTangan($disk->get($ketua->signature_path)) : null,
            'admin' => $admin ? ['sig' => $admin] + $this->tandaTangan($disk->get($admin->signature_path)) : null,
            'foto' => $r->photos->map(fn ($p) => ['posisi' => $p->position, 'catatan' => $p->note, 'uri' => $this->fotoUri($p->storage_path)])->all(),
            'hash' => $this->signatures->documentHash($r),
        ])->render();

        $options = new Options();
        $options->set('isRemoteEnabled', false);
        $options->set('defaultFont', 'DejaVu Sans');
        $dompdf = new Dompdf($options);
        $dompdf->setPaper('A4');
        $dompdf->loadHtml($html, 'UTF-8');
        $dompdf->render();
        $pdf = $dompdf->output();

        $path = "reports/{$r->id}/ba-final.pdf";
        $disk->put($path, $pdf);
        $r->forceFill(['pdf_path' => $path, 'pdf_hash' => hash('sha256', $pdf)])->save();

        return $path;
    }

    /** Gambar tanda tangan sebagai data URI beserta ukuran tampil yang muat di kotak 235x100 titik (rasio terjaga). */
    private function tandaTangan(string $png): array
    {
        [$w, $h] = getimagesizefromstring($png) ?: [235, 100];
        $skala = min(235 / $w, 100 / $h);

        return ['img' => $this->dataUri($png, 'image/png'), 'w' => max(1, (int) round($w * $skala)), 'h' => max(1, (int) round($h * $skala))];
    }

    private function qr(string $url): string
    {
        return (new QRCode(new QROptions([
            'outputInterface' => QRGdImagePNG::class,
            'scale' => 5,
            'quietzoneSize' => 2,
            'outputBase64' => true,
        ])))->render($url);
    }

    private function dataUri(string $bytes, string $mime): string
    {
        return "data:{$mime};base64," . base64_encode($bytes);
    }

    /** Foto lapangan diperkecil agar PDF tidak membengkak; kosong bila berkas hilang. */
    private function fotoUri(string $path): ?string
    {
        $disk = Storage::disk(SignatureService::DISK);
        if (!$disk->exists($path)) {
            return null;
        }
        $src = @imagecreatefromstring($disk->get($path));
        if (!$src) {
            return null;
        }
        $w = imagesx($src);
        $h = imagesy($src);
        $nw = min(360, $w);
        $nh = max(1, (int) round($h * $nw / $w));
        $dst = imagecreatetruecolor($nw, $nh);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        ob_start();
        imagejpeg($dst, null, 70);
        $jpg = (string) ob_get_clean();
        imagedestroy($src);
        imagedestroy($dst);

        return $this->dataUri($jpg, 'image/jpeg');
    }
}

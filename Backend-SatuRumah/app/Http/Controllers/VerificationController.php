<?php

namespace App\Http\Controllers;

use App\Models\InspectionReport;
use App\Models\ReportSignature;
use App\Services\BaPdfService;
use App\Services\SignatureService;

/** Halaman publik tujuan QR pada BA. Hanya status dasar; tanpa nama orang, isi BA, atau berkas. */
class VerificationController extends Controller
{
    public function show(string $token, SignatureService $signatures)
    {
        $r = InspectionReport::where('verification_token', $token)->first();
        if (!$r) {
            return response()->view('ba.verifikasi', ['ditemukan' => false], 404);
        }

        $ketua = $signatures->validSignature($r, ReportSignature::KETUA);
        $admin = $signatures->validSignature($r, ReportSignature::ADMIN);

        return view('ba.verifikasi', [
            'ditemukan' => true,
            'nomor' => $r->report_number,
            'perumahan' => $r->nama_perumahan,
            'terbit' => $r->published_at,
            'ketua' => $ketua?->signed_at,
            'admin' => $admin?->signed_at,
            'resmi' => BaPdfService::resmi(),
        ]);
    }
}

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

/**
 * Membuang tabel demo skema lama (19 Agu 2026). Tidak ada kode yang memakainya sejak
 * Fase D; isinya hanya data contoh. Pembuangan ini tidak dapat dibatalkan (down kosong):
 * bila perlu, jalankan ulang migrasi 2026_08_19_*.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Urutan: anak lebih dulu agar kunci asing tidak menghalangi.
        foreach (['notifikasi', 'riwayat_pengajuan', 'monitoring_pengajuan', 'survey_pengajuan', 'dokumen_pengajuan', 'pengajuan'] as $table) {
            Schema::dropIfExists($table);
        }
    }

    public function down(): void
    {
        // Sengaja kosong.
    }
};

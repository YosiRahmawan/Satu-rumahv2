<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pengajuan', function (Blueprint $table) {
            $table->string('id')->primary(); // e.g. SR-2025-0148
            $table->string('nama_pengembang');
            $table->string('nama_perumahan');
            $table->string('lokasi');
            $table->string('jumlah_unit');
            $table->string('luas_kawasan');
            $table->string('penanggung_jawab');
            $table->string('tahap'); // Dokumen, Verifikasi teknis, Survey, Monitoring, Persetujuan
            $table->string('status'); // Menunggu verifikasi, Perlu perbaikan, Terjadwal, Draft, Final, Siap disetujui
            $table->text('catatan_status')->nullable();
            $table->string('diajukan_pada')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengajuan');
    }
};

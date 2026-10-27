<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dokumen_pengajuan', function (Blueprint $table) {
            $table->id();
            $table->string('pengajuan_id');
            $table->foreign('pengajuan_id')->references('id')->on('pengajuan')->onDelete('cascade');
            $table->enum('kategori', ['perusahaan', 'perumahan', 'paket_teknis']);
            $table->string('nama_persyaratan');
            $table->string('nama_file');
            $table->string('ukuran_file')->nullable();
            $table->string('tanggal_unggah')->nullable();
            $table->enum('status', ['Sesuai', 'Perlu perbaikan', 'Belum diperiksa'])->default('Belum diperiksa');
            $table->text('catatan')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dokumen_pengajuan');
    }
};

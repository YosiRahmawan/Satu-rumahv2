<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('monitoring_pengajuan', function (Blueprint $table) {
            $table->id();
            $table->string('pengajuan_id');
            $table->foreign('pengajuan_id')->references('id')->on('pengajuan')->onDelete('cascade');
            $table->enum('status_monitoring', ['Draft', 'Final'])->default('Draft');
            $table->string('tanggal_survey')->nullable();
            $table->string('petugas_nama')->nullable();
            $table->string('hasil')->nullable(); // Perlu Evaluasi, Disetujui, Perlu Perbaikan
            $table->text('temuan')->nullable();
            $table->text('kesimpulan')->nullable();
            $table->text('kesepakatan')->nullable();
            $table->text('rencana_tindak_lanjut')->nullable();
            $table->json('foto_bukti')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('monitoring_pengajuan');
    }
};

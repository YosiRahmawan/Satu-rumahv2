<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('survey_pengajuan', function (Blueprint $table) {
            $table->id();
            $table->string('pengajuan_id');
            $table->foreign('pengajuan_id')->references('id')->on('pengajuan')->onDelete('cascade');
            $table->string('tanggal_survey');
            $table->string('jam_survey')->default('09.00 WIB');
            $table->string('petugas_nama');
            $table->string('petugas_role')->default('Perwaskim');
            $table->text('instruksi')->nullable();
            $table->enum('status', ['Terjadwal', 'Selesai', 'Dijadwalkan Ulang'])->default('Terjadwal');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('survey_pengajuan');
    }
};

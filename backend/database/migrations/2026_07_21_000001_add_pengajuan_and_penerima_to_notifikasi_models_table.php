<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Menyamakan notifikasi dengan model Flutter: relasi eksplisit ke pengajuan,
 * penerima per role, dan jenis `perluRevisi` (permintaan revisi untuk
 * Pengembang, berbeda dari kabar unggahan berkas untuk Admin).
 *
 * Migrasi baru, bukan edit migrasi lama, supaya database yang sudah
 * menjalankan migrasi sebelumnya tetap aman.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifikasi_models', function (Blueprint $table) {
            $table->string('pengajuan_id')->nullable()->after('user_id');
            $table->foreign('pengajuan_id')
                ->references('id')->on('pengajuans')
                ->nullOnDelete();

            // Null = penerima belum jelas (data lama); jangan dianggap milik siapa pun.
            $table->enum('penerima_role', ['pengembang', 'admin', 'perwaskim'])
                ->nullable()
                ->after('pengajuan_id');

            $table->enum('jenis', [
                'pengajuanBaru',
                'dokumenDiunggahUlang',
                'reminderSurvey',
                'deadlineVerifikasi',
                'perluRevisi',
            ])->change();
        });
    }

    public function down(): void
    {
        Schema::table('notifikasi_models', function (Blueprint $table) {
            $table->dropForeign(['pengajuan_id']);
            $table->dropColumn(['pengajuan_id', 'penerima_role']);

            $table->enum('jenis', [
                'pengajuanBaru',
                'dokumenDiunggahUlang',
                'reminderSurvey',
                'deadlineVerifikasi',
            ])->change();
        });
    }
};

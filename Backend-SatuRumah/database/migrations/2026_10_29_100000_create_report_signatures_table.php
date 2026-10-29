<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Persetujuan elektronik BA oleh Ketua Pengawas dan Admin.
 * `provider`/`provider_ref` disiapkan agar penyedia TTE tersertifikasi (mis. BSrE) dapat dipasang
 * tanpa mengubah tabel; nilai `gambar` berarti coretan atau unggahan gambar, bukan TTE tersertifikasi.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_signatures', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained('inspection_reports')->cascadeOnDelete();
            $table->string('role', 10); // ketua | admin
            $table->foreignId('user_id')->constrained('users');
            $table->string('method', 10); // draw | upload
            $table->string('signature_path');
            $table->char('document_hash', 64);
            $table->unsignedInteger('report_version');
            $table->timestamp('signed_at');
            $table->string('provider', 30)->default('gambar');
            $table->string('provider_ref')->nullable();
            $table->string('ip', 45)->nullable();
            $table->timestamps();

            $table->unique(['report_id', 'role', 'report_version']);
        });

        Schema::table('inspection_reports', function (Blueprint $table) {
            $table->char('pdf_hash', 64)->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('inspection_reports', function (Blueprint $table) {
            $table->dropColumn('pdf_hash');
        });
        Schema::dropIfExists('report_signatures');
    }
};

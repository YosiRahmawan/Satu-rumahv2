<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Fase C: foto geotag laporan BA, serta kolom laporan yang dibutuhkan
     * Flutter (bagian I "Maksud dan Tujuan", hasil evaluasi, kunci versi,
     * kunci idempotensi).
     */
    public function up(): void
    {
        Schema::table('inspection_reports', function (Blueprint $table) {
            $table->text('maksud_tujuan')->nullable()->after('lokasi');
            $table->string('status_hasil_evaluasi', 30)->nullable()->after('rtl');
            $table->unsignedInteger('version')->default(1)->after('status');
            $table->string('client_uuid', 36)->nullable()->after('report_number');
            $table->unique(['officer_id', 'client_uuid']);
        });

        Schema::create('inspection_report_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained('inspection_reports')->cascadeOnDelete();
            $table->unsignedTinyInteger('position')->default(1);
            $table->string('stored_name');
            $table->string('storage_path');          // disk privat, tanpa URL publik
            $table->unsignedBigInteger('size_bytes');
            $table->string('checksum', 64);          // sha256 berkas utuh
            $table->decimal('latitude', 10, 7);      // dari tanda tangan di dalam JPEG
            $table->decimal('longitude', 10, 7);
            $table->decimal('accuracy_m', 8, 2)->nullable();
            $table->timestamp('captured_at');
            $table->text('address')->nullable();
            $table->string('note', 255)->nullable();
            $table->string('source', 10)->default('camera');
            $table->timestamps();

            $table->unique(['report_id', 'checksum']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspection_report_photos');

        Schema::table('inspection_reports', function (Blueprint $table) {
            $table->dropUnique(['officer_id', 'client_uuid']);
            $table->dropColumn(['maksud_tujuan', 'status_hasil_evaluasi', 'version', 'client_uuid']);
        });
    }
};

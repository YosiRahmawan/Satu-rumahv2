<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Kecamatan proyek dipilih pengembang (bukan lagi ditebak dari teks alamat) untuk sebaran di dashboard. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('submissions', function (Blueprint $table) {
            $table->string('kecamatan', 40)->nullable()->after('alamat_proyek');
        });
    }

    public function down(): void
    {
        Schema::table('submissions', function (Blueprint $table) {
            $table->dropColumn('kecamatan');
        });
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Data proyek per pengajuan. Satu pengembang dapat mengajukan beberapa
     * perumahan, jadi nama/alamat perumahan dan jenis pengajuan tidak cukup
     * disimpan di developer_profiles (yang menjadi nilai bawaan saja).
     */
    public function up(): void
    {
        Schema::table('submissions', function (Blueprint $table) {
            $table->string('nama_perumahan', 150)->nullable()->after('developer_id');
            $table->text('alamat_proyek')->nullable()->after('nama_perumahan');
            $table->string('tipe_pengajuan', 40)->nullable()->after('alamat_proyek');
            $table->string('daya_listrik', 20)->nullable()->after('tipe_perumahan');
        });
    }

    public function down(): void
    {
        Schema::table('submissions', function (Blueprint $table) {
            $table->dropColumn(['nama_perumahan', 'alamat_proyek', 'tipe_pengajuan', 'daya_listrik']);
        });
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * client_uuid: kunci idempotensi dari Flutter (header Idempotency-Key) agar
     * pembuatan draf yang diulang karena jaringan putus tidak menggandakan data.
     */
    public function up(): void
    {
        Schema::table('submissions', function (Blueprint $table) {
            $table->string('client_uuid', 36)->nullable()->after('number');
            $table->unique(['developer_id', 'client_uuid']);
        });
    }

    public function down(): void
    {
        Schema::table('submissions', function (Blueprint $table) {
            $table->dropUnique(['developer_id', 'client_uuid']);
            $table->dropColumn('client_uuid');
        });
    }
};

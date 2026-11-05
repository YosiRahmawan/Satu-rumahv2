<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Admin dapat mengembalikan BA ke petugas dengan alasan; BA itu diganti BA baru dari tugas yang sama. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('inspection_reports', function (Blueprint $table) {
            $table->text('revision_note')->nullable();
            $table->timestamp('revision_requested_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('inspection_reports', function (Blueprint $table) {
            $table->dropColumn(['revision_note', 'revision_requested_at']);
        });
    }
};

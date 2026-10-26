<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Anggota tim pelaksana selain petugas utama; dipilih Admin saat menjadwalkan survei. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inspection_assignment_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('assignment_id')->constrained('inspection_assignments')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users');
            $table->unique(['assignment_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspection_assignment_members');
    }
};

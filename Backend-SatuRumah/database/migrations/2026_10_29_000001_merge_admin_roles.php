<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/** Role verifikator dan administrator digabung menjadi satu role: admin. Email dan sandi tidak berubah. */
return new class extends Migration
{
    public function up(): void
    {
        DB::table('users')->whereIn('role', ['verifikator', 'administrator'])->update(['role' => 'admin']);
    }

    public function down(): void
    {
        DB::table('users')->where('role', 'admin')->update(['role' => 'verifikator']);
    }
};

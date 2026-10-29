<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Pengingat tenggat berjalan tiap pagi; butuh `php artisan schedule:work` (lokal) atau penjadwal sistem (produksi).
Schedule::command('pengajuan:ingatkan-tenggat')->dailyAt('08:00');

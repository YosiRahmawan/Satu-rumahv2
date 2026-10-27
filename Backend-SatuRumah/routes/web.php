<?php

use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\NotificationController;
use App\Http\Controllers\Admin\SubmissionController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Web Admin: hanya verifikator dan administrator.
Route::middleware(['auth', 'role:verifikator,administrator'])->group(function () {
    Route::get('/', [DashboardController::class, 'index']);
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard/ringkasan', [DashboardController::class, 'ringkasan'])->name('dashboard.ringkasan');
    Route::get('/dashboard/export', [DashboardController::class, 'exportCsv'])->name('dashboard.export');

    Route::get('/pengajuan', [SubmissionController::class, 'index'])->name('pengajuan.index');
    Route::get('/pengajuan/{id}', [SubmissionController::class, 'show'])->name('pengajuan.show');
    Route::get('/pengajuan/{id}/berkas/{fileId}', [SubmissionController::class, 'file'])->name('pengajuan.berkas');
    Route::get('/pengajuan/{id}/berkas/{fileId}/lihat', [SubmissionController::class, 'lihat'])->name('pengajuan.lihat');
    Route::get('/pengajuan/{id}/foto/{photoId}', [SubmissionController::class, 'photo'])->name('pengajuan.foto');
    Route::post('/pengajuan/{id}/berkas/{fileId}/nilai', [SubmissionController::class, 'review'])->name('pengajuan.nilai');
    Route::post('/pengajuan/{id}/perbaikan', [SubmissionController::class, 'requestRevision'])->name('pengajuan.perbaikan');
    Route::post('/pengajuan/{id}/setujui-administrasi', [SubmissionController::class, 'approve'])->name('pengajuan.setujui_administrasi');
    Route::post('/pengajuan/{id}/jadwal', [SubmissionController::class, 'schedule'])->name('pengajuan.jadwal');
    Route::post('/pengajuan/{id}/terima-laporan', [SubmissionController::class, 'acceptReports'])->name('pengajuan.terima_laporan');
    Route::post('/pengajuan/{id}/keputusan', [SubmissionController::class, 'decide'])->name('pengajuan.keputusan');

    Route::get('/notifikasi', [NotificationController::class, 'index'])->name('notifikasi.index');
    Route::post('/notifikasi/read-all', [NotificationController::class, 'readAll'])->name('notifikasi.read_all');
    Route::post('/notifikasi/{id}/read', [NotificationController::class, 'read'])->name('notifikasi.read');
});

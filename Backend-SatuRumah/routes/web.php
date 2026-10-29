<?php

use App\Http\Controllers\Admin\AccountController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\NotificationController;
use App\Http\Controllers\Admin\SettingController;
use App\Http\Controllers\Admin\SubmissionController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\VerificationController;
use Illuminate\Support\Facades\Route;

Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

// Verifikasi publik BA lewat QR: hanya status dasar, tanpa data pribadi atau isi dokumen.
Route::get('/verifikasi/{token}', [VerificationController::class, 'show'])->where('token', '[A-Za-z0-9]{20,64}')->middleware('throttle:60,1')->name('verifikasi');

// Ganti sandi: boleh dibuka walau sandi masih sementara.
Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/ganti-sandi', [AuthController::class, 'showChangePassword'])->name('sandi.ubah');
    Route::post('/ganti-sandi', [AuthController::class, 'changePassword'])->name('sandi.simpan');
});

// Web Admin: hanya role admin, dengan sandi yang sudah bukan sementara.
Route::middleware(['auth', 'role:admin', 'password.changed'])->group(function () {
    Route::get('/', [DashboardController::class, 'index']);
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard/kpi', [DashboardController::class, 'kpi'])->name('dashboard.kpi');
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
    Route::post('/pengajuan/{id}/jadwal/{assignmentId}/batal', [SubmissionController::class, 'cancelAssignment'])->name('pengajuan.batal_jadwal');
    Route::post('/pengajuan/{id}/laporan/{reportId}/terbitkan', [SubmissionController::class, 'publishReport'])->name('pengajuan.terbitkan_ba');
    Route::post('/pengajuan/{id}/laporan/{reportId}/tanda-tangan', [SubmissionController::class, 'signReport'])->name('pengajuan.tanda_tangan_ba')->middleware('throttle:signature');
    Route::get('/pengajuan/{id}/laporan/{reportId}/pdf', [SubmissionController::class, 'reportPdf'])->name('pengajuan.pdf_ba');
    Route::post('/pengajuan/{id}/terima-laporan', [SubmissionController::class, 'acceptReports'])->name('pengajuan.terima_laporan');
    Route::post('/pengajuan/{id}/keputusan', [SubmissionController::class, 'decide'])->name('pengajuan.keputusan');

    Route::get('/akun', [AccountController::class, 'index'])->name('akun.index');
    Route::post('/akun', [AccountController::class, 'store'])->name('akun.store');
    Route::post('/akun/{id}', [AccountController::class, 'update'])->name('akun.update');
    Route::post('/akun/{id}/reset-sandi', [AccountController::class, 'resetPassword'])->name('akun.reset');
    Route::post('/akun/{id}/status', [AccountController::class, 'toggleActive'])->name('akun.status');

    Route::get('/pengaturan', [SettingController::class, 'index'])->name('pengaturan.index');
    Route::post('/pengaturan', [SettingController::class, 'update'])->name('pengaturan.update');

    Route::get('/notifikasi', [NotificationController::class, 'index'])->name('notifikasi.index');
    Route::post('/notifikasi/read-all', [NotificationController::class, 'readAll'])->name('notifikasi.read_all');
    Route::post('/notifikasi/{id}/read', [NotificationController::class, 'read'])->name('notifikasi.read');
});

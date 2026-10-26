<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeveloperProfileController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\Officer\AssignmentController;
use App\Http\Controllers\Api\Officer\ReportController;
use App\Http\Controllers\Api\Officer\ReportPhotoController;
use App\Http\Controllers\Api\SubmissionController;
use App\Http\Controllers\Api\SubmissionFileController;
use Illuminate\Support\Facades\Route;

// Prefiks /api dari framework, jadi alamat akhirnya /api/v1/...
Route::prefix('v1')->group(function () {
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:api-login');

    Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::post('auth/change-password', [AuthController::class, 'changePassword']);

        // Jalur lain wajib kata sandi yang sudah bukan sementara (fase B dan seterusnya).
        Route::middleware('password.changed')->group(function () {
            // Semua role mobile
            Route::get('notifications', [NotificationController::class, 'index']);
            Route::post('notifications/read-all', [NotificationController::class, 'readAll']);
            Route::post('notifications/{id}/read', [NotificationController::class, 'read'])->whereNumber('id');

            // Pengembang
            Route::middleware('role:pengembang')->group(function () {
                Route::get('developer/profile', [DeveloperProfileController::class, 'show']);
                Route::put('developer/profile', [DeveloperProfileController::class, 'update']);

                Route::get('submissions', [SubmissionController::class, 'index']);
                Route::post('submissions', [SubmissionController::class, 'store']);
                Route::get('submissions/{id}', [SubmissionController::class, 'show'])->whereNumber('id');
                Route::patch('submissions/{id}', [SubmissionController::class, 'update'])->whereNumber('id');
                Route::post('submissions/{id}/submit', [SubmissionController::class, 'submit'])->whereNumber('id');
                Route::get('submissions/{id}/timeline', [SubmissionController::class, 'timeline'])->whereNumber('id');
                Route::post('submissions/{id}/resubmit', [SubmissionController::class, 'resubmit'])->whereNumber('id');

                Route::post('submissions/{id}/files', [SubmissionFileController::class, 'store'])->whereNumber('id');
                Route::delete('submissions/{id}/files/{fileId}', [SubmissionFileController::class, 'destroy'])->whereNumber(['id', 'fileId']);
                Route::get('submissions/{id}/files/{fileId}/download', [SubmissionFileController::class, 'download'])->whereNumber(['id', 'fileId']);
            });

            // Pengawas (tim lapangan)
            Route::middleware('role:tim_lapangan')->prefix('officer')->group(function () {
                Route::get('assignments', [AssignmentController::class, 'index']);
                Route::post('assignments/{id}/accept', [AssignmentController::class, 'accept'])->whereNumber('id');

                Route::get('reports', [ReportController::class, 'index']);
                Route::post('reports', [ReportController::class, 'store']);
                Route::get('reports/{id}', [ReportController::class, 'show'])->whereNumber('id');
                Route::put('reports/{id}', [ReportController::class, 'update'])->whereNumber('id');
                Route::post('reports/{id}/submit', [ReportController::class, 'submit'])->whereNumber('id');

                Route::post('reports/{id}/photos', [ReportPhotoController::class, 'store'])->whereNumber('id');
                Route::delete('reports/{id}/photos/{photoId}', [ReportPhotoController::class, 'destroy'])->whereNumber(['id', 'photoId']);
                Route::get('reports/{id}/photos/{photoId}/file', [ReportPhotoController::class, 'file'])->whereNumber(['id', 'photoId']);
            });
        });
    });
});

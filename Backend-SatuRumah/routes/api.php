<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DeveloperProfileController;
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
            // Pengembang
            Route::middleware('role:pengembang')->group(function () {
                Route::get('developer/profile', [DeveloperProfileController::class, 'show']);
                Route::put('developer/profile', [DeveloperProfileController::class, 'update']);

                Route::get('submissions', [SubmissionController::class, 'index']);
                Route::post('submissions', [SubmissionController::class, 'store']);
                Route::get('submissions/{id}', [SubmissionController::class, 'show'])->whereNumber('id');
                Route::patch('submissions/{id}', [SubmissionController::class, 'update'])->whereNumber('id');
                Route::post('submissions/{id}/submit', [SubmissionController::class, 'submit'])->whereNumber('id');
                Route::post('submissions/{id}/resubmit', [SubmissionController::class, 'resubmit'])->whereNumber('id');

                Route::post('submissions/{id}/files', [SubmissionFileController::class, 'store'])->whereNumber('id');
                Route::delete('submissions/{id}/files/{fileId}', [SubmissionFileController::class, 'destroy'])->whereNumber(['id', 'fileId']);
                Route::get('submissions/{id}/files/{fileId}/download', [SubmissionFileController::class, 'download'])->whereNumber(['id', 'fileId']);
            });
        });
    });
});

<?php

use App\Http\Controllers\Api\AuthController;
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
            //
        });
    });
});

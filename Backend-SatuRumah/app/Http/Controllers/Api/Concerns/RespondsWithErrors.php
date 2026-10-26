<?php

namespace App\Http\Controllers\Api\Concerns;

use Illuminate\Http\JsonResponse;

/** Galat API berbentuk {"error": {"code", "message", ...}} (API_SPEC.md bagian 1). */
trait RespondsWithErrors
{
    /** @param array<string, mixed> $extra */
    protected function error(string $code, string $message, int $status, array $extra = []): JsonResponse
    {
        return response()->json(['error' => ['code' => $code, 'message' => $message] + $extra], $status);
    }

    protected function versionConflict(int $current): JsonResponse
    {
        return $this->error(
            'ERR-015',
            'Data sudah berubah di perangkat lain. Muat ulang lalu coba lagi.',
            409,
            ['current_version' => $current]
        );
    }
}

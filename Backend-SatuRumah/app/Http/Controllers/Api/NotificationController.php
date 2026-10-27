<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Notifikasi dalam aplikasi untuk akun yang sedang masuk (aplikasi menariknya; belum ada push). */
class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = AppNotification::where('user_id', $request->user()->id);
        $unread = (clone $query)->whereNull('read_at')->count();

        $items = $query->with('submission:id,number')->when($request->boolean('unread'), fn ($q) => $q->whereNull('read_at'))
            ->latest('id')->limit(min((int) $request->query('limit', 50), 100))->get();

        return response()->json([
            'data' => $items->map(fn (AppNotification $n) => [
                'id' => $n->id,
                'type' => $n->type,
                'title' => $n->title,
                'body' => $n->body,
                'submission_id' => $n->submission_id,
                'submission_number' => $n->submission?->number,
                'data' => $n->data,
                'read' => $n->read_at !== null,
                'created_at' => $n->created_at?->toIso8601String(),
            ])->values(),
            'meta' => ['unread_count' => $unread],
        ]);
    }

    public function read(Request $request, int $id): JsonResponse
    {
        $n = AppNotification::where('user_id', $request->user()->id)->findOrFail($id);
        $n->forceFill(['read_at' => $n->read_at ?? now()])->save();

        return response()->json(['message' => 'Notifikasi ditandai dibaca.']);
    }

    public function readAll(Request $request): JsonResponse
    {
        AppNotification::where('user_id', $request->user()->id)->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['message' => 'Semua notifikasi ditandai dibaca.']);
    }
}

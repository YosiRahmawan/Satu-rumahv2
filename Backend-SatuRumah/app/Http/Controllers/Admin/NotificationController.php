<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = AppNotification::where('user_id', $request->user()->id)->latest('id')->limit(100)->get();

        return view('admin.notifikasi.index', [
            'notifications' => $notifications,
            'unreadCount' => $notifications->whereNull('read_at')->count(),
        ]);
    }

    public function read(Request $request, int $id)
    {
        $n = AppNotification::where('user_id', $request->user()->id)->findOrFail($id);
        $n->forceFill(['read_at' => $n->read_at ?? now()])->save();

        return $n->submission_id
            ? redirect()->route('pengajuan.show', $n->submission_id)
            : back();
    }

    public function readAll(Request $request)
    {
        AppNotification::where('user_id', $request->user()->id)->whereNull('read_at')->update(['read_at' => now()]);

        return back()->with('success', 'Semua notifikasi ditandai sudah dibaca.');
    }
}

@extends('layouts.portal')

@section('title', 'Notifikasi - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs"><b>Notifikasi</b></div>
        <div class="hero-title">Pusat Notifikasi</div>
        <div class="hero-sub">{{ $unreadCount }} notifikasi belum dibaca.</div>
    </div>
    @if($unreadCount > 0)
        <form action="{{ route('notifikasi.read_all') }}" method="POST">
            @csrf
            <button type="submit" class="btn btn-white">Tandai Semua Dibaca</button>
        </form>
    @endif
</div>

<div class="notif-list">
    @forelse($notifications as $n)
        <div class="notif {{ $n->read_at ? 'read' : 'unread' }}">
            <div class="notif-body">
                @unless($n->read_at)
                    <div class="notif-meta"><span class="badge badge-danger badge-dot">Belum dibaca</span></div>
                @endunless
                <div class="notif-text"><strong>{{ $n->title }}</strong>@if($n->body) &middot; {{ $n->body }}@endif</div>
                <div class="notif-time">{{ $n->created_at?->translatedFormat('d M Y, H.i') }} WIB</div>
            </div>
            <div class="notif-actions">
                <form action="{{ route('notifikasi.read', $n->id) }}" method="POST">
                    @csrf
                    <button type="submit" class="link-muted" style="font-weight:700;">{{ $n->submission_id ? 'Buka' : 'Tandai dibaca' }}</button>
                </form>
            </div>
        </div>
    @empty
        <div class="card"><div class="card-body text-muted" style="text-align:center;">Belum ada notifikasi.</div></div>
    @endforelse
</div>
@endsection

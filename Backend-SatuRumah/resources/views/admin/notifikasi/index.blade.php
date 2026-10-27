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

@php
    // Jenis notifikasi -> label, warna, dan ikon (path SVG 24x24).
    $jenis = [
        'submitted' => ['Pengajuan Baru', 'danger', 'M12 5v14M5 12h14'],
        'resubmitted' => ['Perbaikan Terkirim', 'warn', 'M4 4v6h6M20 20v-6h-6M20 10A8 8 0 006 6M4 14a8 8 0 0014 4'],
        'report_submitted' => ['Laporan Survei', 'info', 'M9 12h6m-6 4h6M7 3h7l5 5v13H7z'],
        'assignment' => ['Penugasan', 'info', 'M8 7V3m8 4V3M4 11h16M5 5h14a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V6a1 1 0 011-1z'],
        'survey_scheduled' => ['Jadwal Survei', 'info', 'M8 7V3m8 4V3M4 11h16M5 5h14a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V6a1 1 0 011-1z'],
        'stage_advanced' => ['Tahap Lanjut', 'ok', 'M13 5l7 7-7 7M5 12h14'],
        'decided' => ['Keputusan', 'ok', 'M5 13l4 4L19 7'],
    ];
@endphp

<div class="notif-list">
    @forelse($notifications as $n)
        @php [$label, $warna, $ikon] = $jenis[$n->type] ?? ['Notifikasi', 'muted', 'M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 10-12 0v3.2a2 2 0 01-.6 1.4L4 17h5m6 0a3 3 0 11-6 0']; @endphp
        <div class="notif {{ $n->read_at ? 'read' : 'unread' }}">
            <div class="notif-icon is-{{ $warna }}">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="{{ $ikon }}"/></svg>
            </div>
            <div class="notif-body">
                <div class="notif-meta">
                    <span class="tl-tag {{ $warna === 'danger' ? 'bad' : $warna }}">{{ $label }}</span>
                    @if($n->read_at)
                        <span class="badge badge-success badge-dot">Sudah dibaca</span>
                    @else
                        <span class="badge badge-danger badge-dot">Belum dibaca</span>
                    @endif
                </div>
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

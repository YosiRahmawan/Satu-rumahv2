@extends('layouts.portal')

@section('title', 'Detail Pengajuan - ' . $s->number)

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs">
            <a href="{{ route('pengajuan.index') }}" style="color:#fff;opacity:.85;">Antrean Pengajuan</a> &nbsp;&gt;&nbsp; <b>{{ $s->number }}</b>
        </div>
        <div class="hero-tags">
            <span class="hero-tag">{{ $s->number }}</span>
            @if($s->isInRevision()) <span class="hero-tag warning">Menunggu perbaikan pengembang</span> @endif
        </div>
        <div class="hero-title">{{ $s->nama_perumahan }}</div>
        <div class="hero-sub">{{ $s->developer?->developerProfile?->nama_pt }} &middot; Tahap: {{ $s->tahapLabel() }} &middot; {{ $s->statusLabel() }}</div>
    </div>
</div>

@if($errors->any())
    <div class="alert alert-danger" style="margin-bottom:16px;">
        <div>
            <div class="alert-title">Belum bisa diproses</div>
            @if($errors->has('slots'))
                <div style="margin-bottom:6px;">Berkas wajib berikut belum berstatus Sesuai. Selesaikan dulu di tab Dokumen:</div>
                <ul style="margin:0;padding-left:18px;">
                    @foreach($errors->get('slots') as $e) <li>{{ $e }}</li> @endforeach
                </ul>
            @endif
            @foreach($errors->getBag('default')->getMessages() as $k => $msgs)
                @continue($k === 'slots')
                @foreach($msgs as $e) <div>{{ $e }}</div> @endforeach
            @endforeach
        </div>
    </div>
@endif

<div class="card">
    <div class="tabs">
        @foreach(['ringkasan' => 'Ringkasan', 'dokumen' => 'Dokumen', 'monitoring' => 'Survei & Monitoring', 'riwayat' => 'Riwayat'] as $key => $label)
            <a href="{{ route('pengajuan.show', ['id' => $s->id, 'tab' => $key]) }}" class="tab {{ $tab === $key ? 'active' : '' }}">{{ $label }}</a>
        @endforeach
    </div>
    <div class="card-body">
        @include('admin.pengajuan.tab_' . $tab)
    </div>
</div>
@endsection

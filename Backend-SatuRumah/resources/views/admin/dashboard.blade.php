@extends('layouts.portal')

@section('title', 'Dashboard - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs">Portal Admin &nbsp;&gt;&nbsp; <b>Dashboard</b></div>
        <div class="hero-title">Dashboard Pengawasan</div>
        <div class="hero-sub">Ringkasan pengajuan persetujuan site plan yang sedang berjalan.</div>
    </div>
    <div class="hero-meta">Diperbarui {{ now()->translatedFormat('d M Y, H.i') }} WIB</div>
</div>

@if($stats['perlu_tindak_lanjut'] > 0)
<div class="alert alert-warning" style="align-items:center;">
    <div style="flex:1;">
        <div class="alert-title">{{ $stats['perlu_tindak_lanjut'] }} pengajuan menunggu perbaikan dari pengembang</div>
    </div>
    <a href="{{ route('pengajuan.index', ['status' => 'perlu_perbaikan']) }}" class="btn btn-sm" style="background:#B45309;color:#fff;white-space:nowrap;">Lihat</a>
</div>
@endif

<div class="kpi-grid">
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Perlu Ditelaah</span></div>
        <div class="kpi-value">{{ $stats['pengajuan_baru'] }}<span class="kpi-unit">Berkas</span></div>
        <div class="kpi-note">Baru masuk atau perbaikan terkirim</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Verifikasi Teknis</span></div>
        <div class="kpi-value">{{ $stats['verifikasi_teknis'] }}<span class="kpi-unit">Proses</span></div>
        <div class="kpi-note">Berkas teknis sedang diperiksa</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Survei Berjalan</span></div>
        <div class="kpi-value">{{ $stats['survey_terjadwal'] }}<span class="kpi-unit">Lokasi</span></div>
        <div class="kpi-note">Penugasan belum selesai</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Menunggu Pengembang</span></div>
        <div class="kpi-value">{{ $stats['perlu_tindak_lanjut'] }}<span class="kpi-unit">Revisi</span></div>
        <div class="kpi-note">Perbaikan belum dijawab</div>
    </div>
</div>

<div class="card">
    <div class="card-head bordered">
        <div>
            <div class="card-title">Pengajuan Terbaru</div>
            <div class="card-sub">Lima pengajuan dengan aktivitas terakhir.</div>
        </div>
        <a href="{{ route('dashboard.export') }}" class="btn btn-outline">Ekspor CSV</a>
    </div>
    @include('admin.partials.table')
    <div class="card-foot">
        <div>Menampilkan <strong class="text-primary">{{ $pengajuans->count() }}</strong> dari <strong>{{ $pengajuans->total() }}</strong> pengajuan.</div>
        <a href="{{ route('pengajuan.index') }}" class="btn btn-soft btn-sm">Lihat semua antrean</a>
    </div>
</div>
@endsection

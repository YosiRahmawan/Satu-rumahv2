@extends('layouts.portal')

@section('title', 'Antrean Pengajuan - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs"><a href="{{ route('dashboard') }}" style="color:#fff;opacity:.85;">Dashboard</a> &nbsp;&gt;&nbsp; <b>Antrean Pengajuan</b></div>
        <div class="hero-title">Antrean Pengajuan</div>
        <div class="hero-sub">Pengajuan persetujuan site plan dari pengembang, dari verifikasi administrasi sampai keputusan akhir.</div>
    </div>
</div>

<div class="kpi-grid">
    <div class="kpi"><div class="kpi-top"><span class="kpi-label">Total Pengajuan</span></div><div class="kpi-value">{{ $totals['semua'] }}</div></div>
    <div class="kpi"><div class="kpi-top"><span class="kpi-label">Aktif</span></div><div class="kpi-value">{{ $totals['aktif'] }}</div></div>
    <div class="kpi"><div class="kpi-top"><span class="kpi-label">Perlu Ditelaah</span></div><div class="kpi-value">{{ $totals['menunggu'] }}</div></div>
    <div class="kpi"><div class="kpi-top"><span class="kpi-label">Menunggu Perbaikan</span></div><div class="kpi-value">{{ $totals['perbaikan'] }}</div></div>
</div>

<div class="card">
    <div class="card-head bordered">
        <div>
            <div class="card-title">Daftar Pengajuan</div>
            <div class="card-sub">{{ $pengajuans->firstItem() ?? 0 }}–{{ $pengajuans->lastItem() ?? 0 }} dari {{ $pengajuans->total() }}</div>
        </div>
        <a href="{{ route('dashboard.export') }}" class="btn btn-outline">Ekspor CSV</a>
    </div>

    <div style="padding:20px 24px 0;">
        <form method="GET" action="{{ route('pengajuan.index') }}" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
            <div class="search" style="flex:1;min-width:260px;">
                <input type="text" name="search" class="input" placeholder="Cari nomor, perumahan, atau nama PT" value="{{ request('search') }}" onchange="this.form.submit()">
            </div>
            <select name="tahap" class="select" onchange="this.form.submit()">
                <option value="">Semua tahap</option>
                @foreach([2, 3, 4, 5, 6] as $st)
                    <option value="{{ $st }}" @selected(request('tahap') == $st)>{{ \App\Models\Submission::TAHAP_LABEL[$st] }}</option>
                @endforeach
            </select>
            <select name="status" class="select" onchange="this.form.submit()">
                <option value="">Semua status</option>
                @foreach(\App\Models\Submission::STATUS_LABEL as $key => $label)
                    @continue($key === 'draft')
                    <option value="{{ $key }}" @selected(request('status') === $key)>{{ $label }}</option>
                @endforeach
            </select>
            @if(request()->hasAny(['search', 'tahap', 'status']))
                <a href="{{ route('pengajuan.index') }}" class="btn btn-outline btn-sm">&times; Reset</a>
            @endif
        </form>
    </div>

    <div style="margin-top:16px;">@include('admin.partials.table')</div>

    <div class="card-foot">
        <div>{{ $pengajuans->total() }} pengajuan</div>
        <div class="pagination">
            @if($pengajuans->onFirstPage()) <span class="page disabled">&lt;</span>
            @else <a href="{{ $pengajuans->previousPageUrl() }}" class="page">&lt;</a> @endif
            <span class="page active">{{ $pengajuans->currentPage() }}</span>
            @if($pengajuans->hasMorePages()) <a href="{{ $pengajuans->nextPageUrl() }}" class="page">&gt;</a>
            @else <span class="page disabled">&gt;</span> @endif
        </div>
    </div>
</div>
@endsection

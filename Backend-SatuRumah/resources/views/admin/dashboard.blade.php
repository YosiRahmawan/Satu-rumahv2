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
<div id="ringkasan" data-url="{{ route('dashboard.ringkasan') }}">
    @include('admin.partials.ringkasan')
</div>
@endsection

@section('scripts')
<script>
// Kartu ringkasan dimuat ulang tiap 5 detik (berhenti saat tab tersembunyi); batang bergeser halus ke nilai baru.
(function () {
    const box = document.getElementById('ringkasan');
    if (!box) return;
    async function segarkan() {
        if (document.hidden) return;
        try {
            const res = await fetch(box.dataset.url, { headers: { 'X-Requested-With': 'XMLHttpRequest' }, credentials: 'same-origin' });
            if (!res.ok) return;
            const lama = {};
            box.querySelectorAll('.progress-bar[data-kec]').forEach(b => lama[b.dataset.kec] = b.style.width);
            box.innerHTML = await res.text();
            box.querySelectorAll('.progress-bar[data-kec]').forEach(b => {
                const baru = b.dataset.lebar + '%';
                b.style.width = lama[b.dataset.kec] ?? '0%';
                requestAnimationFrame(() => requestAnimationFrame(() => b.style.width = baru));
            });
        } catch (e) { /* jaringan putus: biarkan data terakhir tampil */ }
    }
    setInterval(segarkan, 5000);
    document.addEventListener('visibilitychange', segarkan);
})();
</script>
@endsection

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

<div id="kpi" data-url="{{ route('dashboard.kpi') }}">
    @include('admin.partials.kpi')
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
// Kartu angka dan ringkasan dimuat ulang tiap 5 detik (berhenti saat tab tersembunyi); batang bergeser halus ke nilai baru.
(function () {
    const kpi = document.getElementById('kpi');
    const box = document.getElementById('ringkasan');
    async function ambil(el) {
        const res = await fetch(el.dataset.url, { headers: { 'X-Requested-With': 'XMLHttpRequest' }, credentials: 'same-origin' });
        return res.ok ? res.text() : null;
    }
    async function segarkan() {
        if (document.hidden) return;
        try {
            const [htmlKpi, htmlBox] = await Promise.all([ambil(kpi), ambil(box)]);
            if (htmlKpi !== null) kpi.innerHTML = htmlKpi;
            if (htmlBox === null) return;
            const lama = {};
            box.querySelectorAll('.progress-bar[data-kec]').forEach(b => lama[b.dataset.kec] = b.style.width);
            box.innerHTML = htmlBox;
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

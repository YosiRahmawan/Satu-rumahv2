{{-- Kartu angka dashboard; dimuat ulang berkala dari database. --}}
@if($stats['perlu_tindak_lanjut'] > 0)
<div class="alert alert-warning" style="align-items:center;">
    <div style="flex:1;">
        <div class="alert-title">{{ $stats['perlu_tindak_lanjut'] }} pengajuan menunggu perbaikan dari pengembang</div>
    </div>
    <a href="{{ route('pengajuan.index', ['status' => 'perlu_perbaikan']) }}" class="btn btn-sm" style="background:#B45309;color:#fff;white-space:nowrap;">Lihat</a>
</div>
@endif

<div class="kpi-grid is-enam">
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Total Masuk {{ $stats['tahun'] }}</span><span class="kpi-icon is-merah"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg></span></div>
        <div class="kpi-value">{{ $stats['masuk'] }}<span class="kpi-unit">Pengajuan</span></div>
        <div class="kpi-note">Terkirim tahun ini</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Perlu Ditelaah</span><span class="kpi-icon is-kuning"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 12h6m-6 4h6M7 3h7l5 5v13H7z"/></svg></span></div>
        <div class="kpi-value">{{ $stats['pengajuan_baru'] }}<span class="kpi-unit">Berkas</span></div>
        <div class="kpi-note">Baru masuk / revisi</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Verifikasi Teknis</span><span class="kpi-icon is-biru"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5h6M9 3h6v4H9zM6 5H5v16h14V5h-1M9 14l2 2 4-4"/></svg></span></div>
        <div class="kpi-value">{{ $stats['verifikasi_teknis'] }}<span class="kpi-unit">Proses</span></div>
        <div class="kpi-note">Sedang diperiksa</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Survei Berjalan</span><span class="kpi-icon is-hijau"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 21s7-6.2 7-11a7 7 0 10-14 0c0 4.8 7 11 7 11zM12 12a2 2 0 100-4 2 2 0 000 4z"/></svg></span></div>
        <div class="kpi-value">{{ $stats['survey_terjadwal'] }}<span class="kpi-unit">Lokasi</span></div>
        <div class="kpi-note">Penugasan aktif</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Menunggu Pengembang</span><span class="kpi-icon is-oranye"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 7v5l3 2M12 21a9 9 0 100-18 9 9 0 000 18z"/></svg></span></div>
        <div class="kpi-value">{{ $stats['perlu_tindak_lanjut'] }}<span class="kpi-unit">Revisi</span></div>
        <div class="kpi-note">Belum dijawab</div>
    </div>
    <div class="kpi">
        <div class="kpi-top"><span class="kpi-label">Selesai</span><span class="kpi-icon is-hijau"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 13l4 4L19 7"/></svg></span></div>
        <div class="kpi-value">{{ $stats['selesai'] }}<span class="kpi-unit">Disetujui</span></div>
        <div class="kpi-note">Dari {{ $stats['masuk'] }} pengajuan masuk &middot; {{ $stats['ditolak'] }} ditolak</div>
    </div>
</div>

@php $p = $s->developer?->developerProfile; @endphp
<div class="grid-main-side">
    <div class="card" style="box-shadow:none;">
        <div class="card-head bordered"><div class="card-title" style="font-size:16px;">Informasi Pengajuan</div></div>
        <div class="card-body" style="padding:8px 24px 20px;">
            <dl class="kv">
                <div class="kv-row"><dt>Perusahaan</dt><dd>{{ $p?->nama_pt ?? '-' }}</dd></div>
                <div class="kv-row"><dt>Nama perumahan</dt><dd>{{ $s->nama_perumahan }}</dd></div>
                <div class="kv-row"><dt>Alamat proyek</dt><dd>{{ $s->alamat_proyek }}</dd></div>
                <div class="kv-row"><dt>Kecamatan</dt><dd>{{ $s->kecamatan ?: '-' }}</dd></div>
                <div class="kv-row"><dt>Titik lokasi</dt><dd>
                    @if($s->latitude !== null && $s->longitude !== null)
                        <a href="https://www.google.com/maps/search/?api=1&query={{ $s->latitude }},{{ $s->longitude }}" target="_blank" rel="noopener">{{ number_format($s->latitude, 6) }}, {{ number_format($s->longitude, 6) }} &middot; Buka di peta</a>
                    @elseif($s->alamat_proyek)
                        <span class="text-muted">Belum dikirim pengembang.</span> <a href="https://www.google.com/maps/search/?api=1&query={{ urlencode($s->alamat_proyek) }}" target="_blank" rel="noopener">Cari alamat di peta</a>
                    @else
                        -
                    @endif
                </dd></div>
                <div class="kv-row"><dt>Jenis pengajuan</dt><dd>{{ $s->tipe_pengajuan }}</dd></div>
                <div class="kv-row"><dt>NPWP</dt><dd>{{ $s->npwp }}</dd></div>
                <div class="kv-row"><dt>Luas lahan</dt><dd>{{ $s->luas_lahan }} m²</dd></div>
                <div class="kv-row"><dt>Jumlah unit</dt><dd>{{ $s->jumlah_unit }}</dd></div>
                <div class="kv-row"><dt>Tipe perumahan</dt><dd>{{ $s->tipe_perumahan }}</dd></div>
                <div class="kv-row"><dt>Diajukan</dt><dd>{{ $s->submitted_at?->translatedFormat('d F Y, H.i') }}</dd></div>
                @if($s->correction_deadline_at && $s->isInRevision())
                    <div class="kv-row"><dt>Batas perbaikan</dt><dd>{{ $s->correction_deadline_at->translatedFormat('d F Y') }}</dd></div>
                @endif
                @if($s->decision_number)
                    <div class="kv-row"><dt>Nomor keputusan</dt><dd>{{ $s->decision_number }} ({{ $s->decision_date?->translatedFormat('d F Y') }})</dd></div>
                @endif
            </dl>
        </div>
    </div>

    <div class="card" style="box-shadow:none;">
        <div class="card-head bordered"><div class="card-title" style="font-size:16px;">Tindakan Tahap Ini</div></div>
        <div class="card-body">
            <div style="margin-bottom:14px;">@include('admin.partials.status', ['s' => $s])</div>

            @if($s->isInRevision())
                <p style="font-size:14px;">Menunggu pengembang mengirim perbaikan berkas. Tindakan lain dibuka setelah perbaikan diterima.</p>
            @elseif($s->stage === \App\Models\Submission::STAGE_ADMINISTRASI)
                @php $siap = $progresAdministrasi['siap']; $total = $progresAdministrasi['total']; $lengkap = $siap === $total; @endphp
                <div style="margin-bottom:14px;">
                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px;"><span>Berkas administrasi sesuai</span><strong>{{ $siap }} dari {{ $total }}</strong></div>
                    <div class="progress"><div class="progress-bar" style="width:{{ $total ? round($siap / $total * 100) : 0 }}%;"></div></div>
                </div>
                @if($lengkap)
                    <p style="font-size:14px;margin-bottom:14px;">Semua berkas sudah dinilai sesuai. Konfirmasi untuk melanjutkan ke verifikasi teknis; pengembang akan diberi tahu.</p>
                    <form method="POST" action="{{ route('pengajuan.setujui_administrasi', $s->id) }}" data-konfirmasi="Pengajuan akan lanjut ke verifikasi teknis dan pengembang diberi tahu." data-konfirmasi-judul="Setujui Verifikasi Administrasi" data-konfirmasi-tombol="Ya, setujui">
                        @csrf <button class="btn btn-primary btn-block">Setujui Verifikasi Administrasi</button>
                    </form>
                @else
                    <p style="font-size:14px;margin-bottom:14px;">Nilai semua berkas di tab Dokumen. Tombol setuju aktif setelah seluruhnya sesuai.</p>
                    <button class="btn btn-primary btn-block" disabled title="Masih ada berkas yang belum sesuai">Setujui Verifikasi Administrasi</button>
                @endif
            @elseif($s->stage === \App\Models\Submission::STAGE_TEKNIS)
                @php $siap = $progresTeknis['siap']; $total = $progresTeknis['total']; $lengkap = $siap === $total; @endphp
                <div style="margin-bottom:14px;">
                    <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px;"><span>Berkas teknis sesuai</span><strong>{{ $siap }} dari {{ $total }}</strong></div>
                    <div class="progress"><div class="progress-bar" style="width:{{ $total ? round($siap / $total * 100) : 0 }}%;"></div></div>
                </div>
                @if($lengkap)
                    <p style="font-size:14px;margin-bottom:14px;">Semua berkas teknis sesuai. Jadwalkan survei di bawah ini.</p>
                    @include('admin.pengajuan._form-jadwal', ['kompak' => true])
                @else
                    <p style="font-size:14px;margin-bottom:14px;">Nilai semua berkas teknis di tab Dokumen. Form jadwal survei muncul di sini setelah seluruhnya sesuai.</p>
                    <a href="{{ route('pengajuan.show', ['id' => $s->id, 'tab' => 'dokumen']) }}" class="btn btn-outline btn-block">Buka tab Dokumen</a>
                @endif
            @elseif($s->stage === \App\Models\Submission::STAGE_SURVEI)
                @php $laporanFinal = $s->reports->firstWhere('status', 'final'); @endphp
                @if($laporanFinal)
                    <p style="font-size:14px;margin-bottom:14px;">Petugas sudah mengirim BA <strong>{{ $laporanFinal->report_number }}</strong>. Periksa isinya di tab Survei &amp; Monitoring, lalu terima untuk lanjut ke persetujuan.</p>
                    <form method="POST" action="{{ route('pengajuan.terima_laporan', $s->id) }}" data-konfirmasi="Laporan survei diterima dan pengajuan masuk tahap persetujuan." data-konfirmasi-judul="Terima Laporan Survei" data-konfirmasi-tombol="Ya, terima">
                        @csrf <button class="btn btn-primary btn-block">Terima Laporan Survei</button>
                    </form>
                    @include('admin.pengajuan._minta-perbaikan-ba', ['r' => $laporanFinal])
                    <a href="{{ route('pengajuan.show', ['id' => $s->id, 'tab' => 'monitoring']) }}" class="btn btn-outline btn-block" style="margin-top:8px;">Lihat BA</a>
                @else
                    <p style="font-size:14px;margin-bottom:14px;">Survei berjalan. Menunggu petugas mengirim Berita Acara.</p>
                    <a href="{{ route('pengajuan.show', ['id' => $s->id, 'tab' => 'monitoring']) }}" class="btn btn-outline btn-block">Lihat penugasan</a>
                @endif
            @elseif($s->stage === \App\Models\Submission::STAGE_PERSETUJUAN)
                <form method="POST" action="{{ route('pengajuan.keputusan', $s->id) }}" class="form-group" style="display:grid;gap:10px;" data-konfirmasi="Keputusan akhir tidak dapat diubah setelah disimpan." data-konfirmasi-judul="Simpan Keputusan Akhir" data-konfirmasi-tombol="Ya, simpan">
                    @csrf
                    <label class="form-label">Keputusan</label>
                    <select name="keputusan" class="form-select">
                        <option value="setuju">Setujui</option>
                        <option value="tolak">Tolak</option>
                    </select>
                    <label class="form-label">Nomor keputusan (bila disetujui)</label>
                    <input class="form-input" name="nomor" value="{{ old('nomor') }}">
                    <label class="form-label">Tanggal keputusan (bila disetujui)</label>
                    <input class="form-input" type="date" name="tanggal" value="{{ old('tanggal', now()->toDateString()) }}">
                    <label class="form-label">Alasan (wajib bila ditolak)</label>
                    <textarea class="form-textarea" name="catatan" rows="3">{{ old('catatan') }}</textarea>
                    <button class="btn btn-primary btn-block">Simpan Keputusan</button>
                </form>
            @else
                <p style="font-size:14px;">Proses selesai: {{ $s->statusLabel() }}.</p>
            @endif
        </div>
    </div>
</div>

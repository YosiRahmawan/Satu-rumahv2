@php $p = $s->developer?->developerProfile; @endphp
<div class="grid-main-side">
    <div class="card" style="box-shadow:none;">
        <div class="card-head bordered"><div class="card-title" style="font-size:16px;">Informasi Pengajuan</div></div>
        <div class="card-body" style="padding:8px 24px 20px;">
            <dl class="kv">
                <div class="kv-row"><dt>Perusahaan</dt><dd>{{ $p?->nama_pt ?? '-' }}</dd></div>
                <div class="kv-row"><dt>Nama perumahan</dt><dd>{{ $s->nama_perumahan }}</dd></div>
                <div class="kv-row"><dt>Alamat proyek</dt><dd>{{ $s->alamat_proyek }}</dd></div>
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
                <p style="font-size:14px;margin-bottom:14px;">Nilai berkas di tab Dokumen. Setelah semua berkas administrasi sesuai, setujui untuk lanjut ke verifikasi teknis.</p>
                <form method="POST" action="{{ route('pengajuan.setujui_administrasi', $s->id) }}" data-konfirmasi="Semua berkas administrasi sudah sesuai. Pengajuan akan lanjut ke verifikasi teknis dan pengembang diberi tahu." data-konfirmasi-judul="Setujui Verifikasi Administrasi" data-konfirmasi-tombol="Ya, setujui">
                    @csrf <button class="btn btn-primary btn-block">Setujui Verifikasi Administrasi</button>
                </form>
            @elseif($s->stage === \App\Models\Submission::STAGE_TEKNIS)
                <p style="font-size:14px;">Nilai berkas teknis di tab Dokumen, lalu jadwalkan survei di tab Survei &amp; Monitoring.</p>
            @elseif($s->stage === \App\Models\Submission::STAGE_SURVEI)
                <p style="font-size:14px;">Survei berjalan. Terima laporan petugas di tab Survei &amp; Monitoring.</p>
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

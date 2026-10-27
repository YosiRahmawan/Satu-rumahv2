@php
    $fotoData = [];
    $canSchedule = in_array($s->stage, [\App\Models\Submission::STAGE_TEKNIS, \App\Models\Submission::STAGE_SURVEI], true) && !$s->isInRevision();
    $openAssignment = $s->assignments->first(fn ($a) => $a->isOpen());
    $finalReport = $s->reports->firstWhere('status', 'final');
@endphp

@if($canSchedule)
<div class="card" style="box-shadow:none;margin-bottom:20px;">
    <div class="card-head bordered">
        <div>
            <div class="card-title" style="font-size:16px;">{{ $openAssignment ? 'Ubah Jadwal / Alihkan Petugas' : 'Jadwalkan Survei' }}</div>
            <div class="card-sub">Tentukan petugas dan tanggal. Tugas langsung muncul di aplikasi petugas.</div>
        </div>
    </div>
    <div class="card-body">
        <form method="POST" action="{{ route('pengajuan.jadwal', $s->id) }}" class="grid-2">
            @csrf
            <div class="form-group">
                <label class="form-label">Petugas lapangan</label>
                <select name="petugas_id" class="form-select" required>
                    @foreach($officers as $o)
                        <option value="{{ $o->id }}" @selected($openAssignment?->officer_id === $o->id)>{{ $o->name }}</option>
                    @endforeach
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Tanggal survei</label>
                <input type="date" name="tanggal" class="form-input" min="{{ now()->toDateString() }}" value="{{ old('tanggal', $openAssignment?->scheduled_date?->toDateString()) }}" required>
            </div>
            <div class="form-group" style="grid-column:1/-1;">
                <label class="form-label">Anggota tim pelaksana (selain petugas utama)</label>
                <div style="display:flex;flex-wrap:wrap;gap:6px 18px;">
                    @php $chosen = collect(old('anggota', $openAssignment?->members->pluck('id')->all() ?? [])); @endphp
                    @foreach($officers as $o)
                        <label style="display:flex;gap:6px;align-items:center;font-size:13px;">
                            <input type="checkbox" name="anggota[]" value="{{ $o->id }}" @checked($chosen->contains($o->id))>
                            {{ $o->name }}@if($o->jabatan) <span class="text-muted">({{ $o->jabatan }})</span>@endif
                        </label>
                    @endforeach
                </div>
                <div class="text-muted" style="font-size:12px;margin-top:4px;">Nama tim ini otomatis tertulis di Berita Acara; petugas tidak bisa mengubahnya di aplikasi.</div>
            </div>
            <div class="form-group">
                <label class="form-label">Catatan untuk petugas</label>
                <input name="catatan" class="form-input" value="{{ old('catatan') }}">
            </div>
            @if($openAssignment)
                <div class="form-group">
                    <label class="form-label">Alasan perubahan</label>
                    <input name="alasan" class="form-input" value="{{ old('alasan') }}">
                </div>
            @endif
            <div style="grid-column:1/-1;display:flex;justify-content:flex-end;"><button class="btn btn-primary">{{ $openAssignment ? 'Simpan Perubahan' : 'Jadwalkan' }}</button></div>
        </form>
    </div>
</div>
@endif

<div class="card" style="box-shadow:none;margin-bottom:20px;">
    <div class="card-head bordered"><div><div class="card-title" style="font-size:16px;">Penugasan</div><div class="card-sub">Riwayat penugasan survei untuk pengajuan ini beserta statusnya.</div></div></div>
    <div class="table-wrap">
        <table class="table">
            <thead><tr><th>Petugas / Tim</th><th>Tanggal</th><th>Status</th><th>Catatan</th></tr></thead>
            <tbody>
                @forelse($s->assignments as $a)
                    <tr>
                        <td class="col-strong">{{ collect($a->team())->pluck('nama')->implode(', ') }}</td>
                        <td>{{ $a->scheduled_date?->translatedFormat('d M Y') }}</td>
                        <td><span class="badge {{ $a->status === 'selesai' ? 'badge-success' : ($a->isOpen() ? 'badge-info' : '') }} badge-dot">{{ ucfirst($a->status) }}</span></td>
                        <td class="text-muted">{{ $a->reassign_reason ?? $a->note }}</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="text-muted" style="text-align:center;padding:24px;">Belum ada penugasan survei.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<div class="card" style="box-shadow:none;">
    <div class="card-head bordered">
        <div><div class="card-title" style="font-size:16px;">Laporan Survei (BA)</div><div class="card-sub">Berita Acara dan foto lapangan yang dikirim petugas setelah survei.</div></div>
        @if($s->stage === \App\Models\Submission::STAGE_SURVEI && !$s->isInRevision())
            <form method="POST" action="{{ route('pengajuan.terima_laporan', $s->id) }}" data-konfirmasi="Laporan survei akan diterima dan pengajuan lanjut ke tahap persetujuan." data-konfirmasi-judul="Terima Laporan Survei" data-konfirmasi-tombol="Ya, terima">
                @csrf <button class="btn btn-primary" @disabled(!$finalReport)>Terima Laporan &amp; Lanjut</button>
            </form>
        @endif
    </div>
    <div class="card-body">
        @forelse($s->reports->where('status', 'final') as $r)
            <div style="margin-bottom:22px;">
                <div class="fw-700">{{ $r->report_number }} &middot; {{ $r->officer?->name }}</div>
                <div class="text-muted" style="font-size:12px;margin-bottom:8px;">
                    Dikirim {{ $r->submitted_at?->translatedFormat('d M Y, H.i') }} &middot; Hasil: {{ $r->status_hasil_evaluasi }}
                </div>
                <p style="font-size:14px;margin-bottom:8px;">{{ $r->maksud_tujuan }}</p>
                @if($r->photos->isNotEmpty())
                    <div style="display:flex;gap:10px;flex-wrap:wrap;">
                        @foreach($r->photos as $ph)
                            @php
                                $fotoData[] = [
                                    'src' => route('pengajuan.foto', [$s->id, $ph->id]),
                                    'posisi' => $ph->position,
                                    'lat' => $ph->latitude, 'lng' => $ph->longitude, 'akurasi' => $ph->accuracy_m,
                                    'waktu' => $ph->captured_at ? $ph->captured_at->translatedFormat('d F Y · H.i') . ' WIB' : null,
                                    'alamat' => $ph->address, 'catatan' => $ph->note,
                                    'petugas' => $r->officer?->name, 'laporan' => $r->report_number,
                                ];
                            @endphp
                            <button type="button" data-foto="{{ count($fotoData) - 1 }}" title="Lihat detail foto" style="padding:0;border:0;background:none;cursor:zoom-in;">
                                <img src="{{ route('pengajuan.foto', [$s->id, $ph->id]) }}" alt="Foto {{ $ph->position }}" loading="lazy" style="width:150px;height:110px;object-fit:cover;border-radius:8px;border:1px solid var(--border);">
                            </button>
                        @endforeach
                    </div>
                @endif
            </div>
        @empty
            <div class="text-muted">Belum ada laporan final dari petugas.</div>
        @endforelse
    </div>
</div>

<div id="fotoModal" class="modal-backdrop" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="fotoJudul">
    <div class="foto-modal">
        <div class="foto-head">
            <div>
                <span class="badge badge-info" id="fotoUrut"></span>
                <h3 class="modal-title" id="fotoJudul" style="margin-top:6px;">Bukti Foto Lapangan</h3>
            </div>
            <div style="display:flex;gap:8px;align-items:center;">
                <a id="fotoPeta" class="btn btn-outline btn-sm" target="_blank" rel="noopener">Buka di Peta</a>
                <a id="fotoUnduh" class="btn btn-outline btn-sm" download>Unduh</a>
                <button type="button" class="modal-close" id="fotoTutup" aria-label="Tutup" style="font-size:24px;">&times;</button>
            </div>
        </div>
        <div class="foto-body">
            <div class="foto-stage">
                <img id="fotoImg" alt="Foto lapangan">
                <span class="foto-gps" id="fotoGps"></span>
                <div class="foto-nav">
                    <button type="button" class="btn btn-outline btn-sm" id="fotoPrev">&lsaquo; Sebelumnya</button>
                    <button type="button" class="btn btn-primary btn-sm" id="fotoNext">Berikutnya &rsaquo;</button>
                </div>
            </div>
            <div class="foto-info">
                <div><div class="fw-700">Informasi Foto</div><div class="text-muted" style="font-size:12px;">Metadata GPS dikirim petugas bersama foto.</div></div>
                <dl class="kv" id="fotoMeta"></dl>
            </div>
        </div>
    </div>
</div>

<script>
(function () {
    const data = @json($fotoData);
    if (!data.length) return;
    const $ = (id) => document.getElementById(id);
    let i = 0;
    const esc = (t) => String(t ?? '-').replace(/[&<>"]/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;'}[c]));
    const baris = (k, v) => '<div class="kv-row"><dt>' + k + '</dt><dd>' + v + '</dd></div>';
    function tampil(n) {
        i = (n + data.length) % data.length;
        const f = data[i];
        $('fotoUrut').textContent = 'Foto ' + (i + 1) + ' dari ' + data.length;
        $('fotoJudul').textContent = f.catatan || ('Foto lapangan ' + f.posisi);
        $('fotoImg').src = f.src;
        $('fotoUnduh').href = f.src;
        const ada = f.lat != null && f.lng != null;
        $('fotoGps').textContent = ada ? 'GPS ±' + (f.akurasi != null ? Number(f.akurasi).toFixed(1) : '?') + ' m' : '';
        $('fotoGps').style.display = ada ? '' : 'none';
        $('fotoPeta').style.display = ada ? '' : 'none';
        if (ada) $('fotoPeta').href = 'https://www.google.com/maps?q=' + f.lat + ',' + f.lng;
        $('fotoMeta').innerHTML =
            baris('Koordinat', ada ? Number(f.lat).toFixed(6) + ', ' + Number(f.lng).toFixed(6) : '-') +
            baris('Alamat', esc(f.alamat)) + baris('Waktu', esc(f.waktu)) +
            baris('Petugas', esc(f.petugas)) + baris('No. BA', esc(f.laporan)) + baris('Catatan', esc(f.catatan));
    }
    const tutup = () => { $('fotoModal').style.display = 'none'; $('fotoImg').removeAttribute('src'); };
    document.querySelectorAll('[data-foto]').forEach(b => b.addEventListener('click', () => { tampil(+b.dataset.foto); $('fotoModal').style.display = 'flex'; }));
    $('fotoPrev').onclick = () => tampil(i - 1);
    $('fotoNext').onclick = () => tampil(i + 1);
    $('fotoTutup').onclick = tutup;
    $('fotoModal').addEventListener('click', (e) => { if (e.target === $('fotoModal')) tutup(); });
    document.addEventListener('keydown', (e) => {
        if ($('fotoModal').style.display === 'none') return;
        if (e.key === 'Escape') tutup();
        if (e.key === 'ArrowLeft') tampil(i - 1);
        if (e.key === 'ArrowRight') tampil(i + 1);
    });
})();
</script>

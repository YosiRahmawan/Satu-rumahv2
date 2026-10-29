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
            <thead><tr><th>Petugas / Tim</th><th>Tanggal</th><th>Status</th><th>Catatan</th><th class="col-actions">Aksi</th></tr></thead>
            <tbody>
                @forelse($s->assignments as $a)
                    <tr>
                        <td class="col-strong">{{ collect($a->team())->pluck('nama')->implode(', ') }}</td>
                        <td>{{ $a->scheduled_date?->translatedFormat('d M Y') }}</td>
                        <td><span class="badge {{ $a->status === 'selesai' ? 'badge-success' : ($a->isOpen() ? 'badge-info' : '') }} badge-dot">{{ ucfirst($a->status) }}</span></td>
                        <td class="text-muted">{{ $a->reassign_reason ?? $a->note }}</td>
                        <td class="col-actions">
                            @if($a->isOpen() && !$s->isInRevision())
                                <button type="button" class="btn btn-outline btn-sm" data-batal="{{ route('pengajuan.batal_jadwal', [$s->id, $a->id]) }}" data-batal-nama="{{ collect($a->team())->pluck('nama')->implode(', ') }}">Batalkan</button>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="text-muted" style="text-align:center;padding:24px;">Belum ada penugasan survei.</td></tr>
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
                <div style="display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap;">
                    <div class="fw-700">{{ $r->report_number }} &middot; {{ $r->officer?->name }}</div>
                    @php
                        $diverifikasi = $s->stage >= \App\Models\Submission::STAGE_PERSETUJUAN;
                        $ttd = app(\App\Services\SignatureService::class)->status($r);
                    @endphp
                    <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;">
                        @if($r->published_at)
                            <span class="badge badge-success badge-dot">Diterbitkan {{ $r->published_at->translatedFormat('d M Y') }}</span>
                            @if($r->pdf_path)<a class="btn btn-outline btn-sm" href="{{ route('pengajuan.pdf_ba', [$s->id, $r->id]) }}">Unduh PDF</a>@endif
                        @elseif($diverifikasi)
                            <span class="badge badge-info badge-dot">Diverifikasi</span>
                            @if($ttd['ready_to_publish'])
                                <form method="POST" action="{{ route('pengajuan.terbitkan_ba', [$s->id, $r->id]) }}" data-konfirmasi="BA {{ $r->report_number }} akan ditandai terbit dan PDF final dibuat. Petugas dan pengembang diberi tahu." data-konfirmasi-judul="Terbitkan BA" data-konfirmasi-tombol="Ya, terbitkan">
                                    @csrf <button class="btn btn-primary btn-sm">Terbitkan BA</button>
                                </form>
                            @elseif($ttd['ketua']['signed'])
                                <button type="button" class="btn btn-primary btn-sm" data-ttd="{{ route('pengajuan.tanda_tangan_ba', [$s->id, $r->id]) }}" data-ttd-versi="{{ $r->version }}" data-ttd-nomor="{{ $r->report_number }}">Tanda tangani</button>
                                <button type="button" class="btn btn-primary btn-sm" disabled title="Tanda tangani dulu">Terbitkan BA</button>
                            @else
                                <button type="button" class="btn btn-primary btn-sm" disabled title="Menunggu tanda tangan Ketua Pengawas">Terbitkan BA</button>
                            @endif
                        @else
                            <span class="badge badge-warning badge-dot">Dikirim</span>
                            <span class="text-muted" style="font-size:12px;">Terima laporan untuk memverifikasi</span>
                        @endif
                    </div>
                </div>
                <div style="display:flex;gap:8px;flex-wrap:wrap;margin:6px 0;">
                    <span class="badge {{ $ttd['ketua']['signed'] ? 'badge-success' : 'badge-warning' }} badge-dot">Ketua Pengawas: {{ $ttd['ketua']['signed'] ? 'sudah menyetujui' : 'belum menyetujui' }}</span>
                    <span class="badge {{ $ttd['admin']['signed'] ? 'badge-success' : '' }} badge-dot">Admin: {{ $ttd['admin']['signed'] ? 'sudah menyetujui' : 'belum menyetujui' }}</span>
                </div>
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

<div id="batalModal" class="modal-backdrop" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="batalJudul">
    <div class="modal" style="max-width:460px;">
        <div class="modal-head">
            <div>
                <h3 class="modal-title" id="batalJudul">Batalkan Penugasan</h3>
                <div class="modal-sub" id="batalNama"></div>
            </div>
            <button type="button" class="modal-close" id="batalTutup" aria-label="Tutup" style="font-size:24px;">&times;</button>
        </div>
        <form method="POST" id="batalForm" action="#">
            @csrf
            <div class="modal-body" style="display:grid;gap:12px;">
                <p style="margin:0;font-size:14px;">Petugas dan pengembang akan diberi tahu. Setelah dibatalkan, jadwalkan ulang survei dari kartu di atas.</p>
                <div><label class="form-label" for="batalAlasan">Alasan pembatalan</label><textarea class="form-textarea" name="alasan" id="batalAlasan" rows="3" maxlength="300" required></textarea></div>
            </div>
            <div class="modal-foot">
                <button type="button" class="btn btn-outline" id="batalBatal">Kembali</button>
                <button type="submit" class="btn btn-primary">Batalkan Penugasan</button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const m = document.getElementById('batalModal');
    const tutup = () => { m.style.display = 'none'; };
    document.querySelectorAll('[data-batal]').forEach(b => b.addEventListener('click', () => {
        document.getElementById('batalForm').action = b.dataset.batal;
        document.getElementById('batalNama').textContent = b.dataset.batalNama;
        document.getElementById('batalAlasan').value = '';
        m.style.display = 'flex';
    }));
    document.getElementById('batalTutup').addEventListener('click', tutup);
    document.getElementById('batalBatal').addEventListener('click', tutup);
    m.addEventListener('click', (e) => { if (e.target === m) tutup(); });
})();
</script>

<div id="ttdModal" class="modal-backdrop" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="ttdJudul">
    <div class="modal" style="max-width:520px;">
        <div class="modal-head">
            <div>
                <h3 class="modal-title" id="ttdJudul">Tanda Tangan Admin</h3>
                <div class="modal-sub" id="ttdNomor"></div>
            </div>
            <button type="button" class="modal-close" id="ttdTutup" aria-label="Tutup" style="font-size:24px;">&times;</button>
        </div>
        <form method="POST" id="ttdForm" action="#" enctype="multipart/form-data">
            @csrf
            <input type="hidden" name="version" id="ttdVersi">
            <input type="hidden" name="method" id="ttdMetode" value="draw">
            <input type="hidden" name="signature_data" id="ttdData">
            <div class="modal-body" style="display:grid;gap:12px;">
                <div class="seg" style="justify-self:start;">
                    <button type="button" class="seg-btn is-active" data-ttd-tab="draw">Gambar langsung</button>
                    <button type="button" class="seg-btn" data-ttd-tab="upload">Unggah gambar</button>
                </div>

                <div id="ttdDraw">
                    <canvas id="ttdCanvas" width="460" height="180" style="width:100%;max-width:460px;height:auto;border:1px dashed var(--border-strong);border-radius:10px;background:#fff;touch-action:none;cursor:crosshair;"></canvas>
                    <div style="display:flex;gap:8px;margin-top:6px;"><button type="button" class="btn btn-outline btn-sm" id="ttdHapus">Hapus dan ulangi</button></div>
                </div>

                <div id="ttdUpload" style="display:none;">
                    <input type="file" id="ttdBerkas" accept="image/png,image/jpeg" class="form-input">
                    <div class="text-muted" style="font-size:12px;margin-top:4px;">PNG atau JPEG, maksimal 2 MB. Latar putih otomatis dibuat transparan.</div>
                    <button type="button" class="btn btn-outline btn-sm" id="ttdGanti" style="display:none;margin-top:6px;">Hapus gambar</button>
                </div>

                <div>
                    <div class="form-label">Pratinjau</div>
                    <div style="min-height:80px;border:1px solid var(--border);border-radius:10px;background:#fff;display:flex;align-items:center;justify-content:center;padding:8px;">
                        <img id="ttdPratinjau" alt="Pratinjau tanda tangan" style="max-height:90px;max-width:100%;display:none;">
                        <span id="ttdKosong" class="text-muted" style="font-size:12px;">Belum ada tanda tangan</span>
                    </div>
                </div>

                <div>
                    <label class="form-label" for="ttdSandi">Konfirmasi dengan sandi Anda</label>
                    <input class="form-input" type="password" name="password" id="ttdSandi" autocomplete="current-password" required>
                </div>
                <div class="text-muted" style="font-size:12px;">Ini persetujuan elektronik berbasis akun Anda, bukan tanda tangan elektronik tersertifikasi. Isi BA yang disetujui dikunci dengan sidik digital.</div>
            </div>
            <div class="modal-foot">
                <button type="button" class="btn btn-outline" id="ttdBatal">Batal</button>
                <button type="submit" class="btn btn-primary" id="ttdKirim">Setujui dan Tandatangani</button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const $ = (id) => document.getElementById(id);
    const m = $('ttdModal');
    if (!m) return;
    const canvas = $('ttdCanvas');
    const ctx = canvas.getContext('2d');
    let metode = 'draw', tergambar = false, menggambar = false, kirim = false;

    function reset() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        tergambar = false;
        $('ttdBerkas').value = '';
        $('ttdGanti').style.display = 'none';
        $('ttdData').value = '';
        pratinjau(null);
    }
    function pratinjau(src) {
        $('ttdPratinjau').style.display = src ? '' : 'none';
        $('ttdKosong').style.display = src ? 'none' : '';
        if (src) $('ttdPratinjau').src = src;
    }
    function tab(nama) {
        metode = nama;
        $('ttdMetode').value = nama;
        $('ttdDraw').style.display = nama === 'draw' ? '' : 'none';
        $('ttdUpload').style.display = nama === 'upload' ? '' : 'none';
        document.querySelectorAll('[data-ttd-tab]').forEach(b => b.classList.toggle('is-active', b.dataset.ttdTab === nama));
        // Hanya satu sumber gambar yang dikirim.
        $('ttdBerkas').name = nama === 'upload' ? 'signature' : '';
        reset();
    }
    const titik = (e) => {
        const r = canvas.getBoundingClientRect();
        return [(e.clientX - r.left) * canvas.width / r.width, (e.clientY - r.top) * canvas.height / r.height];
    };
    canvas.addEventListener('pointerdown', (e) => { menggambar = true; canvas.setPointerCapture(e.pointerId); const [x, y] = titik(e); ctx.beginPath(); ctx.moveTo(x, y); });
    canvas.addEventListener('pointermove', (e) => {
        if (!menggambar) return;
        const [x, y] = titik(e);
        ctx.lineWidth = 2.5; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.strokeStyle = '#111';
        ctx.lineTo(x, y); ctx.stroke(); tergambar = true;
    });
    const selesai = () => { if (!menggambar) return; menggambar = false; if (tergambar) pratinjau(canvas.toDataURL('image/png')); };
    canvas.addEventListener('pointerup', selesai);
    canvas.addEventListener('pointerleave', selesai);
    $('ttdHapus').addEventListener('click', reset);
    $('ttdGanti').addEventListener('click', reset);
    $('ttdBerkas').addEventListener('change', (e) => {
        const f = e.target.files[0];
        if (!f) return reset();
        if (!['image/png', 'image/jpeg'].includes(f.type) || f.size > 2 * 1024 * 1024) { alert('Pilih gambar PNG atau JPEG maksimal 2 MB.'); return reset(); }
        pratinjau(URL.createObjectURL(f));
        $('ttdGanti').style.display = '';
    });
    document.querySelectorAll('[data-ttd-tab]').forEach(b => b.addEventListener('click', () => tab(b.dataset.ttdTab)));

    const tutup = () => { m.style.display = 'none'; reset(); $('ttdSandi').value = ''; kirim = false; $('ttdKirim').disabled = false; };
    document.querySelectorAll('[data-ttd]').forEach(b => b.addEventListener('click', () => {
        $('ttdForm').action = b.dataset.ttd;
        $('ttdVersi').value = b.dataset.ttdVersi;
        $('ttdNomor').textContent = 'BA ' + b.dataset.ttdNomor;
        tab('draw');
        m.style.display = 'flex';
    }));
    $('ttdTutup').addEventListener('click', tutup);
    $('ttdBatal').addEventListener('click', tutup);
    m.addEventListener('click', (e) => { if (e.target === m) tutup(); });
    $('ttdForm').addEventListener('submit', (e) => {
        if (kirim) { e.preventDefault(); return; } // cegah kirim ganda
        if (metode === 'draw') {
            if (!tergambar) { e.preventDefault(); alert('Gambar tanda tangan Anda terlebih dahulu.'); return; }
            $('ttdData').value = canvas.toDataURL('image/png');
        } else if (!$('ttdBerkas').files.length) {
            e.preventDefault(); alert('Pilih gambar tanda tangan terlebih dahulu.'); return;
        }
        kirim = true; $('ttdKirim').disabled = true;
    });
})();
</script>

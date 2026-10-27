@php
    $canReview = $s->stage >= 2 && $s->stage <= 5 && !$s->isInRevision() && !in_array($s->sub_status, ['selesai', 'ditolak'], true);
    $flagged = $s->currentFiles->where('status', 'perlu_perbaikan')->count();
    $ukuran = fn ($bytes) => number_format($bytes / 1048576, 2) . ' MB';
@endphp

@if($s->isInRevision())
    <div class="callout" style="margin-bottom:16px;">Permintaan perbaikan sudah dikirim. Berkas bisa dinilai lagi setelah pengembang mengirim perbaikan.</div>
@endif

<div class="card" style="box-shadow:none;">
    <div class="card-head bordered">
        <div>
            <h2 class="card-title" style="font-size:16px;">Berkas Persyaratan</h2>
            <div class="card-sub">{{ $s->currentFiles->count() }} berkas aktif &middot; {{ $flagged }} perlu perbaikan</div>
        </div>
        @if($canReview && $flagged > 0)
            <form method="POST" action="{{ route('pengajuan.perbaikan', $s->id) }}" data-konfirmasi="Kirim permintaan perbaikan ke pengembang?" data-konfirmasi-judul="Kirim Permintaan Perbaikan" data-konfirmasi-tombol="Ya, kirim">
                @csrf <button class="btn btn-primary">Kirim Permintaan Perbaikan</button>
            </form>
        @endif
    </div>
    <div class="table-wrap">
        <table class="table">
            <thead>
                <tr><th>Persyaratan</th><th>Berkas</th><th>Status</th><th class="col-actions">Aksi</th></tr>
            </thead>
            <tbody>
                @foreach($slots as $code => $slot)
                    @php
                        $files = $filesBySlot->get($code, collect());
                        $grup = (int) ($slot['step'] ?? 2);
                        $judulGrup = [2 => 'Administrasi', 3 => 'Teknis', 4 => 'Site Plan & Kajian'][$grup] ?? 'Lainnya';
                        $terisi = $files->isNotEmpty();
                    @endphp
                    @if(($prevGrup ?? null) !== $grup)
                        @php
                            $prevGrup = $grup;
                            $dalamGrup = collect($slots)->filter(fn ($x) => (int) ($x['step'] ?? 2) === $grup)->keys();
                            $sesuaiGrup = $dalamGrup->filter(fn ($k) => $filesBySlot->get($k, collect())->isNotEmpty() && $filesBySlot->get($k)->every('status', 'lolos'))->count();
                        @endphp
                        <tr class="dok-grup"><td colspan="4">
                            <div class="dok-grup-isi">
                                <div>
                                    <span class="dok-grup-judul">{{ $judulGrup }}</span>
                                    <span class="dok-grup-jumlah">{{ $dalamGrup->count() }} persyaratan</span>
                                    <div class="text-muted" style="font-size:12px;margin-top:2px;">{{ [2 => 'Identitas pemohon, legalitas perusahaan, dan keanggotaan asosiasi', 3 => 'Kajian teknis tapak, perizinan tata ruang, dan kepatuhan sarana prasarana kota', 4 => 'Dokumen site plan dan kajian teknis'][$grup] ?? '' }}</div>
                                </div>
                                <span class="badge {{ $sesuaiGrup === $dalamGrup->count() ? 'badge-success' : 'badge-warning' }} badge-dot">{{ $sesuaiGrup }} / {{ $dalamGrup->count() }} Terverifikasi</span>
                            </div>
                        </td></tr>
                    @endif
                    @forelse($files as $f)
                        @php
                            $doc = [
                                'syarat' => "{$code} · {$slot['name']}",
                                'nama' => $f->original_name,
                                'ukuran' => $ukuran($f->size_bytes),
                                'status' => $f->status === 'lolos' ? 'lolos' : ($f->status === 'perlu_perbaikan' ? 'perlu_perbaikan' : 'lolos'),
                                'catatan' => $f->review_note,
                                'lihat' => $f->file_type === 'pdf' ? route('pengajuan.lihat', [$s->id, $f->id]) : null,
                                'unduh' => route('pengajuan.berkas', [$s->id, $f->id]),
                                'nilai' => route('pengajuan.nilai', [$s->id, $f->id]),
                            ];
                        @endphp
                        <tr class="dok-baris{{ $loop->first ? ' dok-awal' : '' }}">
                            @if($loop->first)<td class="col-strong" rowspan="{{ $files->count() }}">{{ $code }} &middot; {{ $slot['name'] }}</td>@endif
                            <td>
                                <span class="mono" style="font-weight:600;">{{ $f->original_name }}</span>
                                <div class="text-muted" style="font-size:12px;">v{{ $f->version }} &middot; {{ $ukuran($f->size_bytes) }}</div>
                            </td>
                            <td>
                                @if($f->status === 'lolos') <span class="badge badge-success badge-dot">Sesuai</span>
                                @elseif($f->status === 'perlu_perbaikan') <span class="badge badge-warning badge-dot">Perlu perbaikan</span>
                                @else <span class="badge badge-dot">Belum diperiksa</span> @endif
                                @if($f->review_note)<div class="text-muted" style="font-size:12px;margin-top:4px;">{{ $f->review_note }}</div>@endif
                            </td>
                            <td class="col-actions">
                                <div style="display:inline-flex;gap:6px;flex-wrap:wrap;justify-content:flex-end;">
                                    @if($doc['lihat'])
                                        <button type="button" class="btn btn-outline btn-sm" data-pratinjau="{{ json_encode($doc) }}">Pratinjau</button>
                                    @endif
                                    <a href="{{ $doc['unduh'] }}" class="btn btn-outline btn-sm" title="Unduh berkas">Unduh</a>
                                    @if($canReview)
                                        <button type="button" class="btn btn-primary btn-sm" data-nilai="{{ json_encode($doc) }}">Nilai</button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr class="dok-baris dok-awal">
                            <td class="col-strong">{{ $code }} &middot; {{ $slot['name'] }}</td>
                            <td colspan="3" class="text-muted">{{ ($slot['required'] ?? true) ? 'Belum diunggah' : 'Opsional, tidak diunggah' }}</td>
                        </tr>
                    @endforelse
                @endforeach
            </tbody>
        </table>
    </div>
</div>

{{-- Pratinjau PDF di halaman (tanpa mengunduh) --}}
<div id="pdfModal" class="modal-backdrop" style="display:none;z-index:110;" role="dialog" aria-modal="true" aria-labelledby="pdfModalTitle">
    <div class="pdf-modal-container">
        <div class="pdf-toolbar">
            <div>
                <div class="modal-title" id="pdfModalTitle" style="font-size:16px;">Pratinjau Berkas</div>
                <div class="modal-sub" id="pdfModalSub"></div>
            </div>
            <div style="display:flex;gap:10px;align-items:center;">
                <a id="pdfModalUnduh" href="#" class="btn btn-outline btn-sm">Unduh</a>
                <button type="button" class="modal-close" data-tutup="pdfModal" aria-label="Tutup" style="font-size:24px;">&times;</button>
            </div>
        </div>
        <iframe id="pdfFrame" title="Pratinjau PDF" style="width:100%;height:76vh;border:0;background:#f8fafc;"></iframe>
    </div>
</div>

{{-- Penilaian satu berkas --}}
<div id="nilaiModal" class="modal-backdrop" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="nilaiTitle">
    <div class="modal">
        <div class="modal-head">
            <div>
                <h3 class="modal-title" id="nilaiTitle">Verifikasi Dokumen</h3>
                <div class="modal-sub">Periksa berkas lalu tentukan statusnya.</div>
            </div>
            <button type="button" class="modal-close" data-tutup="nilaiModal" aria-label="Tutup" style="font-size:24px;">&times;</button>
        </div>
        <form method="POST" id="nilaiForm" action="#">
            @csrf
            <div class="modal-body" style="display:grid;gap:16px;">
                <div>
                    <label class="form-label">Nama Persyaratan</label>
                    <input class="form-input" id="nilaiSyarat" readonly>
                </div>
                <div>
                    <label class="form-label">Berkas Aktif yang Diunggah</label>
                    <div style="display:flex;gap:10px;align-items:center;justify-content:space-between;padding:10px 14px;border:1px solid var(--primary-border);background:var(--primary-tint);border-radius:10px;">
                        <div><div class="mono" id="nilaiNama" style="font-weight:600;font-size:13px;"></div><div class="text-muted" id="nilaiUkuran" style="font-size:12px;"></div></div>
                        <button type="button" class="btn btn-outline btn-sm" id="nilaiLihat">Pratinjau</button>
                    </div>
                </div>
                <div>
                    <label class="form-label" for="nilaiStatus">Status Verifikasi</label>
                    <select class="form-select" name="decision" id="nilaiStatus">
                        <option value="lolos">Sesuai (diterima)</option>
                        <option value="perlu_perbaikan">Perlu perbaikan</option>
                    </select>
                </div>
                <div>
                    <label class="form-label" for="nilaiCatatan">Catatan Evaluasi <span class="text-muted" id="nilaiHint" style="font-weight:400;">(opsional jika sesuai)</span></label>
                    <textarea class="form-textarea" name="catatan" id="nilaiCatatan" rows="3" maxlength="1000"></textarea>
                </div>
            </div>
            <div class="modal-foot">
                <button type="button" class="btn btn-outline" data-tutup="nilaiModal">Batal</button>
                <button type="submit" class="btn btn-primary">Simpan Status Dokumen</button>
            </div>
        </form>
    </div>
</div>

<script>
(function () {
    const $ = (id) => document.getElementById(id);
    const buka = (id) => { $(id).style.display = 'flex'; };
    const tutup = (id) => {
        $(id).style.display = 'none';
        if (id === 'pdfModal') $('pdfFrame').src = 'about:blank'; // hentikan pemuatan PDF
    };

    function pratinjau(doc) {
        $('pdfModalTitle').textContent = doc.syarat;
        $('pdfModalSub').textContent = doc.nama + ' · ' + doc.ukuran;
        $('pdfModalUnduh').href = doc.unduh;
        $('pdfFrame').src = doc.lihat;
        buka('pdfModal');
    }

    function nilai(doc) {
        $('nilaiTitle').textContent = 'Verifikasi ' + doc.syarat.split(' · ').slice(1).join(' · ');
        $('nilaiForm').action = doc.nilai;
        $('nilaiSyarat').value = doc.syarat;
        $('nilaiNama').textContent = doc.nama;
        $('nilaiUkuran').textContent = doc.ukuran;
        $('nilaiStatus').value = doc.status;
        $('nilaiCatatan').value = doc.catatan || '';
        $('nilaiLihat').style.display = doc.lihat ? '' : 'none';
        $('nilaiLihat').onclick = () => pratinjau(doc);
        sinkron();
        buka('nilaiModal');
    }

    // Catatan wajib bila berkas diminta diperbaiki (sama dengan aturan server).
    function sinkron() {
        const perlu = $('nilaiStatus').value === 'perlu_perbaikan';
        $('nilaiCatatan').required = perlu;
        $('nilaiHint').textContent = perlu ? '(wajib diisi)' : '(opsional jika sesuai)';
    }
    $('nilaiStatus').addEventListener('change', sinkron);

    document.querySelectorAll('[data-pratinjau]').forEach(b => b.addEventListener('click', () => pratinjau(JSON.parse(b.dataset.pratinjau))));
    document.querySelectorAll('[data-nilai]').forEach(b => b.addEventListener('click', () => nilai(JSON.parse(b.dataset.nilai))));
    document.querySelectorAll('[data-tutup]').forEach(b => b.addEventListener('click', () => tutup(b.dataset.tutup)));
    ['pdfModal', 'nilaiModal'].forEach(id => $(id).addEventListener('click', (e) => { if (e.target === $(id)) tutup(id); }));
    document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape') return;
        // Pratinjau (yang bisa dibuka dari jendela nilai) ditutup lebih dulu.
        ['pdfModal', 'nilaiModal'].forEach(id => { if ($(id).style.display !== 'none') { tutup(id); } });
    });
})();
</script>

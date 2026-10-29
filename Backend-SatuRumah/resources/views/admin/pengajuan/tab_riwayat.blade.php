@php
    // Jenis kejadian -> warna bulatan, ikon, dan label kategori.
    $jenis = function ($e) {
        $reviewed = $e->type === 'file_reviewed';
        $ditolak = $e->type === 'decided' && str_contains($e->title, 'ditolak');
        return match (true) {
            $reviewed && ($e->meta['decision'] ?? null) === 'perlu_perbaikan', $e->type === 'revision_requested' => ['warn', 'Perlu Perbaikan', 'M12 9v4m0 4h.01M10.3 3.9L2.4 18a2 2 0 001.7 3h15.8a2 2 0 001.7-3L13.7 3.9a2 2 0 00-3.4 0z'],
            $ditolak => ['bad', 'Ditolak', 'M6 6l12 12M18 6L6 18'],
            $reviewed => ['ok', 'Dokumen Sesuai', 'M5 13l4 4L19 7'],
            $e->type === 'decided' => ['ok', 'Disetujui', 'M5 13l4 4L19 7'],
            $e->type === 'stage_advanced' => ['ok', 'Tahap Lanjut', 'M13 5l7 7-7 7M5 12h14'],
            in_array($e->type, ['survey_scheduled', 'survey_rescheduled'], true) => ['info', 'Survei', 'M8 7V3m8 4V3M4 11h16M5 5h14a1 1 0 011 1v14a1 1 0 01-1 1H5a1 1 0 01-1-1V6a1 1 0 011-1z'],
            $e->type === 'report_submitted' => ['info', 'Laporan Survei', 'M9 12h6m-6 4h6M7 3h7l5 5v13H7z'],
            $e->type === 'resubmitted' => ['info', 'Perbaikan Dikirim', 'M4 4v6h6M20 20v-6h-6M20 10A8 8 0 006 6M4 14a8 8 0 0014 4'],
            default => ['muted', 'Registrasi Awal', 'M5 21V4m0 0h11l-2 4 2 4H5'],
        };
    };
    $filter = [
        'semua' => 'Semua',
        'perbaikan' => 'Perbaikan',
        'dokumen' => 'Dokumen',
        'survei' => 'Survei',
    ];
@endphp

<div class="card" style="box-shadow:none;">
    <div class="card-head bordered">
        <div>
            <h2 class="card-title" style="font-size:16px;">Riwayat Aktivitas &amp; Jejak Audit</h2>
            <div class="card-sub">Setiap tindakan terhadap pengajuan ini tercatat permanen: siapa, kapan, dan apa catatannya.</div>
        </div>
        <div class="seg" id="riwayatFilter" role="tablist">
            @foreach($filter as $k => $v)
                <button type="button" class="seg-btn {{ $loop->first ? 'is-active' : '' }}" data-filter="{{ $k }}">{{ $v }}</button>
            @endforeach
        </div>
    </div>
    <div class="card-body">
        <div class="timeline">
            @forelse($s->events as $e)
                @php
                    [$warna, $label, $ikon] = $jenis($e);
                    $grup = match (true) {
                        $warna === 'warn' => 'perbaikan dokumen',
                        $e->type === 'file_reviewed' => 'dokumen',
                        str_contains($e->type, 'survey') || $e->type === 'report_submitted' => 'survei',
                        default => '',
                    };
                    $slot = $e->meta['slot'] ?? null;
                @endphp
                <div class="tl-item" data-grup="{{ $grup }}">
                    <span class="tl-dot {{ $warna }}">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="{{ $ikon }}"/></svg>
                    </span>
                    <div class="tl-card {{ $warna === 'warn' || $warna === 'bad' ? 'warn' : '' }}">
                        <div class="tl-head">
                            <span>{{ $e->created_at?->translatedFormat('d F Y') }} &middot; {{ $e->created_at?->format('H.i') }} WIB</span>
                            <span class="tl-tag {{ $warna }}">{{ $label }}</span>
                        </div>
                        <div class="tl-title">{{ $e->title }}</div>
                        @if($e->description)
                            @if($warna === 'warn' && $e->type === 'file_reviewed')
                                <div class="tl-note"><strong>Catatan evaluasi verifikator</strong>{{ $e->description }}@if($slot)<div class="mono">{{ $slot }}</div>@endif</div>
                            @else
                                <div class="text-muted" style="font-size:13px;">{{ $e->description }}</div>
                            @endif
                        @endif
                        <div class="tl-by">{{ $e->actor ? 'Dilakukan oleh ' : 'Sistem' }}<strong>{{ $e->actor?->name }}</strong>@if($e->actor) &middot; {{ ['admin' => 'Admin', 'pengembang' => 'Pengembang', 'tim_lapangan' => 'Petugas lapangan'][$e->actor->role] ?? $e->actor->role }}@endif</div>
                    </div>
                </div>
            @empty
                <div class="text-muted">Belum ada aktivitas tercatat.</div>
            @endforelse
        </div>
    </div>
</div>

<script>
(function () {
    const tombol = document.querySelectorAll('#riwayatFilter [data-filter]');
    tombol.forEach(b => b.addEventListener('click', () => {
        tombol.forEach(x => x.classList.toggle('is-active', x === b));
        document.querySelectorAll('.tl-item').forEach(i => {
            i.style.display = b.dataset.filter === 'semua' || i.dataset.grup.split(' ').includes(b.dataset.filter) ? '' : 'none';
        });
    }));
})();
</script>

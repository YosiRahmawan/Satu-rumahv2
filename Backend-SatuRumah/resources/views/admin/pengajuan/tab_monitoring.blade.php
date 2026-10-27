@php
    $canSchedule = in_array($s->stage, [\App\Models\Submission::STAGE_TEKNIS, \App\Models\Submission::STAGE_SURVEI], true) && !$s->isInRevision();
    $openAssignment = $s->assignments->first(fn ($a) => $a->isOpen());
    $finalReport = $s->reports->firstWhere('status', 'final');
@endphp

@if($canSchedule)
<div class="card" style="box-shadow:none;margin-bottom:20px;">
    <div class="card-head bordered">
        <div class="card-title" style="font-size:16px;">{{ $openAssignment ? 'Ubah Jadwal / Alihkan Petugas' : 'Jadwalkan Survei' }}</div>
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
            <div><button class="btn btn-primary">{{ $openAssignment ? 'Simpan Perubahan' : 'Jadwalkan' }}</button></div>
        </form>
    </div>
</div>
@endif

<div class="card" style="box-shadow:none;margin-bottom:20px;">
    <div class="card-head bordered"><div class="card-title" style="font-size:16px;">Penugasan</div></div>
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
        <div class="card-title" style="font-size:16px;">Laporan Survei (BA)</div>
        @if($s->stage === \App\Models\Submission::STAGE_SURVEI && !$s->isInRevision())
            <form method="POST" action="{{ route('pengajuan.terima_laporan', $s->id) }}" onsubmit="return confirm('Terima laporan dan lanjut ke persetujuan?')">
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
                            <a href="{{ route('pengajuan.foto', [$s->id, $ph->id]) }}" target="_blank" title="{{ $ph->address }}">
                                <img src="{{ route('pengajuan.foto', [$s->id, $ph->id]) }}" alt="Foto {{ $ph->position }}" loading="lazy" style="width:150px;height:110px;object-fit:cover;border-radius:8px;border:1px solid var(--border);">
                            </a>
                        @endforeach
                    </div>
                @endif
            </div>
        @empty
            <div class="text-muted">Belum ada laporan final dari petugas.</div>
        @endforelse
    </div>
</div>

@php $openAssignment = $openAssignment ?? $s->assignments->first(fn ($a) => $a->isOpen()); @endphp
<form method="POST" action="{{ route('pengajuan.jadwal', $s->id) }}" class="{{ ($kompak ?? false) ? '' : 'grid-2' }}" style="{{ ($kompak ?? false) ? 'display:grid;gap:12px;' : '' }}">
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
    <div class="form-group" style="{{ ($kompak ?? false) ? '' : 'grid-column:1/-1;' }}">
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
    <div style="{{ ($kompak ?? false) ? '' : 'grid-column:1/-1;' }}display:flex;justify-content:flex-end;"><button class="btn btn-primary">{{ $openAssignment ? 'Simpan Perubahan' : 'Jadwalkan' }}</button></div>
</form>

@extends('layouts.portal')

@section('title', 'Pengaturan - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs">Portal Admin &nbsp;&gt;&nbsp; <b>Pengaturan</b></div>
        <div class="hero-title">Pengaturan</div>
        <div class="hero-sub">Batas waktu, tenggat perbaikan, target dashboard, dan batas unggah. Berlaku untuk proses berikutnya.</div>
    </div>
</div>

<div class="callout">Angka batas waktu (SLA) masih usulan awal dan menunggu penetapan resmi Disperwaskim. Hari libur nasional belum dihitung.</div>

<form method="POST" action="{{ route('pengaturan.update') }}" style="display:grid;gap:20px;">
    @csrf
    @foreach($groups as $judul => $fields)
        <div class="card">
            <div class="card-head bordered"><div class="card-title" style="font-size:16px;">{{ $judul }}</div></div>
            <div class="card-body" style="display:grid;gap:14px;">
                @foreach($fields as $key => $f)
                    @php $name = str_replace('.', '_', $key); @endphp
                    <div style="display:grid;grid-template-columns:minmax(0,1fr) 150px 130px;gap:12px;align-items:center;">
                        <label class="form-label" for="{{ $name }}" style="margin:0;">{{ $f['label'] }}</label>
                        <input class="form-input" type="number" id="{{ $name }}" name="nilai[{{ $name }}]" min="{{ $f['min'] }}" max="{{ $f['max'] }}" value="{{ old('nilai.' . $name, $nilai[$key]) }}" required>
                        <span class="text-muted" style="font-size:13px;">{{ $f['unit'] }}</span>
                        @error('nilai.' . $name)<div class="text-primary" style="grid-column:1/-1;font-size:12px;">{{ $message }}</div>@enderror
                    </div>
                @endforeach
            </div>
        </div>
    @endforeach
    <div style="display:flex;justify-content:flex-end;"><button class="btn btn-primary">Simpan Pengaturan</button></div>
</form>
@endsection

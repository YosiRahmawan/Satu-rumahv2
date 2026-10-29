@extends('layouts.portal')

@section('title', 'Ganti Sandi - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs"><b>Akun</b></div>
        <div class="hero-title">Ganti Sandi</div>
        <div class="hero-sub">{{ auth()->user()->must_change_password ? 'Sandi Anda masih sementara. Ganti dulu sebelum memakai portal.' : 'Gunakan sandi yang kuat dan tidak dipakai di tempat lain.' }}</div>
    </div>
</div>

<div class="card" style="max-width:560px;">
    <div class="card-body">
        <form method="POST" action="{{ route('sandi.simpan') }}" style="display:grid;gap:16px;">
            @csrf
            <div>
                <label class="form-label" for="current_password">Sandi saat ini</label>
                <div class="pw-wrap"><input class="form-input" type="password" id="current_password" name="current_password" autocomplete="current-password" required><button type="button" class="pw-toggle" aria-label="Tampilkan atau sembunyikan sandi"><svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg></button></div>
                @error('current_password')<div class="text-primary" style="font-size:12px;margin-top:4px;">{{ $message }}</div>@enderror
            </div>
            <div>
                <label class="form-label" for="new_password">Sandi baru</label>
                <div class="pw-wrap"><input class="form-input" type="password" id="new_password" name="new_password" autocomplete="new-password" required><button type="button" class="pw-toggle" aria-label="Tampilkan atau sembunyikan sandi"><svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg></button></div>
                <div class="text-muted" style="font-size:12px;margin-top:4px;">Minimal 10 karakter, kombinasi huruf besar, huruf kecil, dan angka.</div>
                @error('new_password')<div class="text-primary" style="font-size:12px;margin-top:4px;">{{ $message }}</div>@enderror
            </div>
            <div>
                <label class="form-label" for="new_password_confirmation">Ulangi sandi baru</label>
                <div class="pw-wrap"><input class="form-input" type="password" id="new_password_confirmation" name="new_password_confirmation" autocomplete="new-password" required><button type="button" class="pw-toggle" aria-label="Tampilkan atau sembunyikan sandi"><svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg></button></div>
            </div>
            <div style="display:flex;justify-content:flex-end;"><button class="btn btn-primary">Simpan Sandi</button></div>
        </form>
    </div>
</div>
@endsection

@section('scripts')
<script>
    const EYE = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>';
    const EYE_OFF = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3l18 18M10.6 10.6a3 3 0 004.2 4.2M9.9 5.1A9.8 9.8 0 0112 5c4.5 0 8.3 2.9 9.5 7a10 10 0 01-2.6 4.2M6.2 6.2A10 10 0 002.5 12c1.2 4.1 5 7 9.5 7a9.700 9.700 0 003.8-.8"/>';
    document.querySelectorAll('.pw-toggle').forEach(b => b.addEventListener('click', () => {
        const input = b.parentElement.querySelector('input');
        const tampil = input.type === 'password';
        input.type = tampil ? 'text' : 'password';
        b.querySelector('svg').innerHTML = tampil ? EYE_OFF : EYE;
    }));
</script>
@endsection

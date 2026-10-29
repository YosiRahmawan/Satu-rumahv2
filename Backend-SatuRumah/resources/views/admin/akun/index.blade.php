@extends('layouts.portal')

@section('title', 'Akun - SATU RUMAH')

@section('content')
<div class="hero">
    <div>
        <div class="hero-crumbs">Portal Admin &nbsp;&gt;&nbsp; <b>Akun</b></div>
        <div class="hero-title">Manajemen Akun</div>
        <div class="hero-sub">Akun bersifat tertutup. Admin membuat akun dan mereset sandi bila ada yang lupa.</div>
    </div>
    <button type="button" class="btn btn-white" id="akunTambah">Tambah Akun</button>
</div>

@if(session('sandi_sementara'))
    @php $sm = session('sandi_sementara'); @endphp
    <div class="alert alert-warning" style="align-items:center;">
        <div style="flex:1;">
            <div class="alert-title">Sandi sementara untuk {{ $sm['nama'] }} ({{ $sm['email'] }})</div>
            <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;margin-top:6px;">
                <code class="mono" id="sandiSementara" style="font-size:16px;font-weight:700;">{{ $sm['sandi'] }}</code>
                <button type="button" class="btn btn-outline btn-sm" id="sandiSalin">Salin</button>
            </div>
            <div style="font-size:12px;margin-top:6px;">Sandi ini hanya tampil sekali. Berikan langsung ke pemilik akun; ia wajib menggantinya saat masuk pertama.</div>
        </div>
    </div>
@endif

<div class="card">
    <div class="card-head bordered">
        <form method="GET" style="display:flex;gap:10px;flex-wrap:wrap;width:100%;">
            <input class="form-input" name="search" value="{{ request('search') }}" placeholder="Cari nama, email, atau username" style="max-width:320px;">
            <select class="form-select" name="role" style="max-width:200px;" onchange="this.form.submit()">
                <option value="">Semua role</option>
                @foreach($roles as $k => $v)<option value="{{ $k }}" @selected(request('role') === $k)>{{ $v }}</option>@endforeach
            </select>
            <button class="btn btn-outline">Cari</button>
        </form>
    </div>
    <div class="table-wrap">
        <table class="table">
            <thead><tr><th>Nama</th><th>Email / Username</th><th>Role</th><th>Status</th><th class="col-actions">Aksi</th></tr></thead>
            <tbody>
                @forelse($users as $u)
                    <tr>
                        <td class="col-strong">{{ $u->name }}@if($u->jabatan)<div class="text-muted" style="font-size:12px;font-weight:400;">{{ $u->jabatan }}</div>@endif</td>
                        <td>{{ $u->email }}<div class="text-muted" style="font-size:12px;">{{ $u->username }}</div></td>
                        <td>{{ $roles[$u->role] ?? $u->role }}</td>
                        <td>
                            <span class="badge {{ $u->is_active ? 'badge-success' : '' }} badge-dot">{{ $u->is_active ? 'Aktif' : 'Nonaktif' }}</span>
                            @if($u->must_change_password)<div class="text-muted" style="font-size:12px;margin-top:4px;">Sandi sementara</div>@endif
                        </td>
                        <td class="col-actions">
                            @if($u->id === auth()->id())
                                <span class="text-muted" style="font-size:12px;">Akun Anda</span>
                            @else
                                <div style="display:inline-flex;gap:6px;flex-wrap:wrap;justify-content:flex-end;">
                                    <form method="POST" action="{{ route('akun.reset', $u->id) }}" data-konfirmasi="Sandi {{ $u->name }} akan diganti sandi sementara dan semua sesi aplikasinya keluar. Lanjutkan?" data-konfirmasi-judul="Reset Sandi" data-konfirmasi-tombol="Ya, reset">
                                        @csrf <button class="btn btn-outline btn-sm">Reset sandi</button>
                                    </form>
                                    <form method="POST" action="{{ route('akun.status', $u->id) }}" data-konfirmasi="{{ $u->is_active ? $u->name . ' tidak akan bisa masuk sampai diaktifkan lagi.' : $u->name . ' akan bisa masuk kembali.' }}" data-konfirmasi-judul="{{ $u->is_active ? 'Nonaktifkan Akun' : 'Aktifkan Akun' }}" data-konfirmasi-tombol="{{ $u->is_active ? 'Ya, nonaktifkan' : 'Ya, aktifkan' }}">
                                        @csrf <button class="btn btn-outline btn-sm">{{ $u->is_active ? 'Nonaktifkan' : 'Aktifkan' }}</button>
                                    </form>
                                </div>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="text-muted" style="text-align:center;padding:24px;">Tidak ada akun.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    @if($users->hasPages())<div class="card-foot">{{ $users->links() }}</div>@endif
</div>

<div id="akunModal" class="modal-backdrop" style="display:{{ $errors->any() ? 'flex' : 'none' }};" role="dialog" aria-modal="true" aria-labelledby="akunJudul">
    <div class="modal" style="max-width:520px;">
        <div class="modal-head">
            <div>
                <h3 class="modal-title" id="akunJudul">Tambah Akun</h3>
                <div class="modal-sub">Sandi sementara dibuat otomatis dan ditampilkan sekali setelah disimpan.</div>
            </div>
            <button type="button" class="modal-close" id="akunTutup" aria-label="Tutup" style="font-size:24px;">&times;</button>
        </div>
        <form method="POST" action="{{ route('akun.store') }}">
            @csrf
            <div class="modal-body" style="display:grid;gap:14px;">
                @if($errors->any())<div class="alert alert-danger" style="margin:0;"><div>{{ $errors->first() }}</div></div>@endif
                <div><label class="form-label">Nama lengkap</label><input class="form-input" name="name" value="{{ old('name') }}" required></div>
                <div><label class="form-label">Email (email asli milik orangnya)</label><input class="form-input" type="email" name="email" value="{{ old('email') }}" required></div>
                <div><label class="form-label">Username</label><input class="form-input" name="username" value="{{ old('username') }}" required><div class="text-muted" style="font-size:12px;margin-top:4px;">Huruf, angka, garis bawah. Dipakai untuk masuk di aplikasi HP.</div></div>
                <div class="grid-2">
                    <div><label class="form-label">Role</label>
                        <select class="form-select" name="role" required>
                            @foreach($roles as $k => $v)<option value="{{ $k }}" @selected(old('role') === $k)>{{ $v }}</option>@endforeach
                        </select>
                    </div>
                    <div><label class="form-label">Jabatan (opsional)</label><input class="form-input" name="jabatan" value="{{ old('jabatan') }}"></div>
                </div>
            </div>
            <div class="modal-foot">
                <button type="button" class="btn btn-outline" id="akunBatal">Batal</button>
                <button type="submit" class="btn btn-primary">Buat Akun</button>
            </div>
        </form>
    </div>
</div>
@endsection

@section('scripts')
<script>
(function () {
    const m = document.getElementById('akunModal');
    const tutup = () => { m.style.display = 'none'; };
    document.getElementById('akunTambah').addEventListener('click', () => { m.style.display = 'flex'; });
    document.getElementById('akunTutup').addEventListener('click', tutup);
    document.getElementById('akunBatal').addEventListener('click', tutup);
    m.addEventListener('click', (e) => { if (e.target === m) tutup(); });
    const salin = document.getElementById('sandiSalin');
    if (salin) salin.addEventListener('click', async () => {
        try { await navigator.clipboard.writeText(document.getElementById('sandiSementara').textContent.trim()); salin.textContent = 'Tersalin'; } catch (e) { /* salin manual */ }
    });
})();
</script>
@endsection

<!DOCTYPE html>
<html lang="id">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - SATU RUMAH Portal Verifikator Disperwaskim</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap"
        rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="{{ asset('favicon.svg') }}">
    <link rel="stylesheet" href="{{ asset('css/portal.css') }}">
</head>

<body>
    <div class="login-shell">
        <div class="login-aside">
            <div class="login-brand">
                <div class="login-brand-icon">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M3 10.5L12 3l9 7.5" stroke="#ffffff" stroke-width="2" stroke-linecap="round"
                            stroke-linejoin="round" />
                        <path d="M5 9.5V20a1 1 0 001 1h3v-6h6v6h3a1 1 0 001-1V9.5" stroke="#ffffff" stroke-width="2"
                            stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                </div>
                <div>
                    <div class="login-brand-title">SATU RUMAH</div>
                    <div class="login-brand-sub">Portal Verifikator Disperwaskim</div>
                </div>
            </div>

            <div>
                <h1 class="login-headline">Sistem Informasi Tata Ruang &amp; Verifikasi Site Plan Perumahan</h1>
                <p class="login-lead">Sentralisasi verifikasi berkas teknis, disposisi jadwal survey tim Perwaskim, dan
                    penerbitan rekomendasi Berita Acara secara digital, akuntabel, dan transparan.</p>
            </div>

            <div class="login-address">
                Dinas Perumahan Rakyat dan Kawasan Permukiman Kota Tasikmalaya
                <small>Jl. Ir. H. Juanda No. 191, Tasikmalaya, Jawa Barat</small>
            </div>
        </div>

        <div class="login-panel">
            <div class="login-form">
                <h2>Selamat Datang di Konsol Verifikasi</h2>
                <p class="lead">Silakan masuk menggunakan akun kedinasan untuk mengakses antrean berkas dan penugasan
                    survey.</p>   

                @if($errors->any())
                    <div class="alert alert-danger" style="margin-bottom: 20px;">
                        {{ $errors->first() }}
                    </div>
                @endif

                <form action="{{ route('login') }}" method="POST">
                    @csrf
                    <div class="field">
                        <label class="label">Email Dinas</label>
                        <div class="input-icon">
                            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M3 8l9 6 9-6M5 5h14a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2z" />
                            </svg>
                            <input type="email" name="email" class="input" required autofocus
                                placeholder="admin@saturumah.go.id">
                        </div>
                    </div>

                    <div class="field">
                        <label class="label">Kata Sandi</label>
                        <div class="input-icon">
                            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M7 11V8a5 5 0 0110 0v3M6 11h12a1 1 0 011 1v8a1 1 0 01-1 1H6a1 1 0 01-1-1v-8a1 1 0 011-1z" />
                            </svg>
                            <input type="password" name="password" id="password" class="input" required
                                placeholder="••••••••">
                            <button type="button" class="toggle-visibility" onclick="togglePw()" aria-label="Tampilkan atau sembunyikan sandi">
                                <svg id="pwIkon" width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                </svg>
                            </button>
                        </div>
                    </div>

                    <div class="login-row">
                        <label class="check">
                            <input type="checkbox" name="remember" checked>
                            Ingat sesi login ini
                        </label>
                        <a href="#" id="bantuanBuka">Bantuan Akses?</a>
                    </div>

                    <button type="submit" class="btn btn-primary btn-block">Masuk</button>
                </form>
            </div>
        </div>
    </div>

    <div id="bantuanModal" class="modal-backdrop" style="display:none;" role="dialog" aria-modal="true" aria-labelledby="bantuanJudul">
        <div class="modal" style="max-width:460px;">
            <div class="modal-head">
                <h3 class="modal-title" id="bantuanJudul">Bantuan Akses</h3>
                <button type="button" class="modal-close" id="bantuanTutup" aria-label="Tutup" style="font-size:24px;">&times;</button>
            </div>
            <div class="modal-body" style="display:grid;gap:14px;font-size:14px;">
                <div><strong>Lupa sandi</strong><br>Minta admin lain membuka menu Akun lalu memilih Reset sandi untuk akun Anda. Anda akan menerima sandi sementara dan diminta membuat sandi baru saat masuk. Bila tidak ada admin lain yang bisa masuk, minta petugas IT menjalankan perintah darurat <code>akun:reset-sandi</code> di server.</div>
                <div><strong>Muncul "Terlalu banyak percobaan masuk"</strong><br>Akun dikunci sementara demi keamanan. Tunggu satu menit, lalu coba lagi.</div>
                <div><strong>Belum punya akun</strong><br>Akun dibuat oleh admin lewat menu Akun, tidak ada pendaftaran mandiri.</div>
                <div><strong>Pengembang dan petugas lapangan</strong><br>Portal ini hanya untuk admin Disperwaskim. Gunakan aplikasi SATU RUMAH di HP.</div>
            </div>
            <div class="modal-foot"><button type="button" class="btn btn-primary" id="bantuanOk">Mengerti</button></div>
        </div>
    </div>

    <script>
        const EYE = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>';
        const EYE_OFF = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3l18 18M10.6 10.6a3 3 0 004.2 4.2M9.9 5.1A9.8 9.8 0 0112 5c4.5 0 8.3 2.9 9.5 7a10 10 0 01-2.6 4.2M6.2 6.2A10 10 0 002.5 12c1.2 4.1 5 7 9.5 7a9.700 9.700 0 003.8-.8"/>';
        function togglePw() {
            const input = document.getElementById('password');
            const tampil = input.type === 'password';
            input.type = tampil ? 'text' : 'password';
            document.getElementById('pwIkon').innerHTML = tampil ? EYE_OFF : EYE;
        }
        (function () {
            const m = document.getElementById('bantuanModal');
            const tutup = () => { m.style.display = 'none'; };
            document.getElementById('bantuanBuka').addEventListener('click', (e) => { e.preventDefault(); m.style.display = 'flex'; });
            document.getElementById('bantuanTutup').addEventListener('click', tutup);
            document.getElementById('bantuanOk').addEventListener('click', tutup);
            m.addEventListener('click', (e) => { if (e.target === m) tutup(); });
            document.addEventListener('keydown', (e) => { if (e.key === 'Escape') tutup(); });
        })();
    </script>
</body>

</html>

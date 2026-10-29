<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'SATU RUMAH - Portal Verifikator Disperwaskim')</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="{{ asset('favicon.svg') }}">
    <link rel="stylesheet" href="{{ asset('css/portal.css') }}">
    @yield('styles')
</head>
<body>
    <div class="app-shell">
        <aside class="sidebar">
            <div class="sidebar-brand">
                <div class="sidebar-brand-icon">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M3 10.5L12 3l9 7.5" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M5 9.5V20a1 1 0 001 1h3v-6h6v6h3a1 1 0 001-1V9.5" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
                <div>
                    <div class="sidebar-brand-title">SATU RUMAH</div>
                    <div class="sidebar-brand-sub">Disperwaskim Kota Tasikmalaya</div>
                </div>
            </div>

            <div class="sidebar-label">Menu Utama</div>
            <nav class="sidebar-nav">
                <a href="{{ route('dashboard') }}" class="nav-link {{ request()->routeIs('dashboard') ? 'active' : '' }}">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
                    </svg>
                    Dashboard
                </a>
                <a href="{{ route('pengajuan.index') }}" class="nav-link {{ request()->routeIs('pengajuan.*') ? 'active' : '' }}">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                    </svg>
                    Antrean Pengajuan
                    @if(isset($antreanCount) && $antreanCount > 0)
                        <span class="nav-count">{{ $antreanCount }}</span>
                    @endif
                </a>
                <a href="{{ route('akun.index') }}" class="nav-link {{ request()->routeIs('akun.*') ? 'active' : '' }}">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a4 4 0 00-3-3.9M9 11a4 4 0 100-8 4 4 0 000 8zM2 20v-1a5 5 0 015-5h4a5 5 0 015 5v1M16 3.1a4 4 0 010 7.8"></path>
                    </svg>
                    Akun
                </a>
            </nav>

            <div class="sidebar-user">
                <div class="avatar avatar-sm">{{ mb_strtoupper(mb_substr(auth()->user()->name ?? 'V', 0, 2)) }}</div>
                <div>
                    <div class="sidebar-user-name">{{ auth()->user()->name ?? 'Verifikator Disperwaskim' }}</div>
                    <div class="sidebar-user-role">{{ ucfirst(auth()->user()->role) }}</div>
                </div>
                <a href="{{ route('sandi.ubah') }}" class="logout-btn" title="Ganti sandi" style="display:flex;align-items:center;">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a4 4 0 11-3.9 4.9L4 19v2h3v-2h2v-2h2l1.6-1.6A4 4 0 0115 7z"></path></svg>
                </a>
                <form action="{{ route('logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="logout-btn" title="Keluar">
                        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
                        </svg>
                    </button>
                </form>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <div class="topbar-left">
                    <span class="topbar-tag">Kota Tasikmalaya</span>
                    <span class="topbar-title">Dinas Perumahan Rakyat dan Kawasan Permukiman</span>
                </div>
                <div class="topbar-right">
                    <a href="{{ route('notifikasi.index') }}" class="icon-btn" title="Notifikasi">
                        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path>
                        </svg>
                        @if(isset($unreadCount) && $unreadCount > 0)
                            <span class="dot"></span>
                        @endif
                    </a>
                    <div class="user-pill">
                        <div class="avatar avatar-sm">{{ mb_strtoupper(mb_substr(auth()->user()->name ?? 'V', 0, 2)) }}</div>
                        <span>{{ auth()->user()->name ?? 'Verifikator Disperwaskim' }}</span>
                    </div>
                </div>
            </header>

            @if(session('success'))
                <div class="alert alert-success" style="margin: 20px 28px 0;">
                    <span>{{ session('success') }}</span>
                    <button class="alert-close" onclick="this.parentElement.remove()">&times;</button>
                </div>
            @endif
            @if(session('warning'))
                <div class="alert alert-warning" style="margin: 20px 28px 0;">
                    <span>{{ session('warning') }}</span>
                    <button class="alert-close" onclick="this.parentElement.remove()">&times;</button>
                </div>
            @endif

            <main class="content">
                @yield('content')
            </main>
        </div>
    </div>

    <div id="konfirmModal" class="modal-backdrop" style="display:none;z-index:120;" role="alertdialog" aria-modal="true" aria-labelledby="konfirmJudul">
        <div class="modal" style="max-width:440px;">
            <div class="modal-head">
                <h3 class="modal-title" id="konfirmJudul">Konfirmasi</h3>
            </div>
            <div class="modal-body"><p id="konfirmIsi" style="margin:0;font-size:14px;"></p></div>
            <div class="modal-foot">
                <button type="button" class="btn btn-outline" id="konfirmBatal">Batal</button>
                <button type="button" class="btn btn-primary" id="konfirmYa">Ya</button>
            </div>
        </div>
    </div>
    <script>
    (function () {
        const m = document.getElementById('konfirmModal');
        let form = null;
        const tutup = () => { m.style.display = 'none'; form = null; };
        document.addEventListener('submit', (e) => {
            const f = e.target;
            if (!f.dataset || !f.dataset.konfirmasi || f.dataset.sudah) return;
            e.preventDefault();
            form = f;
            document.getElementById('konfirmJudul').textContent = f.dataset.konfirmasiJudul || 'Konfirmasi';
            document.getElementById('konfirmIsi').textContent = f.dataset.konfirmasi;
            document.getElementById('konfirmYa').textContent = f.dataset.konfirmasiTombol || 'Ya, lanjutkan';
            m.style.display = 'flex';
            document.getElementById('konfirmYa').focus();
        }, true);
        document.getElementById('konfirmYa').addEventListener('click', () => {
            const f = form;
            tutup();
            if (!f) return;
            f.dataset.sudah = '1'; // lewati penjaga pada pengiriman berikutnya
            f.requestSubmit();
        });
        document.getElementById('konfirmBatal').addEventListener('click', tutup);
        m.addEventListener('click', (e) => { if (e.target === m) tutup(); });
        document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && m.style.display !== 'none') tutup(); });
    })();
    </script>

    @yield('scripts')
</body>
</html>

<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<style>
    @page { margin: 36px 42px 48px; }
    body { font-family: 'DejaVu Sans', sans-serif; font-size: 10.5px; color: #111; line-height: 1.5; }
    h1 { font-size: 14px; text-align: center; margin: 0 0 2px; }
    .sub { text-align: center; margin-bottom: 10px; }
    .kop { text-align: center; border-bottom: 2px solid #111; padding-bottom: 6px; margin-bottom: 12px; font-size: 11px; }
    .tandai { border: 1px solid #b91c1c; color: #b91c1c; padding: 4px 8px; text-align: center; font-weight: bold; margin-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; }
    .meta td { padding: 2px 4px; vertical-align: top; }
    .meta td:first-child { width: 120px; }
    h2 { font-size: 11px; margin: 12px 0 4px; text-transform: uppercase; }
    ol { margin: 0; padding-left: 18px; }
    .tbl th, .tbl td { border: 1px solid #555; padding: 3px 5px; text-align: left; }
    .ttd { margin-top: 18px; }
    .ttd td { width: 50%; text-align: center; vertical-align: top; padding: 0 8px; }
    .ttd .belum { height: 60px; color: #888; padding-top: 22px; }
    .foto td { width: 33%; padding: 3px; vertical-align: top; font-size: 9px; }
    .foto img { width: 100%; }
    .verif { margin-top: 14px; border-top: 1px solid #999; padding-top: 6px; }
    .verif td { vertical-align: middle; }
    .kecil { font-size: 8.5px; color: #444; word-break: break-all; }
</style>
</head>
<body>
    <div class="kop">
        <strong>PEMERINTAH KOTA TASIKMALAYA</strong><br>
        DINAS PERUMAHAN RAKYAT DAN KAWASAN PERMUKIMAN<br>
        Jl. Ir. H. Juanda No. 191, Tasikmalaya
    </div>

    @unless($resmi)
        <div class="tandai">TEMPLATE SEMENTARA &mdash; BELUM FORMAT RESMI DISPERWASKIM. Persetujuan elektronik berbasis akun, bukan TTE tersertifikasi.</div>
    @endunless

    <h1>BERITA ACARA MONITORING / SURVEI LAPANGAN</h1>
    <div class="sub">Nomor: {{ $r->report_number }}</div>

    <table class="meta">
        <tr><td>Tanggal</td><td>: {{ $r->monitoring_date?->translatedFormat('d F Y') }}</td></tr>
        <tr><td>Perumahan</td><td>: {{ $r->nama_perumahan }}</td></tr>
        <tr><td>Lokasi</td><td>: {{ $r->lokasi }}</td></tr>
        <tr><td>No. Pengajuan</td><td>: {{ $r->submission?->number }}</td></tr>
        <tr><td>Hasil evaluasi</td><td>: {{ ['sesuaiSiteplan' => 'Sesuai site plan', 'tidakSesuaiSiteplan' => 'Tidak sesuai site plan', 'perluEvaluasiLanjutan' => 'Perlu evaluasi lanjutan'][$r->status_hasil_evaluasi] ?? $r->status_hasil_evaluasi }}</td></tr>
    </table>

    <h2>Maksud dan Tujuan</h2>
    <div>{{ $r->maksud_tujuan }}</div>

    @foreach(['temuan' => 'Temuan Lapangan', 'kesimpulan' => 'Kesimpulan', 'kesepakatan' => 'Kesepakatan', 'rtl' => 'Rencana Tindak Lanjut'] as $k => $judul)
        @if(!empty($r->{$k}))
            <h2>{{ $judul }}</h2>
            <ol>@foreach($r->{$k} as $baris)<li>{{ $baris }}</li>@endforeach</ol>
        @endif
    @endforeach

    <h2>Tim Pelaksana</h2>
    <table class="tbl">
        <tr><th>No</th><th>Nama</th><th>Jabatan</th></tr>
        @foreach(($r->tim_pelaksana ?? []) as $i => $m)
            <tr><td>{{ $i + 1 }}</td><td>{{ $m['nama'] ?? '' }}</td><td>{{ $m['jabatan'] ?? '' }}</td></tr>
        @endforeach
    </table>

    @if(!empty($r->pihak_ditemui))
        <h2>Pihak yang Ditemui</h2>
        <table class="tbl">
            <tr><th>No</th><th>Nama</th><th>Jabatan</th></tr>
            @foreach($r->pihak_ditemui as $i => $m)
                <tr><td>{{ $i + 1 }}</td><td>{{ $m['nama'] ?? '' }}</td><td>{{ $m['jabatan'] ?? '' }}</td></tr>
            @endforeach
        </table>
    @endif

    @if(!empty($foto))
        <h2>Dokumentasi Foto</h2>
        <table class="foto">
            @foreach(array_chunk($foto, 3) as $baris)
                <tr>@foreach($baris as $f)<td>@if($f['uri'])<img src="{{ $f['uri'] }}">@endif<div>Foto {{ $f['posisi'] }}@if($f['catatan']) &mdash; {{ $f['catatan'] }}@endif</div></td>@endforeach</tr>
            @endforeach
        </table>
    @endif

    <table class="ttd">
        <tr>
            <td>Ketua Pengawas Lapangan<br>
                @if($ketua)<img src="{{ $ketua['img'] }}" width="{{ $ketua['w'] }}" height="{{ $ketua['h'] }}"><br><strong>{{ $ketua['sig']->signer?->name }}</strong><br>{{ $ketua['sig']->signer?->jabatan }}<br>@if($ketua['sig']->signer?->nip)NIP {{ $ketua['sig']->signer->nip }}<br>@endif{{ $ketua['sig']->signed_at->translatedFormat('d F Y, H.i') }} WIB
                @else<div class="belum">(belum ditandatangani)</div>@endif
            </td>
            <td>Tim Verifikator Disperwaskim<br>
                @if($admin)<img src="{{ $admin['img'] }}" width="{{ $admin['w'] }}" height="{{ $admin['h'] }}"><br><strong>{{ $admin['sig']->signer?->name }}</strong><br>{{ $admin['sig']->signer?->jabatan }}<br>@if($admin['sig']->signer?->nip)NIP {{ $admin['sig']->signer->nip }}<br>@endif{{ $admin['sig']->signed_at->translatedFormat('d F Y, H.i') }} WIB
                @else<div class="belum">(belum ditandatangani)</div>@endif
            </td>
        </tr>
    </table>

    <table class="verif">
        <tr>
            <td style="width:90px;"><img src="{{ $qr }}" style="width:80px;"></td>
            <td>
                <strong>Verifikasi dokumen</strong><br>
                Pindai QR atau buka: {{ $verifyUrl }}<br>
                <span class="kecil">Sidik isi BA (SHA-256): {{ $hash }}</span><br>
                @if($r->published_at)<span class="kecil">Diterbitkan: {{ $r->published_at->translatedFormat('d F Y, H.i') }} WIB</span>@endif
            </td>
        </tr>
    </table>
</body>
</html>

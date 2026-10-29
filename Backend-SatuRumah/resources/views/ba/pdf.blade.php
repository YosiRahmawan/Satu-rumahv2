<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<style>
    /* Format resmi Disperwaskim: Folio (F4), Times New Roman 12, tanpa kop, bab I-V. */
    @page { margin: 71pt 56.7pt 56pt 56.7pt; }
    body { font-family: 'Times New Roman', Times, serif; font-size: 12pt; line-height: 1.5; color: #000; text-align: justify; }
    .judul { text-align: center; font-weight: bold; margin: 0 0 14pt; }
    .tandai { border: 1px solid #b91c1c; color: #b91c1c; padding: 3pt 6pt; text-align: center; font-weight: bold; font-size: 10pt; margin-bottom: 8pt; }
    p { margin: 0 0 4pt; }
    table.bab { width: 100%; border-collapse: collapse; margin-top: 3pt; }
    table.bab td { padding: 0; vertical-align: top; font-weight: bold; }
    table.bab td.no { width: 36pt; }
    .awal { text-indent: 36pt; }
    .blok { margin-left: 36pt; }
    ul.poin { margin: 0 0 0 36pt; padding-left: 18pt; }
    ul.poin li { margin-bottom: 3pt; }
    table.ttd { width: 100%; border-collapse: collapse; margin-top: 22pt; page-break-inside: avoid; }
    table.ttd td { width: 50%; vertical-align: top; text-align: center; padding: 0 6pt; }
    table.ttd td.gbr { height: 72pt; vertical-align: middle; }
    table.ttd td.nm { text-align: left; font-weight: bold; padding-left: 20pt; }
    .tengah { text-align: center; margin-top: 16pt; page-break-inside: avoid; }
    .tengah .gbr { height: 72pt; }
    .verif { margin-top: 18pt; border-top: 1px solid #999; padding-top: 5pt; font-size: 9pt; line-height: 1.3; page-break-inside: avoid; }
    .verif td { vertical-align: middle; text-align: left; }
    .kecil { font-size: 7.5pt; color: #444; word-break: break-all; }
    .doc-judul { page-break-before: always; font-weight: bold; margin: 0 0 6pt; text-align: left; }
    table.frame { width: 100%; border-collapse: collapse; margin-bottom: 10pt; page-break-inside: avoid; }
    table.frame td { border: 1px solid #777; text-align: center; vertical-align: middle; height: 372pt; padding: 2pt; }
</style>
</head>
<body>
    @unless($resmi)
        <div class="tandai">TEMPLATE SEMENTARA &mdash; BELUM FORMAT RESMI DISPERWASKIM.</div>
    @endunless

    <div class="judul">BERITA ACARA MONITORING DAN EVALUASI LAPANGAN</div>

    @php
        $tgl = $r->monitoring_date;
        $poin = fn ($daftar) => collect($daftar)->map(fn ($v) => trim((string) $v))->filter()->values()->all() ?: ['-'];
    @endphp

    <p>Pada hari ini, {{ $tgl?->translatedFormat('l') }} tanggal {{ $tgl?->format('j') }} bulan {{ $tgl?->translatedFormat('F') }} tahun {{ $tgl?->format('Y') }} telah dilakukan monitoring dan evaluasi lapangan oleh Tim dari Dinas Perumahan dan Kawasan Permukiman Kota Tasikmalaya bertempat di Perumahan {{ mb_strtoupper((string) $r->nama_perumahan) }} yang berlokasi di {{ $r->lokasi }}.</p>

    <table class="bab"><tr><td class="no">I.</td><td>Maksud dan Tujuan</td></tr></table>
    <p class="awal">{{ $r->maksud_tujuan }}</p>

    <table class="bab"><tr><td class="no">II.</td><td>Temuan Di Lapangan</td></tr></table>
    <ul class="poin">@foreach($poin($r->temuan) as $t)<li>{{ $t }}</li>@endforeach</ul>

    <table class="bab"><tr><td class="no">III.</td><td>Kesimpulan</td></tr></table>
    <div class="blok">@foreach($poin($r->kesimpulan) as $k)<p>{{ $k }}</p>@endforeach</div>

    <table class="bab"><tr><td class="no">IV.</td><td>Kesepakatan</td></tr></table>
    <ul class="poin">@foreach($poin($r->kesepakatan) as $k)<li>{{ $k }}</li>@endforeach</ul>

    <table class="bab"><tr><td class="no">V.</td><td>Rencana Tindak Lanjut</td></tr></table>
    <ul class="poin">@foreach($poin($r->rtl) as $k)<li>{{ $k }}</li>@endforeach</ul>

    <p style="margin-top:6pt;">Demikian Berita Acara ini dibuat dengan sebenarnya dan ditandatangani untuk digunakan sebagaimana mestinya.</p>

    <table class="ttd">
        <tr>
            <td>Yang Melaksanakan Observasi / Inspeksi<br>(Nama, Jabatan, Tanda Tangan)</td>
            <td>Yang Ditemui di Lapangan<br>(Nama, Jabatan, Tanda Tangan)</td>
        </tr>
        <tr>
            <td class="gbr">@if($ketua)<img src="{{ $ketua['img'] }}" width="{{ $ketua['w'] }}" height="{{ $ketua['h'] }}">@endif</td>
            <td class="gbr"></td>
        </tr>
        <tr>
            <td class="nm">
                Nama &nbsp;&nbsp;&nbsp;: {{ $ketua ? ($ketua['sig']->signer?->name ?: '-') : '-' }}<br>
                Jabatan : {{ $ketua ? ($ketua['sig']->signer?->jabatan ?: '-') : '-' }}@if($ketua && $ketua['sig']->signer?->nip)<br>NIP &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: {{ $ketua['sig']->signer->nip }}@endif
            </td>
            <td class="nm">
                @php $ditemui = collect($r->pihak_ditemui ?? [])->filter(fn ($m) => trim((string) ($m['nama'] ?? '')) !== ''); @endphp
                @forelse($ditemui as $m)
                    Nama &nbsp;&nbsp;&nbsp;: {{ $m['nama'] }}<br>Jabatan : {{ ($m['jabatan'] ?? '') ?: '-' }}@unless($loop->last)<br><br>@endunless
                @empty
                    Nama &nbsp;&nbsp;&nbsp;: -<br>Jabatan : -
                @endforelse
            </td>
        </tr>
    </table>

    {{-- Tim verifikator menandatangani setelah Ketua (keputusan Disperwaskim); letaknya di bawah dua kolom di atas. --}}
    <div class="tengah">
        Mengetahui,<br>Tim Verifikator Disperwaskim
        <div class="gbr">@if($admin)<img src="{{ $admin['img'] }}" width="{{ $admin['w'] }}" height="{{ $admin['h'] }}">@endif</div>
        <strong>Nama &nbsp;&nbsp;&nbsp;: {{ $admin ? ($admin['sig']->signer?->name ?: '-') : '-' }}</strong><br>
        <strong>Jabatan : {{ $admin ? ($admin['sig']->signer?->jabatan ?: '-') : '-' }}</strong>@if($admin && $admin['sig']->signer?->nip)<br><strong>NIP &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: {{ $admin['sig']->signer->nip }}</strong>@endif
    </div>

    <table class="verif">
        <tr>
            <td style="width:70pt;"><img src="{{ $qr }}" style="width:62pt;"></td>
            <td>
                <strong>Verifikasi dokumen:</strong> pindai QR atau buka {{ $verifyUrl }}<br>
                <span class="kecil">Sidik isi BA (SHA-256): {{ $hash }}</span>@if($r->published_at)<br><span class="kecil">Diterbitkan: {{ $r->published_at->translatedFormat('d F Y, H.i') }} WIB &middot; No. BA {{ $r->report_number }}</span>@endif
            </td>
        </tr>
    </table>

    @if(!empty($foto))
        <div class="doc-judul">Dokumentasi Lapangan/ Drone :</div>
        @foreach($foto as $f)
            <table class="frame"><tr><td>@if($f['uri'])<img src="{{ $f['uri'] }}" width="{{ $f['w'] }}" height="{{ $f['h'] }}">@endif</td></tr></table>
        @endforeach
    @endif
</body>
</html>

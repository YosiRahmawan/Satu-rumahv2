<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex">
    <title>Verifikasi Berita Acara - SATU RUMAH</title>
    <link rel="stylesheet" href="{{ asset('css/portal.css') }}">
</head>
<body style="background:var(--bg-page);">
<div style="max-width:520px;margin:40px auto;padding:0 16px;">
    <div class="card"><div class="card-body" style="display:grid;gap:12px;">
        <div class="fw-700" style="font-size:18px;">Verifikasi Berita Acara</div>
        @if(!$ditemukan)
            <div class="alert alert-danger" style="margin:0;"><div>Dokumen tidak ditemukan. Pastikan QR berasal dari Berita Acara resmi.</div></div>
        @else
            <dl class="kv">
                <div class="kv-row"><dt>Nomor BA</dt><dd>{{ $nomor }}</dd></div>
                <div class="kv-row"><dt>Perumahan</dt><dd>{{ $perumahan }}</dd></div>
                <div class="kv-row"><dt>Status</dt><dd>
                    @if($terbit)<span class="badge badge-success badge-dot">Diterbitkan</span>@else<span class="badge badge-warning badge-dot">Belum diterbitkan</span>@endif
                </dd></div>
                @if($terbit)<div class="kv-row"><dt>Tanggal terbit</dt><dd>{{ $terbit->translatedFormat('d F Y') }}</dd></div>@endif
                <div class="kv-row"><dt>Ketua Pengawas Lapangan</dt><dd>{{ $ketua ? 'Menyetujui ' . $ketua->translatedFormat('d F Y, H.i') . ' WIB' : 'Belum' }}</dd></div>
                <div class="kv-row"><dt>Tim Verifikator</dt><dd>{{ $admin ? 'Menyetujui ' . $admin->translatedFormat('d F Y, H.i') . ' WIB' : 'Belum' }}</dd></div>
            </dl>
            @unless($resmi)
                <div class="callout">Format BA ini masih template sementara dan belum ditetapkan resmi oleh Disperwaskim. Persetujuan berupa persetujuan elektronik berbasis akun, bukan tanda tangan elektronik tersertifikasi.</div>
            @endunless
        @endif
    </div></div>
</div>
</body>
</html>

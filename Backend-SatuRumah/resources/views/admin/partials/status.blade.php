@php
    $cls = match ($s->sub_status) {
        'perlu_perbaikan' => 'badge-warning',
        'ditolak' => 'badge-danger',
        'selesai', 'menunggu_persetujuan' => 'badge-success',
        'terjadwal' => 'badge-info',
        default => '',
    };
@endphp
<span class="badge {{ $cls }} badge-dot">{{ $s->statusLabel() }}</span>

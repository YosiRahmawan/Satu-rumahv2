@php
    $cls = match ($s->sub_status) {
        'perlu_perbaikan' => 'badge-warning',
        'ditolak' => 'badge-danger',
        'selesai', 'menunggu_persetujuan' => 'badge-success',
        'terjadwal' => 'badge-info',
        default => '',
    };
@endphp
@php $sla = app(\App\Services\SlaSettings::class)->state($s); @endphp
<span class="badge {{ $cls }} badge-dot">{{ $s->statusLabel() }}</span>
@if($sla === 'terlambat')<span class="badge badge-danger" title="Melewati batas waktu tahap ini">Lewat SLA</span>@elseif($sla === 'mendekati')<span class="badge badge-warning" title="Mendekati batas waktu tahap ini">Mendekati SLA</span>@endif

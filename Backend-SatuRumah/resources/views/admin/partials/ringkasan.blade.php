{{-- Dua kartu ringkasan di bawah dashboard; diperbarui otomatis dari database. --}}
<div class="grid-main-side" style="margin-top:24px;">
    <div class="card">
        <div class="card-head">
            <div>
                <div class="card-title">Sebaran Audit Per Kecamatan</div>
                <div class="card-sub">Pengajuan site plan per kecamatan tahun {{ $sebaran['tahun'] }} (target {{ $sebaran['target'] }} berkas per kecamatan).</div>
            </div>
        </div>
        <div class="card-body" style="padding-top:4px;">
            @forelse($sebaran['rows'] as $row)
                <div class="sebaran-row">
                    <div class="sebaran-head">
                        <span class="sebaran-nama"><i class="sw {{ $row['terbanyak'] ? 'is-primary' : 'is-neutral' }}" style="border-radius:50%;"></i>Kecamatan {{ $row['nama'] }}</span>
                        <span class="sebaran-nilai"><strong class="{{ $row['terbanyak'] ? 'text-primary' : '' }}">{{ $row['jumlah'] }} Berkas</strong> ({{ $row['persen'] }}% Target)</span>
                    </div>
                    <div class="progress">
                        <div class="progress-bar {{ $row['terbanyak'] ? '' : 'is-neutral' }}" data-kec="{{ $row['nama'] }}" data-lebar="{{ $row['lebar'] }}" style="width: {{ $row['lebar'] }}%;"></div>
                    </div>
                </div>
            @empty
                <div class="text-muted" style="padding:24px 0;text-align:center;">Belum ada pengajuan dengan kecamatan tahun {{ $sebaran['tahun'] }}.</div>
            @endforelse

            @if($sebaran['tanpa'] > 0)
                <div class="text-muted" style="font-size:12px;margin-top:4px;">{{ $sebaran['tanpa'] }} pengajuan belum memilih kecamatan.</div>
            @endif

            <div class="legend">
                <span><i class="sw is-primary"></i>Paling banyak</span>
                <span><i class="sw is-neutral"></i>Kecamatan lain</span>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-head" style="align-items:flex-start;">
            <div>
                <div class="eyebrow">TIM PENGAWAS</div>
                <div class="card-title">Jadwal Tinjauan Lapangan</div>
                <div class="card-sub">
                    @if($jadwal['hari_ini'] > 0)
                        Hari ini dijadwalkan {{ $jadwal['hari_ini'] }} peninjauan fisik konstruksi perumahan.
                    @else
                        Tidak ada peninjauan hari ini.
                    @endif
                </div>
            </div>
            @if($jadwal['hari_ini'] > 0)<span class="eyebrow is-live">HARI INI</span>@endif
        </div>
        <div class="card-body" style="padding-top:4px;">
            @forelse($jadwal['items'] as $j)
                <a href="{{ route('pengajuan.show', ['id' => $j['id'], 'tab' => 'monitoring']) }}" class="jadwal-item">
                    <i class="jadwal-dot {{ $j['hari_ini'] ? 'is-primary' : '' }}"></i>
                    <div>
                        <div>
                            <span class="chip {{ $j['hari_ini'] ? 'is-primary' : '' }}">{{ $j['hari_ini'] ? 'Hari ini' : $j['tanggal']->translatedFormat('D, d M') }}</span>
                            <strong>Survei {{ $j['perumahan'] }}</strong>
                        </div>
                        <div class="text-muted" style="font-size:12.5px;">
                            {{ $j['tim'] ?: 'Petugas belum ditentukan' }}
                            <span class="badge {{ $j['diterima'] ? 'badge-success' : 'badge-warning' }} badge-dot" style="margin-left:6px;">{{ $j['diterima'] ? 'Sudah diterima petugas' : 'Belum diterima petugas' }}</span>
                        </div>
                    </div>
                </a>
            @empty
                <div class="text-muted" style="padding:16px 0;text-align:center;">Belum ada survei terjadwal dalam 7 hari ke depan.</div>
            @endforelse
            <a href="{{ route('pengajuan.index', ['tahap' => 4]) }}" class="btn btn-primary btn-block" style="margin-top:12px;">Lihat Semua Jadwal Survei</a>
        </div>
    </div>
</div>

<div style="display: grid; grid-template-columns: 2fr 1fr; gap: 24px; align-items: start;">
    <!-- Informasi Perumahan Card -->
    <div class="card" style="margin-bottom: 0;">
        <div class="card-header">
            <h2 class="card-title">Informasi Perumahan</h2>
        </div>
        <div class="card-body" style="padding: 0;">
            <table class="table" style="font-size: 14px;">
                <tbody>
                    <tr>
                        <td style="width: 220px; color: var(--text-muted); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">Nama perumahan</td>
                        <td style="font-weight: 700; color: var(--text-main); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">{{ $pengajuan->nama_perumahan }}</td>
                    </tr>
                    <tr>
                        <td style="color: var(--text-muted); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">Lokasi</td>
                        <td style="font-weight: 600; color: var(--text-main); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">{{ $pengajuan->lokasi }}</td>
                    </tr>
                    <tr>
                        <td style="color: var(--text-muted); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">Jumlah unit</td>
                        <td style="font-weight: 700; color: var(--text-main); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">{{ $pengajuan->jumlah_unit }}</td>
                    </tr>
                    <tr>
                        <td style="color: var(--text-muted); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">Luas kawasan</td>
                        <td style="font-weight: 700; color: var(--text-main); border-bottom: 1px solid var(--border-color); padding: 18px 24px;">{{ $pengajuan->luas_kawasan }}</td>
                    </tr>
                    <tr>
                        <td style="color: var(--text-muted); padding: 18px 24px;">Penanggung jawab</td>
                        <td style="font-weight: 700; color: var(--text-main); padding: 18px 24px;">{{ $pengajuan->penanggung_jawab }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Status Pengajuan Card -->
    <div class="card" style="margin-bottom: 0;">
        <div class="card-header">
            <h2 class="card-title">Status Pengajuan</h2>
        </div>
        <div class="card-body">
            <div style="margin-bottom: 16px;">
                @if($pengajuan->status == 'Perlu perbaikan')
                    <span class="badge badge-yellow" style="font-size: 13px; padding: 6px 12px;">Perlu perbaikan</span>
                @elseif($pengajuan->status == 'Terjadwal')
                    <span class="badge badge-blue" style="font-size: 13px; padding: 6px 12px;">Terjadwal</span>
                @elseif($pengajuan->status == 'Final' || $pengajuan->status == 'Siap disetujui')
                    <span class="badge badge-green" style="font-size: 13px; padding: 6px 12px;">{{ $pengajuan->status }}</span>
                @else
                    <span class="badge badge-gray" style="font-size: 13px; padding: 6px 12px;">{{ $pengajuan->status }}</span>
                @endif
            </div>

            <p style="font-size: 14px; color: var(--text-main); line-height: 1.6; margin-bottom: 24px;">
                {{ $pengajuan->catatan_status ?? 'Terdapat 3 dokumen yang memerlukan perbaikan sebelum proses dapat dilanjutkan ke penjadwalan survey.' }}
            </p>

            <div style="font-size: 12px; color: var(--text-muted); border-top: 1px solid var(--border-color); padding-top: 16px;">
                Diajukan pada {{ $pengajuan->diajukan_pada }}
            </div>
        </div>
    </div>
</div>

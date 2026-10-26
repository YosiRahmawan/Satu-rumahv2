<div class="card">
    <div class="card-header">
        <h2 class="card-title">Formulir Verifikasi Teknis Pengajuan</h2>
    </div>
    <div class="card-body">
        <form action="{{ route('pengajuan.update_status', $pengajuan->id) }}" method="POST">
            @csrf
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px;">
                <div class="form-group">
                    <label class="form-label">Nomor ID Pengajuan</label>
                    <input type="text" class="form-input" value="{{ $pengajuan->id }}" readonly style="background-color: #f8fafc; font-weight: 700;">
                </div>
                <div class="form-group">
                    <label class="form-label">Nama Perumahan & Pengembang</label>
                    <input type="text" class="form-input" value="{{ $pengajuan->nama_perumahan }} ({{ $pengajuan->nama_pengembang }})" readonly style="background-color: #f8fafc;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px;">
                <div class="form-group">
                    <label class="form-label">Tahap Pengajuan Saat Ini</label>
                    <select name="tahap" class="form-select">
                        <option value="Dokumen" {{ $pengajuan->tahap == 'Dokumen' ? 'selected' : '' }}>Dokumen</option>
                        <option value="Verifikasi teknis" {{ $pengajuan->tahap == 'Verifikasi teknis' ? 'selected' : '' }}>Verifikasi teknis</option>
                        <option value="Survey" {{ $pengajuan->tahap == 'Survey' ? 'selected' : '' }}>Survey</option>
                        <option value="Monitoring" {{ $pengajuan->tahap == 'Monitoring' ? 'selected' : '' }}>Monitoring</option>
                        <option value="Persetujuan" {{ $pengajuan->tahap == 'Persetujuan' ? 'selected' : '' }}>Persetujuan</option>
                    </select>
                </div>

                <div class="form-group">
                    <label class="form-label">Status Keputusan Verifikasi</label>
                    <select name="status" class="form-select">
                        <option value="Menunggu verifikasi" {{ $pengajuan->status == 'Menunggu verifikasi' ? 'selected' : '' }}>Menunggu verifikasi</option>
                        <option value="Perlu perbaikan" {{ $pengajuan->status == 'Perlu perbaikan' ? 'selected' : '' }}>Perlu perbaikan</option>
                        <option value="Terjadwal" {{ $pengajuan->status == 'Terjadwal' ? 'selected' : '' }}>Terjadwal (Siap Survey)</option>
                        <option value="Draft" {{ $pengajuan->status == 'Draft' ? 'selected' : '' }}>Draft Monitoring</option>
                        <option value="Final" {{ $pengajuan->status == 'Final' ? 'selected' : '' }}>Final Monitoring</option>
                        <option value="Siap disetujui" {{ $pengajuan->status == 'Siap disetujui' ? 'selected' : '' }}>Siap disetujui</option>
                    </select>
                </div>
            </div>

            <div class="form-group" style="margin-bottom: 24px;">
                <label class="form-label">Pemeriksaan Checklist Kriteria Utama</label>
                <div style="display: flex; flex-direction: column; gap: 12px; background-color: #f8fafc; padding: 20px; border-radius: 8px; border: 1px solid var(--border-color);">
                    <label style="display: flex; align-items: center; gap: 10px; font-size: 13px; cursor: pointer;">
                        <input type="checkbox" checked style="width: 16px; height: 16px;">
                        <span>Kesesuaian koefisien dasar bangunan (KDB) dan koefisien lantai bangunan (KLB) sesuai Perda.</span>
                    </label>
                    <label style="display: flex; align-items: center; gap: 10px; font-size: 13px; cursor: pointer;">
                        <input type="checkbox" checked style="width: 16px; height: 16px;">
                        <span>Ketersediaan alokasi Ruang Terbuka Hijau (RTH) minimal 20% kawasan perumahan.</span>
                    </label>
                    <label style="display: flex; align-items: center; gap: 10px; font-size: 13px; cursor: pointer;">
                        <input type="checkbox" style="width: 16px; height: 16px;">
                        <span style="color: var(--badge-yellow-text); font-weight: 600;">Detail rancangan jaringan drainase utama terhubung ke pembuangan akhir kota (Butuh revisi).</span>
                    </label>
                    <label style="display: flex; align-items: center; gap: 10px; font-size: 13px; cursor: pointer;">
                        <input type="checkbox" checked style="width: 16px; height: 16px;">
                        <span>Aksesibilitas jalan utama minimal lebar 6-8 meter untuk kendaraan umum & pemadam.</span>
                    </label>
                </div>
            </div>

            <div style="display: flex; justify-content: flex-end; gap: 12px;">
                <a href="{{ route('pengajuan.show', ['id' => $pengajuan->id, 'tab' => 'ringkasan']) }}" class="btn btn-outline">Batal</a>
                <button type="submit" class="btn btn-primary">Simpan Hasil Verifikasi</button>
            </div>
        </form>
    </div>
</div>

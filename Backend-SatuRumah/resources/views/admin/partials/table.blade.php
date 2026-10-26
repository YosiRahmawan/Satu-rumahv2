<div class="table-wrap">
    <table class="table">
        <thead>
            <tr>
                <th>No. Pengajuan</th>
                <th>Pengembang</th>
                <th>Perumahan</th>
                <th>Tahap</th>
                <th>Status</th>
                <th>Diperbarui</th>
                <th class="col-actions">Aksi</th>
            </tr>
        </thead>
        <tbody>
            @forelse($pengajuans as $s)
                <tr class="{{ $s->sub_status === 'perlu_perbaikan' ? 'row-flag' : '' }}">
                    <td><span class="id-chip {{ $s->sub_status === 'perlu_perbaikan' ? 'is-hot' : '' }}">{{ $s->number }}</span></td>
                    <td>{{ $s->developer?->developerProfile?->nama_pt ?? $s->developer?->name }}</td>
                    <td class="col-strong">{{ $s->nama_perumahan }}</td>
                    <td><span class="chip">{{ $s->tahapLabel() }}</span></td>
                    <td>@include('admin.partials.status', ['s' => $s])</td>
                    <td class="text-muted" style="font-size:12px;">{{ $s->updated_at?->translatedFormat('d M Y, H.i') }}</td>
                    <td class="col-actions"><a href="{{ route('pengajuan.show', $s->id) }}" class="table-link">Buka</a></td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" style="text-align:center;padding:40px;" class="text-muted">
                        <div style="font-weight:700;margin-bottom:4px;">Belum ada pengajuan</div>
                        <div style="font-size:13px;">Pengajuan yang dikirim pengembang dari aplikasi akan muncul di sini.</div>
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>
</div>

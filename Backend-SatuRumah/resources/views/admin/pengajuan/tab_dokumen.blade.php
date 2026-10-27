@php
    $canReview = $s->stage >= 2 && $s->stage <= 5 && !$s->isInRevision() && !in_array($s->sub_status, ['selesai', 'ditolak'], true);
    $flagged = $s->currentFiles->where('status', 'perlu_perbaikan')->count();
@endphp

@if($s->isInRevision())
    <div class="callout" style="margin-bottom:16px;">Permintaan perbaikan sudah dikirim. Berkas bisa dinilai lagi setelah pengembang mengirim perbaikan.</div>
@endif

<div class="card" style="box-shadow:none;">
    <div class="card-head bordered">
        <div>
            <h2 class="card-title" style="font-size:16px;">Berkas Persyaratan</h2>
            <div class="card-sub">{{ $s->currentFiles->count() }} berkas aktif &middot; {{ $flagged }} perlu perbaikan</div>
        </div>
        @if($canReview && $flagged > 0)
            <form method="POST" action="{{ route('pengajuan.perbaikan', $s->id) }}" onsubmit="return confirm('Kirim permintaan perbaikan ke pengembang?')">
                @csrf <button class="btn btn-primary">Kirim Permintaan Perbaikan</button>
            </form>
        @endif
    </div>
    <div class="table-wrap">
        <table class="table">
            <thead>
                <tr><th>Persyaratan</th><th>Berkas</th><th>Status</th>@if($canReview)<th>Penilaian</th>@endif</tr>
            </thead>
            <tbody>
                @foreach($slots as $code => $slot)
                    @php $files = $filesBySlot->get($code, collect()); @endphp
                    @forelse($files as $f)
                        <tr>
                            @if($loop->first)<td class="col-strong" rowspan="{{ $files->count() }}">{{ $code }} &middot; {{ $slot['name'] }}</td>@endif
                            <td>
                                <a class="table-link" href="{{ route('pengajuan.berkas', [$s->id, $f->id]) }}">{{ $f->original_name }}</a>
                                <div class="text-muted" style="font-size:12px;">v{{ $f->version }} &middot; {{ number_format($f->size_bytes / 1048576, 2) }} MB</div>
                            </td>
                            <td>
                                @if($f->status === 'lolos') <span class="badge badge-success badge-dot">Sesuai</span>
                                @elseif($f->status === 'perlu_perbaikan') <span class="badge badge-warning badge-dot">Perlu perbaikan</span>
                                @else <span class="badge badge-dot">Belum diperiksa</span> @endif
                                @if($f->review_note)<div class="text-muted" style="font-size:12px;margin-top:4px;">{{ $f->review_note }}</div>@endif
                            </td>
                            @if($canReview)
                                <td>
                                    <form method="POST" action="{{ route('pengajuan.nilai', [$s->id, $f->id]) }}" style="display:flex;gap:6px;flex-wrap:wrap;">
                                        @csrf
                                        <select name="decision" class="select">
                                            <option value="lolos" @selected($f->status === 'lolos')>Sesuai</option>
                                            <option value="perlu_perbaikan" @selected($f->status === 'perlu_perbaikan')>Perlu perbaikan</option>
                                        </select>
                                        <input name="catatan" class="input" placeholder="Catatan" value="{{ $f->review_note }}" style="min-width:160px;">
                                        <button class="btn btn-outline btn-sm">Simpan</button>
                                    </form>
                                </td>
                            @endif
                        </tr>
                    @empty
                        <tr>
                            <td class="col-strong">{{ $code }} &middot; {{ $slot['name'] }}</td>
                            <td colspan="{{ $canReview ? 3 : 2 }}" class="text-muted">{{ ($slot['required'] ?? true) ? 'Belum diunggah' : 'Opsional, tidak diunggah' }}</td>
                        </tr>
                    @endforelse
                @endforeach
            </tbody>
        </table>
    </div>
</div>

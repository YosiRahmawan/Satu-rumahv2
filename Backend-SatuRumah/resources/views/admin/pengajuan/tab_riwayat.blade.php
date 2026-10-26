<div class="card" style="box-shadow:none;">
    <div class="card-head bordered"><h2 class="card-title" style="font-size:16px;">Riwayat aktivitas</h2></div>
    <div class="card-body">
        <div class="timeline">
            @forelse($s->events as $e)
                <div class="tl-item">
                    <span class="tl-dot {{ str_contains($e->type, 'revision') || str_contains($e->title, 'perlu perbaikan') ? 'warn' : 'ok' }}"></span>
                    <div class="tl-card">
                        <div class="tl-head">{{ $e->created_at?->translatedFormat('d M Y · H.i') }}@if($e->actor) &middot; {{ $e->actor->name }}@endif</div>
                        <div class="tl-title" style="font-size:14px;">{{ $e->title }}</div>
                        @if($e->description)<div class="text-muted" style="font-size:13px;">{{ $e->description }}</div>@endif
                    </div>
                </div>
            @empty
                <div class="text-muted">Belum ada aktivitas tercatat.</div>
            @endforelse
        </div>
    </div>
</div>

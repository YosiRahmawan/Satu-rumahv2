{{-- Formulir lipat: alasan wajib, tanpa jendela terpisah. Dipakai di kartu BA dan di Ringkasan. --}}
<details style="margin:8px 0;">
    <summary class="btn btn-outline btn-sm" style="display:inline-block;cursor:pointer;">Minta Perbaikan BA</summary>
    <form method="POST" action="{{ route('pengajuan.perbaikan_ba', [$s->id, $r->id]) }}" style="display:grid;gap:8px;margin-top:10px;" data-konfirmasi="BA dikembalikan ke petugas dan tanda tangan yang ada tidak berlaku lagi. Petugas membuat BA pengganti." data-konfirmasi-judul="Kembalikan BA ke Petugas" data-konfirmasi-tombol="Ya, kembalikan">
        @csrf
        <label class="form-label" style="margin:0;">Apa yang perlu diperbaiki? <span class="text-muted">(wajib)</span></label>
        <textarea name="catatan" class="form-textarea" rows="3" minlength="5" maxlength="500" required placeholder="Contoh: Temuan drainase belum lengkap dan foto lokasi kurang jelas."></textarea>
        <div><button class="btn btn-primary btn-sm">Kirim Permintaan Perbaikan</button></div>
    </form>
</details>

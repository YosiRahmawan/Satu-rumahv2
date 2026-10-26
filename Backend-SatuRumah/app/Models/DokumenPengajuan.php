<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DokumenPengajuan extends Model
{
    use HasFactory;

    protected $table = 'dokumen_pengajuan';

    protected $fillable = [
        'pengajuan_id',
        'kategori',
        'nama_persyaratan',
        'nama_file',
        'ukuran_file',
        'tanggal_unggah',
        'status',
        'catatan',
    ];

    public function pengajuan()
    {
        return $this->belongsTo(Pengajuan::class, 'pengajuan_id', 'id');
    }
}

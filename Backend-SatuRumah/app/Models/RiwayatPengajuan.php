<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RiwayatPengajuan extends Model
{
    use HasFactory;

    protected $table = 'riwayat_pengajuan';

    protected $fillable = [
        'pengajuan_id',
        'judul',
        'deskripsi',
        'oleh',
        'tanggal',
    ];

    public function pengajuan()
    {
        return $this->belongsTo(Pengajuan::class, 'pengajuan_id', 'id');
    }
}

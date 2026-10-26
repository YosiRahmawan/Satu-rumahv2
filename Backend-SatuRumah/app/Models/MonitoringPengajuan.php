<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MonitoringPengajuan extends Model
{
    use HasFactory;

    protected $table = 'monitoring_pengajuan';

    protected $fillable = [
        'pengajuan_id',
        'status_monitoring',
        'tanggal_survey',
        'petugas_nama',
        'hasil',
        'temuan',
        'kesimpulan',
        'kesepakatan',
        'rencana_tindak_lanjut',
        'foto_bukti',
    ];

    protected $casts = [
        'foto_bukti' => 'array',
    ];

    public function pengajuan()
    {
        return $this->belongsTo(Pengajuan::class, 'pengajuan_id', 'id');
    }
}

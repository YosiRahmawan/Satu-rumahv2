<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SurveyPengajuan extends Model
{
    use HasFactory;

    protected $table = 'survey_pengajuan';

    protected $fillable = [
        'pengajuan_id',
        'tanggal_survey',
        'jam_survey',
        'petugas_nama',
        'petugas_role',
        'instruksi',
        'status',
    ];

    public function pengajuan()
    {
        return $this->belongsTo(Pengajuan::class, 'pengajuan_id', 'id');
    }
}

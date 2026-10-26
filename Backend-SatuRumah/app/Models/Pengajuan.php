<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pengajuan extends Model
{
    use HasFactory;

    protected $table = 'pengajuan';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'nama_pengembang',
        'nama_perumahan',
        'lokasi',
        'jumlah_unit',
        'luas_kawasan',
        'penanggung_jawab',
        'tahap',
        'status',
        'catatan_status',
        'diajukan_pada',
    ];

    public function dokumen()
    {
        return $this->hasMany(DokumenPengajuan::class, 'pengajuan_id', 'id');
    }

    public function survey()
    {
        return $this->hasMany(SurveyPengajuan::class, 'pengajuan_id', 'id');
    }

    public function activeSurvey()
    {
        return $this->hasOne(SurveyPengajuan::class, 'pengajuan_id', 'id')->where('status', 'Terjadwal')->latest();
    }

    public function monitoring()
    {
        return $this->hasOne(MonitoringPengajuan::class, 'pengajuan_id', 'id');
    }

    public function riwayat()
    {
        return $this->hasMany(RiwayatPengajuan::class, 'pengajuan_id', 'id')->latest();
    }

    public function notifikasi()
    {
        return $this->hasMany(Notifikasi::class, 'pengajuan_id', 'id');
    }
}

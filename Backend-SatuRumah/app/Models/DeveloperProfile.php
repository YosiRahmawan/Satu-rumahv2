<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeveloperProfile extends Model
{
    protected $fillable = [
        'user_id',
        'nib',
        'nama_perumahan',
        'nama_pt',
        'nama_direktur',
        'alamat_perumahan',
        'alamat_pt',
        'no_hp_direktur',
        'email_pt',
        'tipe_pengajuan',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

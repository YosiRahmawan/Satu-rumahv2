<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Persetujuan elektronik satu pihak (ketua/admin) atas satu versi BA. */
class ReportSignature extends Model
{
    public const KETUA = 'ketua';
    public const ADMIN = 'admin';

    protected $fillable = [
        'report_id', 'role', 'user_id', 'method', 'signature_path', 'document_hash',
        'report_version', 'signed_at', 'provider', 'provider_ref', 'ip',
    ];

    protected function casts(): array
    {
        return ['signed_at' => 'datetime', 'report_version' => 'integer'];
    }

    public function report(): BelongsTo
    {
        return $this->belongsTo(InspectionReport::class, 'report_id');
    }

    public function signer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Penugasan survei: satu petugas lapangan untuk satu pengajuan pada satu tanggal. */
class InspectionAssignment extends Model
{
    public const OPEN = ['dijadwalkan', 'diterima'];

    protected $fillable = [
        'submission_id', 'officer_id', 'scheduled_date', 'note', 'status',
        'reassigned_from_id', 'reassign_reason', 'created_by', 'accepted_at', 'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_date' => 'date',
            'accepted_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function submission(): BelongsTo
    {
        return $this->belongsTo(Submission::class);
    }

    public function officer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'officer_id');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(InspectionReport::class, 'assignment_id');
    }

    public function isOpen(): bool
    {
        return in_array($this->status, self::OPEN, true);
    }
}

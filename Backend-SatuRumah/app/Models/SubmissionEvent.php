<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** Satu baris riwayat pengajuan (siapa melakukan apa dan kapan). */
class SubmissionEvent extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = ['submission_id', 'actor_id', 'type', 'title', 'description', 'meta'];

    protected function casts(): array
    {
        return ['meta' => 'array', 'created_at' => 'datetime'];
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }

    public function submission(): BelongsTo
    {
        return $this->belongsTo(Submission::class);
    }
}

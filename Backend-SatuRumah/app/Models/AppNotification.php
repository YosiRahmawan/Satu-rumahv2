<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppNotification extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = ['user_id', 'submission_id', 'type', 'title', 'body', 'data', 'read_at'];

    public function submission(): BelongsTo
    {
        return $this->belongsTo(Submission::class);
    }

    protected function casts(): array
    {
        return ['data' => 'array', 'read_at' => 'datetime', 'created_at' => 'datetime'];
    }
}

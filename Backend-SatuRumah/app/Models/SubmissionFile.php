<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubmissionFile extends Model
{
    protected $fillable = [
        'submission_id', 'slot_code', 'version', 'is_current', 'original_name', 'stored_name', 'storage_path',
        'file_type', 'size_bytes', 'checksum', 'status', 'decision_type', 'review_note',
        'draft_status', 'draft_decision_type', 'draft_note',
        'uploaded_by', 'reviewed_by', 'reviewed_at', 'replaced_at',
    ];

    protected function casts(): array
    {
        return [
            'is_current' => 'boolean',
            'version' => 'integer',
            'size_bytes' => 'integer',
            'reviewed_at' => 'datetime',
            'replaced_at' => 'datetime',
        ];
    }

    public function submission(): BelongsTo
    {
        return $this->belongsTo(Submission::class);
    }
}

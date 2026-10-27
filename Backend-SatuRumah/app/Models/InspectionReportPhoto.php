<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InspectionReportPhoto extends Model
{
    protected $table = 'inspection_report_photos';

    protected $fillable = [
        'report_id', 'position', 'stored_name', 'storage_path', 'size_bytes', 'checksum',
        'latitude', 'longitude', 'accuracy_m', 'captured_at', 'address', 'note', 'source',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
            'accuracy_m' => 'float',
            'size_bytes' => 'integer',
            'position' => 'integer',
            'captured_at' => 'datetime',
        ];
    }

    public function report(): BelongsTo
    {
        return $this->belongsTo(InspectionReport::class, 'report_id');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Pengajuan persetujuan site plan/PSU. Tahap (`stage`) dan `sub_status`
 * mengikuti KONTRAK_INTEGRASI.md bagian 3.
 */
class Submission extends Model
{
    public const STAGE_DRAFT = 1;
    public const STAGE_ADMINISTRASI = 2;
    public const STAGE_TEKNIS = 3;
    public const STAGE_SURVEI = 4;
    public const STAGE_PERSETUJUAN = 5;
    public const STAGE_SELESAI = 6;

    protected $fillable = [
        'number', 'client_uuid', 'developer_id', 'npwp', 'luas_lahan', 'jumlah_unit', 'tipe_perumahan',
        'stage', 'sub_status', 'current_step', 'submitted_at', 'stage_entered_at',
        'sla_paused_at', 'sla_paused_seconds', 'correction_deadline_at',
        'decision_number', 'decision_date', 'decision_file_path', 'completed_at', 'version',
    ];

    protected function casts(): array
    {
        return [
            'luas_lahan' => 'float',
            'jumlah_unit' => 'integer',
            'stage' => 'integer',
            'current_step' => 'integer',
            'version' => 'integer',
            'submitted_at' => 'datetime',
            'stage_entered_at' => 'datetime',
            'sla_paused_at' => 'datetime',
            'correction_deadline_at' => 'datetime',
            'decision_date' => 'date',
            'completed_at' => 'datetime',
        ];
    }

    public function developer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'developer_id');
    }

    public function files(): HasMany
    {
        return $this->hasMany(SubmissionFile::class);
    }

    public function currentFiles(): HasMany
    {
        return $this->files()->where('is_current', true);
    }

    public function isDraft(): bool
    {
        return $this->stage === self::STAGE_DRAFT;
    }

    public function isInRevision(): bool
    {
        return $this->sub_status === 'perlu_perbaikan';
    }

    /** Kunci enum `StatusTahapPengajuan` di Flutter (kontrak bagian 3). */
    public function statusTahap(): string
    {
        if ($this->sub_status === 'perlu_perbaikan') {
            return 'perluPerbaikan';
        }
        if ($this->sub_status === 'ditolak') {
            return 'ditolak';
        }

        return match ($this->stage) {
            self::STAGE_DRAFT => 'draft',
            self::STAGE_ADMINISTRASI => $this->sub_status === 'baru' ? 'pengajuanBaru' : 'verifikasiAdministrasi',
            self::STAGE_TEKNIS => 'verifikasiTeknis',
            self::STAGE_SURVEI => 'surveyLapangan',
            self::STAGE_PERSETUJUAN => 'persetujuan',
            default => 'selesai',
        };
    }
}

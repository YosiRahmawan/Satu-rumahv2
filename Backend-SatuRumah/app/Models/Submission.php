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
        'number', 'client_uuid', 'developer_id', 'nama_perumahan', 'alamat_proyek', 'tipe_pengajuan', 'daya_listrik', 'npwp', 'luas_lahan', 'jumlah_unit', 'tipe_perumahan',
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

    public function events(): HasMany
    {
        return $this->hasMany(SubmissionEvent::class)->latest('id');
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(InspectionAssignment::class)->latest('id');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(InspectionReport::class)->latest('id');
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

    public const TAHAP_LABEL = [
        self::STAGE_DRAFT => 'Draf',
        self::STAGE_ADMINISTRASI => 'Verifikasi Administrasi',
        self::STAGE_TEKNIS => 'Verifikasi Teknis',
        self::STAGE_SURVEI => 'Survei Lapangan',
        self::STAGE_PERSETUJUAN => 'Persetujuan',
        self::STAGE_SELESAI => 'Selesai',
    ];

    public const STATUS_LABEL = [
        'draft' => 'Draf', 'baru' => 'Baru masuk', 'dalam_telaah' => 'Dalam telaah',
        'perlu_perbaikan' => 'Perlu perbaikan', 'perbaikan_terkirim' => 'Perbaikan terkirim',
        'terjadwal' => 'Terjadwal', 'menunggu_persetujuan' => 'Menunggu persetujuan',
        'selesai' => 'Selesai', 'ditolak' => 'Ditolak',
    ];

    public function tahapLabel(): string
    {
        return self::TAHAP_LABEL[$this->stage] ?? '-';
    }

    public function statusLabel(): string
    {
        return self::STATUS_LABEL[$this->sub_status] ?? (string) $this->sub_status;
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

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/** Laporan monitoring (BA). Berstatus draft sampai petugas mengirimnya (final). */
class InspectionReport extends Model
{
    public const EVALUASI = ['sesuaiSiteplan', 'tidakSesuaiSiteplan', 'perluEvaluasiLanjutan'];

    /** Hasil evaluasi yang mewajibkan Rencana Tindak Lanjut (aturan yang sama di Flutter). */
    public const EVALUASI_WAJIB_RTL = ['tidakSesuaiSiteplan', 'perluEvaluasiLanjutan'];

    protected $fillable = [
        'report_number', 'client_uuid', 'assignment_id', 'submission_id', 'officer_id', 'previous_report_id',
        'monitoring_date', 'nama_perumahan', 'lokasi', 'maksud_tujuan',
        'temuan', 'kesimpulan', 'kesepakatan', 'rtl', 'status_hasil_evaluasi',
        'tim_pelaksana', 'pihak_ditemui', 'status', 'version',
        'submit_latitude', 'submit_longitude', 'submitted_at', 'published_at',
        'pdf_path', 'docx_path', 'verification_token',
    ];

    protected function casts(): array
    {
        return [
            'monitoring_date' => 'date',
            'temuan' => 'array',
            'kesimpulan' => 'array',
            'kesepakatan' => 'array',
            'rtl' => 'array',
            'tim_pelaksana' => 'array',
            'pihak_ditemui' => 'array',
            'version' => 'integer',
            'submit_latitude' => 'float',
            'submit_longitude' => 'float',
            'submitted_at' => 'datetime',
            'published_at' => 'datetime',
        ];
    }

    public function assignment(): BelongsTo
    {
        return $this->belongsTo(InspectionAssignment::class, 'assignment_id');
    }

    public function submission(): BelongsTo
    {
        return $this->belongsTo(Submission::class);
    }

    public function officer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'officer_id');
    }

    public function photos(): HasMany
    {
        return $this->hasMany(InspectionReportPhoto::class, 'report_id')->orderBy('position')->orderBy('id');
    }

    public function signatures(): HasMany
    {
        return $this->hasMany(ReportSignature::class, 'report_id');
    }

    public function isDraft(): bool
    {
        return $this->status === 'draft';
    }
}

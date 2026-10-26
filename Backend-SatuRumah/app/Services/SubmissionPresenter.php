<?php

namespace App\Services;

use App\Models\Submission;
use App\Models\SubmissionFile;

/** Bentuk JSON pengajuan untuk aplikasi (stabil; lihat API_SPEC.md bagian 3). */
class SubmissionPresenter
{
    /** @return array<string, mixed> */
    public function summary(Submission $s): array
    {
        $profile = $s->developer?->developerProfile;

        return [
            'id' => $s->id,
            'number' => $s->number,
            'stage' => $s->stage,
            'sub_status' => $s->sub_status,
            'status_tahap' => $s->statusTahap(),
            // Tahap asal perbaikan = tahap saat ini (kontrak bagian 3).
            'tahap_asal_perbaikan' => $s->isInRevision() ? $this->tahapKey($s->stage) : null,
            'current_step' => $s->current_step,
            'version' => $s->version,
            'nama_perumahan' => $profile?->nama_perumahan,
            'nama_pt' => $profile?->nama_pt,
            'submitted_at' => $s->submitted_at?->toIso8601String(),
            'correction_deadline_at' => $s->correction_deadline_at?->toIso8601String(),
            'updated_at' => $s->updated_at?->toIso8601String(),
        ];
    }

    /** @return array<string, mixed> */
    public function detail(Submission $s): array
    {
        $s->loadMissing('developer.developerProfile', 'currentFiles');

        return $this->summary($s) + [
            'npwp' => $s->npwp,
            'luas_lahan' => $s->luas_lahan,
            'jumlah_unit' => $s->jumlah_unit,
            'tipe_perumahan' => $s->tipe_perumahan,
            'developer_profile' => $s->developer?->developerProfile,
            'decision' => $s->decision_number ? [
                'number' => $s->decision_number,
                'date' => $s->decision_date?->toDateString(),
            ] : null,
            'files' => $s->currentFiles->map(fn (SubmissionFile $f) => $this->file($f))->values()->all(),
        ];
    }

    /** @return array<string, mixed> */
    public function file(SubmissionFile $f): array
    {
        return [
            'id' => $f->id,
            'slot_code' => $f->slot_code,
            'version' => $f->version,
            'original_name' => $f->original_name,
            'file_type' => $f->file_type,
            'size_bytes' => $f->size_bytes,
            'status' => $f->status,
            'review_note' => $f->review_note,
            'uploaded_at' => $f->created_at?->toIso8601String(),
        ];
    }

    private function tahapKey(int $stage): string
    {
        return match ($stage) {
            Submission::STAGE_ADMINISTRASI => 'verifikasiAdministrasi',
            Submission::STAGE_TEKNIS => 'verifikasiTeknis',
            Submission::STAGE_SURVEI => 'surveyLapangan',
            Submission::STAGE_PERSETUJUAN => 'persetujuan',
            default => 'verifikasiAdministrasi',
        };
    }
}

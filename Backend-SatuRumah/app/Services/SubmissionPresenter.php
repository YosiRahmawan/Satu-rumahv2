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
            'nama_perumahan' => $s->nama_perumahan ?? $profile?->nama_perumahan,
            'nama_pt' => $profile?->nama_pt,
            'submitted_at' => $s->submitted_at?->toIso8601String(),
            'correction_deadline_at' => $s->correction_deadline_at?->toIso8601String(),
            'updated_at' => $s->updated_at?->toIso8601String(),
        ];
    }

    /** @return array<string, mixed> */
    public function detail(Submission $s): array
    {
        $s->loadMissing('developer.developerProfile', 'currentFiles', 'assignments.officer', 'assignments.members', 'reports');

        return $this->summary($s) + [
            'alamat_proyek' => $s->alamat_proyek ?? $s->developer?->developerProfile?->alamat_perumahan,
            'tipe_pengajuan' => $s->tipe_pengajuan ?? $s->developer?->developerProfile?->tipe_pengajuan,
            'daya_listrik' => $s->daya_listrik,
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
            'survey' => $this->survey($s),
            'survey_reports' => $s->reports->where('status', 'final')->map(fn ($r) => [
                'id' => $r->id,
                'report_number' => $r->report_number,
                'monitoring_date' => $r->monitoring_date?->toDateString(),
                'lokasi' => $r->lokasi,
                'status_hasil_evaluasi' => $r->status_hasil_evaluasi,
                'temuan' => $r->temuan ?? [],
                'kesimpulan' => $r->kesimpulan ?? [],
                'kesepakatan' => $r->kesepakatan ?? [],
                'rtl' => $r->rtl ?? [],
                'tim_pelaksana' => $r->tim_pelaksana ?? [],
                'submitted_at' => $r->submitted_at?->toIso8601String(),
            ])->values()->all(),
        ];
    }

    /**
     * Jadwal survei terkini (yang masih berjalan, atau yang terakhir selesai),
     * ditetapkan Admin. Null bila belum dijadwalkan.
     *
     * @return array<string, mixed>|null
     */
    private function survey(Submission $s): ?array
    {
        $a = $s->assignments->first(fn ($x) => $x->isOpen())
            ?? $s->assignments->first(fn ($x) => $x->status === 'selesai');

        return $a ? [
            'scheduled_date' => $a->scheduled_date?->toDateString(),
            'status' => $a->status,
            'note' => $a->note,
            'team' => $a->team(),
        ] : null;
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

<?php

namespace App\Services;

use App\Models\InspectionAssignment;
use App\Models\InspectionReport;
use App\Models\InspectionReportPhoto;

/** Bentuk JSON tugas dan laporan untuk aplikasi Pengawas (API_SPEC.md bagian 4). */
class ReportPresenter
{
    /** @return array<string, mixed> */
    public function assignment(InspectionAssignment $a): array
    {
        $s = $a->submission;
        $profile = $s?->developer?->developerProfile;

        return [
            'id' => $a->id,
            'status' => $a->status,
            'scheduled_date' => $a->scheduled_date?->toDateString(),
            'note' => $a->note,
            'accepted_at' => $a->accepted_at?->toIso8601String(),
            'submission' => $s ? [
                'id' => $s->id,
                'number' => $s->number,
                'nama_perumahan' => $s->nama_perumahan ?? $profile?->nama_perumahan,
                'nama_pt' => $profile?->nama_pt,
                'alamat_proyek' => $s->alamat_proyek ?? $profile?->alamat_perumahan,
            ] : null,
        ];
    }

    /** @return array<string, mixed> */
    public function summary(InspectionReport $r): array
    {
        return [
            'id' => $r->id,
            'report_number' => $r->report_number,
            'status' => $r->status,
            'version' => $r->version,
            'assignment_id' => $r->assignment_id,
            'submission_id' => $r->submission_id,
            'monitoring_date' => $r->monitoring_date?->toDateString(),
            'nama_perumahan' => $r->nama_perumahan,
            'status_hasil_evaluasi' => $r->status_hasil_evaluasi,
            'photo_count' => $r->relationLoaded('photos') ? $r->photos->count() : $r->photos()->count(),
            'submitted_at' => $r->submitted_at?->toIso8601String(),
        ];
    }

    /** @return array<string, mixed> */
    public function detail(InspectionReport $r): array
    {
        $r->loadMissing('photos');

        return $this->summary($r) + [
            'lokasi' => $r->lokasi,
            'maksud_tujuan' => $r->maksud_tujuan,
            'temuan' => $r->temuan ?? [],
            'kesimpulan' => $r->kesimpulan ?? [],
            'kesepakatan' => $r->kesepakatan ?? [],
            'rtl' => $r->rtl ?? [],
            'tim_pelaksana' => $r->tim_pelaksana ?? [],
            'pihak_ditemui' => $r->pihak_ditemui ?? [],
            'submit_latitude' => $r->submit_latitude,
            'submit_longitude' => $r->submit_longitude,
            'photos' => $r->photos->map(fn (InspectionReportPhoto $p) => $this->photo($p))->values()->all(),
        ];
    }

    /** @return array<string, mixed> */
    public function photo(InspectionReportPhoto $p): array
    {
        return [
            'id' => $p->id,
            'position' => $p->position,
            'size_bytes' => $p->size_bytes,
            'checksum' => $p->checksum,
            'latitude' => $p->latitude,
            'longitude' => $p->longitude,
            'accuracy_m' => $p->accuracy_m,
            'captured_at' => $p->captured_at?->toIso8601String(),
            'address' => $p->address,
            'note' => $p->note,
            'source' => $p->source,
        ];
    }
}

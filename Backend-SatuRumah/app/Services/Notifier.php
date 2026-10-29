<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Submission;
use App\Models\SubmissionEvent;
use App\Models\User;

/**
 * Mencatat peristiwa pengajuan (riwayat) dan mengirim notifikasi dalam aplikasi.
 * Versi 1 hanya menyimpan notifikasi; aplikasi menariknya lewat API (tanpa push).
 */
class Notifier
{
    /** @param array<string, mixed> $meta */
    public function event(Submission $s, ?User $actor, string $type, string $title, ?string $description = null, array $meta = []): SubmissionEvent
    {
        return SubmissionEvent::create([
            'submission_id' => $s->id,
            'actor_id' => $actor?->id,
            'type' => $type,
            'title' => $title,
            'description' => $description,
            'meta' => $meta ?: null,
        ]);
    }

    /** @param array<string, mixed> $data */
    public function toUser(int|User $user, Submission $s, string $type, string $title, ?string $body = null, array $data = []): AppNotification
    {
        return AppNotification::create([
            'user_id' => $user instanceof User ? $user->id : $user,
            'submission_id' => $s->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data ?: null,
        ]);
    }

    /** Pengembang pemilik pengajuan. @param array<string, mixed> $data */
    public function toDeveloper(Submission $s, string $type, string $title, ?string $body = null, array $data = []): AppNotification
    {
        return $this->toUser($s->developer_id, $s, $type, $title, $body, $data);
    }

    /** Semua akun Web Admin aktif. @param array<string, mixed> $data */
    public function toVerifiers(Submission $s, string $type, string $title, ?string $body = null, array $data = []): void
    {
        User::where('role', 'admin')
            ->where('is_active', true)
            ->pluck('id')
            ->each(fn (int $id) => $this->toUser($id, $s, $type, $title, $body, $data));
    }
}

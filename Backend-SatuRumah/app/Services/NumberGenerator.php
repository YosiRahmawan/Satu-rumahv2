<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/** Penomor berurutan dari tabel `number_sequences` (aman dari nomor ganda). */
class NumberGenerator
{
    /** SR-<tahun>-<urut 4 digit>, urut per tahun. */
    public function submissionNumber(?\DateTimeInterface $at = null): string
    {
        $year = ($at ?? now())->format('Y');

        return sprintf('SR-%s-%04d', $year, $this->next("SR-{$year}"));
    }

    private function next(string $key): int
    {
        return DB::transaction(function () use ($key) {
            $row = DB::table('number_sequences')->where('sequence_key', $key)->lockForUpdate()->first();

            if (!$row) {
                DB::table('number_sequences')->insert([
                    'sequence_key' => $key,
                    'last_value' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                return 1;
            }

            $value = $row->last_value + 1;
            DB::table('number_sequences')->where('id', $row->id)->update([
                'last_value' => $value,
                'updated_at' => now(),
            ]);

            return $value;
        });
    }
}

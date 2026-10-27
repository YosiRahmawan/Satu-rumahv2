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

    /**
     * BA Monitoring: 600.2.5/BA-MON/<bulan Romawi>/<tahun>/<urut 3 digit>,
     * urut per bulan (keputusan pemilik produk; sama dengan format di Flutter).
     */
    public function reportNumber(?\DateTimeInterface $at = null): string
    {
        $at ??= now();
        $roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'][(int) $at->format('n') - 1];
        $key = 'BA-MON-' . $at->format('Y-m');

        return sprintf('600.2.5/BA-MON/%s/%s/%03d', $roman, $at->format('Y'), $this->next($key));
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

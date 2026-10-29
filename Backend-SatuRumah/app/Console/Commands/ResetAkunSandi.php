<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class ResetAkunSandi extends Command
{
    protected $signature = 'akun:reset-sandi {email : Email akun}';

    protected $description = 'Darurat: atur ulang sandi akun ke sandi sementara (wajib diganti saat masuk).';

    public function handle(): int
    {
        $user = User::where('email', $this->argument('email'))->first();
        if (!$user) {
            $this->error('Akun dengan email itu tidak ditemukan.');

            return self::FAILURE;
        }

        $sandi = $user->resetSandi();
        $user->forceFill(['is_active' => true])->save();
        $this->info("Sandi sementara untuk {$user->email}: {$sandi}");
        $this->line('Akun diaktifkan dan akan diminta mengganti sandi saat masuk.');

        return self::SUCCESS;
    }
}

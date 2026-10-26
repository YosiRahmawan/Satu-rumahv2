<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(SettingsSeeder::class);
        $this->call(AccountSeeder::class);
        if (app()->environment('local', 'testing')) {
            $this->call(DemoAssignmentSeeder::class);
        }
    }
}

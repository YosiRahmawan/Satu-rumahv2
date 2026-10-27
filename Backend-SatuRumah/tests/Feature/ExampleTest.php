<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * Halaman utama butuh login; /up dipakai pemantau uptime.
     */
    public function test_tamu_diarahkan_ke_login_dan_health_check_hidup(): void
    {
        $this->get('/')->assertRedirect('/login');
        $this->get('/up')->assertStatus(200);
    }
}

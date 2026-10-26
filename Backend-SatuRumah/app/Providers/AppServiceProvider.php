<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Login: 5 percobaan per menit untuk pasangan IP + username.
        RateLimiter::for('api-login', fn (Request $request) => Limit::perMinute(5)
            ->by($request->ip() . '|' . mb_strtolower((string) $request->input('username'))));
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(120)
            ->by($request->user()?->currentAccessToken()?->getKey() ?? $request->ip()));

        \Illuminate\Support\Facades\View::composer('layouts.admin', function ($view) {
            try {
                $unreadCount = \App\Models\Notifikasi::where('is_read', false)->count();
            } catch (\Throwable $e) {
                $unreadCount = 0;
            }
            $view->with('unreadCount', $unreadCount);
        });
    }
}

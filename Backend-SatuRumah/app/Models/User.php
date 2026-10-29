<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'avatar_initials',
        'username',
        'jabatan',
        'phone',
        'is_active',
        'must_change_password',
        'failed_login_attempts',
        'locked_until',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /** Sandi sementara acak: memuat huruf besar, huruf kecil, dan angka. */
    public static function sandiSementara(int $panjang = 12): string
    {
        do {
            $sandi = \Illuminate\Support\Str::password($panjang, symbols: false);
        } while (!preg_match('/[A-Z]/', $sandi) || !preg_match('/[a-z]/', $sandi) || !preg_match('/\d/', $sandi));

        return $sandi;
    }

    /** Memasang sandi sementara, mewajibkan ganti sandi, dan mencabut semua token aplikasi. */
    public function resetSandi(): string
    {
        $sandi = self::sandiSementara();
        $this->forceFill([
            'password' => $sandi, 'must_change_password' => true,
            'failed_login_attempts' => 0, 'locked_until' => null,
        ])->save();
        $this->tokens()->delete();

        return $sandi;
    }

    public function submissions(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Submission::class, 'developer_id');
    }

    public function developerProfile(): HasOne
    {
        return $this->hasOne(DeveloperProfile::class);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
            'must_change_password' => 'boolean',
            'locked_until' => 'datetime',
        ];
    }
}

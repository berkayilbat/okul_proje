<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'role', 'first_name', 'last_name', 'phone', 'password', 'tc_kimlik_no',
        'company_name', 'tax_no', 'profile_image', 'wallet_balance', 'average_rating',
        'birth_date', 'address', 'professions', 'certificates_json',
        'past_workplaces_json', 'is_profile_complete',
    ];

    // Eski tabloda yalnızca created_at var.
    const UPDATED_AT = null;

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'password' => 'hashed',
        ];
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Branch extends Model
{
    protected $fillable = [
        'name',
        'description',
        'location',
        'address',
        'phone_number',
        'email',
        'admin_id',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Get the admin of this branch.
     */
    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    /**
     * Get all users in this branch.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    /**
     * Get all missional communities in this branch.
     */
    public function missionalCommunities(): HasMany
    {
        return $this->hasMany(MC::class);
    }

    /**
     * Get all MCs in this branch (alias for missionalCommunities).
     */
    public function mcs(): HasMany
    {
        return $this->hasMany(MC::class);
    }

    /**
     * Get all active MCs in this branch.
     */
    public function activeMCs(): HasMany
    {
        return $this->hasMany(MC::class)->where('is_active', true);
    }
}

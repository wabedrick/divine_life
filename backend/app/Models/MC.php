<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MC extends Model
{
    use HasFactory;

    protected $table = 'missional_communities';

    protected $fillable = [
        'name',
        'vision',
        'goals',
        'purpose',
        'location',
        'leader_id',
        'leader_phone',
        'branch_id',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Get the leader of this MC.
     */
    public function leader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'leader_id');
    }

    /**
     * Get the branch this MC belongs to.
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * Get all members of this MC.
     */
    public function members(): HasMany
    {
        return $this->hasMany(User::class, 'mc_id');
    }

    /**
     * Get all reports submitted by this MC.
     */
    public function reports(): HasMany
    {
        return $this->hasMany(Report::class, 'mc_id');
    }

    /**
     * Scope to get only active MCs.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Get total members count.
     */
    public function getTotalMembersAttribute(): int
    {
        return $this->members()->count();
    }

    /**
     * Get recent reports.
     */
    public function getRecentReportsAttribute()
    {
        return $this->reports()->latest()->limit(5)->get();
    }

    /**
     * Get this month's reports.
     */
    public function getThisMonthReportsAttribute()
    {
        return $this->reports()
            ->whereYear('week_ending', now()->year)
            ->whereMonth('week_ending', now()->month)
            ->get();
    }
}

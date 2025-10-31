<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'priority',
        'visibility',
        'branch_id',
        'mc_id',
        'created_by',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Get the user who created this announcement.
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get the branch this announcement belongs to.
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * Get the MC this announcement belongs to.
     */
    public function mc(): BelongsTo
    {
        return $this->belongsTo(MC::class);
    }

    /**
     * Scope for active announcements.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
                    ->where(function ($q) {
                        $q->whereNull('expires_at')
                          ->orWhere('expires_at', '>', now());
                    });
    }

    /**
     * Scope for recent announcements.
     */
    public function scopeRecent($query, int $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }

    /**
     * Scope for announcements visible to a specific user.
     */
    public function scopeVisibleToUser($query, User $user)
    {
        return $query->where(function ($q) use ($user) {
            $q->where('visibility', 'all')
              ->orWhere(function ($subQuery) use ($user) {
                  $subQuery->where('visibility', 'branch')
                          ->where('branch_id', $user->branch_id);
              })
              ->orWhere(function ($subQuery) use ($user) {
                  $subQuery->where('visibility', 'mc')
                          ->where('mc_id', $user->mc_id);
              });
        });
    }

    /**
     * Scope by priority.
     */
    public function scopeByPriority($query, string $priority)
    {
        return $query->where('priority', $priority);
    }

    /**
     * Check if announcement is expired.
     */
    public function getIsExpiredAttribute(): bool
    {
        return $this->expires_at && $this->expires_at < now();
    }

    /**
     * Check if announcement is new (created within 24 hours).
     */
    public function getIsNewAttribute(): bool
    {
        return $this->created_at > now()->subDay();
    }
}

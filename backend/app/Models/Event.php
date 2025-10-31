<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'event_date',
        'end_date',
        'location',
        'visibility',
        'branch_id',
        'mc_id',
        'created_by',
        'is_active',
    ];

    protected $casts = [
        'event_date' => 'datetime',
        'end_date' => 'datetime',
        'is_active' => 'boolean',
    ];

    /**
     * Get the user who created this event.
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Get the branch this event belongs to.
     */
    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * Get the MC this event belongs to.
     */
    public function mc(): BelongsTo
    {
        return $this->belongsTo(MC::class);
    }

    /**
     * Scope for active events.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Scope for upcoming events.
     */
    public function scopeUpcoming($query)
    {
        return $query->where('event_date', '>', now());
    }

    /**
     * Scope for events visible to a specific user.
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
     * Check if event is upcoming.
     */
    public function getIsUpcomingAttribute(): bool
    {
        return $this->event_date > now();
    }

    /**
     * Check if event is today.
     */
    public function getIsTodayAttribute(): bool
    {
        return $this->event_date->isToday();
    }
}

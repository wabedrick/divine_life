<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConversationParticipant extends Model
{
    protected $fillable = [
        'conversation_id',
        'user_id',
        'joined_at',
        'left_at',
        'is_admin',
        'can_add_members',
        'notifications_enabled',
        'last_read_at',
        'unread_count',
    ];

    protected $casts = [
        'joined_at' => 'datetime',
        'left_at' => 'datetime',
        'last_read_at' => 'datetime',
        'is_admin' => 'boolean',
        'can_add_members' => 'boolean',
        'notifications_enabled' => 'boolean',
        'unread_count' => 'integer',
    ];

    // Relationships
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->whereNull('left_at');
    }

    public function scopeAdmins($query)
    {
        return $query->where('is_admin', true);
    }

    public function scopeWithNotifications($query)
    {
        return $query->where('notifications_enabled', true);
    }
}

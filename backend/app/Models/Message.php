<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    protected $fillable = [
        'conversation_id',
        'sender_id',
        'sender_name',
        'content',
        'type',
        'status',
        'file_url',
        'file_name',
        'file_size',
        'reply_to_id',
        'metadata',
        'is_encrypted',
        'read_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'is_encrypted' => 'boolean',
        'read_at' => 'datetime',
        'file_size' => 'integer',
    ];

    // Relationships
    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function replyTo(): BelongsTo
    {
        return $this->belongsTo(Message::class, 'reply_to_id');
    }

    // Scopes
    public function scopeForConversation($query, $conversationId)
    {
        return $query->where('conversation_id', $conversationId);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeRecent($query, $limit = 50)
    {
        return $query->orderBy('created_at', 'desc')->limit($limit);
    }

    // Methods
    public function markAsRead(): void
    {
        $this->update(['read_at' => now()]);
    }

    public function updateStatus($status): void
    {
        $this->update(['status' => $status]);
    }

    // Boot method to handle events
    protected static function boot()
    {
        parent::boot();

        static::created(function ($message) {
            // Increment unread count for all participants except sender
            $conversation = $message->conversation;
            $participants = $conversation->participants()->where('user_id', '!=', $message->sender_id)->get();

            foreach ($participants as $participant) {
                $conversation->incrementUnreadCount($participant->id);
            }
        });
    }
}

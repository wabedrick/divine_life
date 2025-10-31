<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\Auth;

class Conversation extends Model
{
    protected $fillable = [
        'name',
        'description',
        'type',
        'avatar',
        'is_muted',
        'is_pinned',
        'created_by',
        'branch_id',
        'mc_id',
        'settings',
    ];

    protected $casts = [
        'is_muted' => 'boolean',
        'is_pinned' => 'boolean',
        'settings' => 'array',
    ];

    protected $appends = [
        'participant_count',
        'unread_count',
        'last_message',
    ];

    // Relationships
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function branch(): BelongsTo
    {
        return $this->belongsTo(Branch::class);
    }

    public function missionalCommunity(): BelongsTo
    {
        return $this->belongsTo(MC::class, 'mc_id');
    }

    public function participants(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'conversation_participants')
            ->withPivot([
                'joined_at',
                'left_at',
                'is_admin',
                'can_add_members',
                'notifications_enabled',
                'last_read_at',
                'unread_count',
            ])
            ->withTimestamps();
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function lastMessage(): HasOne
    {
        return $this->hasOne(Message::class)->latestOfMany();
    }

    // Accessors
    public function getParticipantCountAttribute(): int
    {
        return $this->participants()->count();
    }

    public function getUnreadCountAttribute(): int
    {
        if (!Auth::check()) {
            return 0;
        }

        $participant = $this->participants()
            ->where('user_id', Auth::id())
            ->first();

        return $participant?->pivot->unread_count ?? 0;
    }

    public function getLastMessageAttribute(): ?Message
    {
        // Load the latest message if not already loaded
        if (!$this->relationLoaded('messages')) {
            return $this->messages()->latest()->first();
        }

        // Return the latest message from loaded messages
        return $this->messages->sortByDesc('created_at')->first();
    }

    // Scopes
    public function scopeForUser($query, $userId)
    {
        return $query->whereHas('participants', function ($q) use ($userId) {
            $q->where('user_id', $userId)
                ->whereNull('left_at');
        });
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeForBranch($query, $branchId)
    {
        return $query->where('branch_id', $branchId);
    }

    public function scopeForMC($query, $mcId)
    {
        return $query->where('mc_id', $mcId);
    }

    // Methods
    public function addParticipant($userId, array $options = []): void
    {
        $this->participants()->attach($userId, array_merge([
            'joined_at' => now(),
            'is_admin' => false,
            'can_add_members' => false,
            'notifications_enabled' => true,
        ], $options));
    }

    public function removeParticipant($userId): void
    {
        $this->participants()->updateExistingPivot($userId, [
            'left_at' => now(),
        ]);
    }

    public function markAsRead($userId): void
    {
        $this->participants()->updateExistingPivot($userId, [
            'last_read_at' => now(),
            'unread_count' => 0,
        ]);
    }

    public function incrementUnreadCount($userId): void
    {
        $participant = $this->participants()->where('user_id', $userId)->first();
        if ($participant) {
            $this->participants()->updateExistingPivot($userId, [
                'unread_count' => $participant->pivot->unread_count + 1,
            ]);
        }
    }

    // Static methods for category-based conversations
    public static function getOrCreateBranchConversation($branchId): self
    {
        return self::firstOrCreate(
            [
                'type' => 'branch',
                'branch_id' => $branchId,
            ],
            [
                'name' => Branch::find($branchId)->name . ' Chat',
                'description' => 'Branch-wide conversation',
                'created_by' => Auth::id(),
            ]
        );
    }

    public static function getOrCreateMCConversation($mcId): self
    {
        return self::firstOrCreate(
            [
                'type' => 'mc',
                'mc_id' => $mcId,
            ],
            [
                'name' => MC::find($mcId)->name . ' Chat',
                'description' => 'MC conversation',
                'created_by' => Auth::id(),
            ]
        );
    }
}

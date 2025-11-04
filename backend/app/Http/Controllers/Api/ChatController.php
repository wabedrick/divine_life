<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class ChatController extends Controller
{
    /**
     * Get conversations for the authenticated user
     */
    public function getConversations(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();
        $type = $request->get('type'); // all, group, mc, branch

        // Build query with strict access control for member users
        $query = Conversation::with(['participants', 'lastMessage', 'branch', 'missionalCommunity'])
            ->orderBy('updated_at', 'desc');

        // For member role users, apply strict access control
        if ($user->role === 'member') {
            if ($type === 'branch') {
                // Members can only see their own branch conversations
                $query->where('type', 'branch')
                    ->where('branch_id', $user->branch_id);
            } elseif ($type === 'mc') {
                // Members can only see MC conversations if they're assigned to an MC
                if ($user->mc_id) {
                    $query->where('type', 'mc')
                        ->where('mc_id', $user->mc_id);
                } else {
                    // No MC assigned, return empty result
                    $query->whereRaw('1 = 0');
                }
            } elseif ($type === 'group') {
                // Members can see group chats they're participants in
                $query->where('type', 'group')
                    ->whereHas('participants', function ($subQ) use ($user) {
                        $subQ->where('user_id', $user->id)->whereNull('left_at');
                    });
            } elseif ($type === 'individual') {
                // Members can see individual chats they're participants in
                $query->where('type', 'individual')
                    ->whereHas('participants', function ($subQ) use ($user) {
                        $subQ->where('user_id', $user->id)->whereNull('left_at');
                    });
            } elseif ($type === 'announcement') {
                // Members can always see announcement/global conversations
                $query->where('type', 'announcement');
            } else {
                // 'all' or no type - show all accessible conversations
                $query->where(function ($q) use ($user) {
                    // Own branch conversations
                    $q->orWhere(function ($branchQ) use ($user) {
                        $branchQ->where('type', 'branch')
                            ->where('branch_id', $user->branch_id);
                    });

                    // Own MC conversations (if assigned to MC)
                    if ($user->mc_id) {
                        $q->orWhere(function ($mcQ) use ($user) {
                            $mcQ->where('type', 'mc')
                                ->where('mc_id', $user->mc_id);
                        });
                    }

                    // Group/individual chats they're participants in
                    $q->orWhere(function ($groupQ) use ($user) {
                        $groupQ->whereIn('type', ['group', 'individual'])
                            ->whereHas('participants', function ($subQ) use ($user) {
                                $subQ->where('user_id', $user->id)->whereNull('left_at');
                            });
                    });

                    // Include announcement/global conversations for all users
                    $q->orWhere('type', 'announcement');
                });
            }
        } else {
            // For admin users, apply the existing broader access control
            if ($type === 'branch' || $type === 'all') {
                // Admin users can see their branch + HQ
                $branchQuery = Conversation::where('type', 'branch')
                    ->where(function ($q) use ($user) {
                        $q->where('branch_id', $user->branch_id); // User's branch

                        // Add HQ branch for admins (Divine Life - HQ)
                        if ($user->isSuperAdmin()) {
                            $hqBranch = \App\Models\Branch::where('name', 'LIKE', '%Divine Life- HQ%')->first();
                            if ($hqBranch) {
                                $q->orWhere('branch_id', $hqBranch->id);
                            }
                        }
                    });

                if ($type === 'branch') {
                    $query = $branchQuery;
                } else {
                    $query->where(function ($q) use ($branchQuery) {
                        $q->whereIn('id', $branchQuery->pluck('id'));
                    });
                }
            }

            if ($type === 'mc' || $type === 'all') {
                // MC conversations access control for admins
                $mcQuery = Conversation::where('type', 'mc');

                if ($user->isBranchAdmin() || $user->isSuperAdmin()) {
                    // Branch admins can see all MCs under their branch
                    $mcQuery->whereHas('missionalCommunity', function ($q) use ($user) {
                        $q->where('branch_id', $user->branch_id);
                    });
                } else {
                    // MC leaders can see their own MC
                    $mcQuery->where('mc_id', $user->mc_id);
                }

                if ($type === 'mc') {
                    $query = $mcQuery;
                } else {
                    $query->orWhereIn('id', $mcQuery->pluck('id'));
                }
            }

            // If no specific type, ensure user has access to the conversations
            if (!$type || $type === 'all') {
                $query->where(function ($q) use ($user) {
                    $q->whereHas('participants', function ($subQ) use ($user) {
                        $subQ->where('user_id', $user->id)->whereNull('left_at');
                    });
                });
            }
        }

        $conversations = $query->get()->map(function ($conversation) use ($user) {
            return [
                'id' => $conversation->id,
                'name' => $this->getConversationName($conversation, $user),
                'description' => $conversation->description,
                'type' => $conversation->type,
                'participants' => $conversation->participants->map(function ($participant) {
                    return [
                        'id' => $participant->id,
                        'name' => $participant->name,
                        'email' => $participant->email,
                        'avatar' => $participant->avatar,
                        'is_online' => $participant->is_online ?? false,
                    ];
                }),
                'last_message' => $conversation->lastMessage ? [
                    'id' => $conversation->lastMessage->id,
                    'sender_id' => $conversation->lastMessage->sender_id,
                    'sender_name' => $conversation->lastMessage->sender_name,
                    'content' => $conversation->lastMessage->content,
                    'type' => $conversation->lastMessage->type,
                    'status' => $conversation->lastMessage->status,
                    'created_at' => $conversation->lastMessage->created_at,
                    'read_at' => $conversation->lastMessage->read_at,
                ] : null,
                'unread_count' => $conversation->getUnreadCountAttribute(),
                'is_muted' => $conversation->is_muted,
                'is_pinned' => $conversation->is_pinned,
                'created_at' => $conversation->created_at,
                'updated_at' => $conversation->updated_at,
                'avatar' => $conversation->avatar,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $conversations,
        ]);
    }

    /**
     * Get messages for a specific conversation
     */
    public function getMessages(Request $request, $conversationId): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();
        $page = $request->get('page', 1);
        $limit = $request->get('limit', 50);

        // Check if user is participant in this conversation
        $conversation = Conversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return response()->json([
                'success' => false,
                'message' => 'Conversation not found or access denied',
            ], 404);
        }

        $messages = Message::forConversation($conversationId)
            ->with(['sender', 'replyTo'])
            ->orderBy('created_at', 'desc')
            ->skip(($page - 1) * $limit)
            ->take($limit)
            ->get()
            ->reverse()
            ->values();

        // Mark messages as read
        $conversation->markAsRead($user->id);

        return response()->json([
            'success' => true,
            'data' => $messages->map(function ($message) {
                return [
                    'id' => $message->id,
                    'conversation_id' => $message->conversation_id,
                    'sender_id' => $message->sender_id,
                    'sender_name' => $message->sender_name,
                    'content' => $message->content,
                    'type' => $message->type,
                    'status' => $message->status,
                    'file_url' => $message->file_url,
                    'file_name' => $message->file_name,
                    'file_size' => $message->file_size,
                    'reply_to_id' => $message->reply_to_id,
                    'metadata' => $message->metadata,
                    'created_at' => $message->created_at,
                    'read_at' => $message->read_at,
                    'reply_to' => $message->replyTo ? [
                        'id' => $message->replyTo->id,
                        'content' => $message->replyTo->content,
                        'sender_name' => $message->replyTo->sender_name,
                    ] : null,
                ];
            }),
        ]);
    }

    /**
     * Send a message to a conversation
     */
    public function sendMessage(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'conversation_id' => 'required|exists:conversations,id',
            'content' => 'required|string|max:5000',
            'type' => 'in:text,image,file,audio,video,location,system',
            'reply_to_id' => 'nullable|exists:messages,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        /** @var User $user */
        $user = Auth::user();
        $conversationId = $request->conversation_id;

        // Check if user is participant in this conversation
        $conversation = Conversation::forUser($user->id)->find($conversationId);

        if (!$conversation) {
            return response()->json([
                'success' => false,
                'message' => 'Conversation not found or access denied',
            ], 404);
        }

        $message = Message::create([
            'conversation_id' => $conversationId,
            'sender_id' => $user->id,
            'sender_name' => $user->name,
            'content' => $request->get('content'),
            'client_id' => $request->get('client_id'),
            'type' => $request->get('type', 'text'),
            'status' => 'sent',
            'reply_to_id' => $request->get('reply_to_id'),
        ]);

        // Update conversation's updated_at timestamp
        $conversation->touch();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $message->id,
                'conversation_id' => $message->conversation_id,
                'sender_id' => $message->sender_id,
                'sender_name' => $message->sender_name,
                'content' => $message->content,
                'type' => $message->type,
                'status' => $message->status,
                'created_at' => $message->created_at,
                'reply_to_id' => $message->reply_to_id,
                // Echo client_id if client provided it so clients can reconcile
                // optimistic messages with server-created records.
                'client_id' => $request->get('client_id'),
            ],
        ]);
    }

    /**
     * Update (edit) a message's content. Only the original sender may edit a
     * message and only within 2 minutes of creation. Returns the updated message.
     */
    public function updateMessage(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'content' => 'required|string|max:5000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        /** @var User $user */
        $user = Auth::user();

        $message = Message::find($id);
        // Try to resolve by primary id first; if not found, attempt to find by
        // client-generated id (optimistic id) passed either in the URL or body.
        $message = Message::find($id) ?? Message::where('client_id', $id)->first();
        if (!$message && $request->has('client_id')) {
            $message = Message::where('client_id', $request->get('client_id'))->first();
        }

        if (!$message) {
            return response()->json(['success' => false, 'message' => 'Message not found'], 404);
        }

        // Only sender can edit and only within 2 minutes
        if ($message->sender_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Permission denied'], 403);
        }

        $createdAt = $message->created_at;
        $now = now();
        if ($now->diffInMinutes($createdAt) > 2) {
            return response()->json(['success' => false, 'message' => 'Edit window expired'], 403);
        }

        $message->content = $request->get('content');
        $message->updated_at = now();
        $message->save();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $message->id,
                'conversation_id' => $message->conversation_id,
                'sender_id' => $message->sender_id,
                'sender_name' => $message->sender_name,
                'content' => $message->content,
                'type' => $message->type,
                'status' => $message->status,
                'created_at' => $message->created_at,
                'updated_at' => $message->updated_at,
                'client_id' => $message->client_id,
            ],
        ]);
    }

    /**
     * Delete a message. The sender may delete at any time. Admins may delete any message.
     */
    public function deleteMessage(Request $request, $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Resolve by primary id or client-generated id (optimistic id)
        $message = Message::find($id) ?? Message::where('client_id', $id)->first();
        if (!$message && $request->has('client_id')) {
            $message = Message::where('client_id', $request->get('client_id'))->first();
        }

        if (!$message) {
            // Treat as success to simplify client behavior when message is
            // already absent on the server (or not yet persisted).
            return response()->json(['success' => true, 'message' => 'Message deleted'], 200);
        }

        // Permission checks
        if ($message->sender_id === $user->id) {
            // Sender can delete
        } else if ($user->isSuperAdmin()) {
            // Super admin can delete
        } else if ($user->isBranchAdmin()) {
            // Branch admin can delete if sender in same branch
            $sender = $message->sender;
            if (!$sender || $sender->branch_id !== $user->branch_id) {
                return response()->json(['success' => false, 'message' => 'Permission denied'], 403);
            }
        } else if ($user->isMCLeader()) {
            // MC leader can delete if sender in same MC
            $sender = $message->sender;
            if (!$sender || $sender->mc_id !== $user->mc_id) {
                return response()->json(['success' => false, 'message' => 'Permission denied'], 403);
            }
        } else {
            return response()->json(['success' => false, 'message' => 'Permission denied'], 403);
        }

        try {
            $message->delete();
            return response()->json(['success' => true, 'message' => 'Message deleted'], 200);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to delete message'], 500);
        }
    }

    /**
     * Create or get category-based conversation (Branch/MC)
     */
    public function getOrCreateCategoryConversation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:branch,mc',
            'category_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        /** @var User $user */
        $user = Auth::user();
        $type = $request->type;
        $categoryId = $request->category_id;

        // Check user access to the category - strict access control for member users
        if ($type === 'branch') {
            // All users can only access their own branch conversations
            if ($user->branch_id !== $categoryId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Access denied: You can only access conversations for your own branch',
                ], 403);
            }
        }

        if ($type === 'mc') {
            $canAccess = false;

            if ($user->role === 'member') {
                // Members can only access their own MC
                $canAccess = ($user->mc_id === $categoryId);
            } else if ($user->isMCLeader()) {
                // MC Leaders can access conversations for their MC
                $canAccess = ($user->mc_id === $categoryId);
            } else if ($user->isBranchAdmin() || $user->isSuperAdmin()) {
                // Branch Admins can access MCs in their branch
                if ($user->mc_id === $categoryId) {
                    $canAccess = true;
                } else {
                    // Check if MC belongs to user's branch
                    $mc = \App\Models\MC::find($categoryId);
                    if ($mc && $mc->branch_id === $user->branch_id) {
                        $canAccess = true;
                    }
                }
            }

            if (!$canAccess) {
                $message = $user->role === 'member'
                    ? 'Access denied: You can only access conversations for your own MC'
                    : 'Access denied to this MC conversation';

                return response()->json([
                    'success' => false,
                    'message' => $message,
                ], 403);
            }
        }

        // Get or create conversation
        if ($type === 'branch') {
            $conversation = Conversation::getOrCreateBranchConversation($categoryId);

            // Add all branch users as participants
            $branchUsers = User::where('branch_id', $categoryId)->get();
            foreach ($branchUsers as $branchUser) {
                if (!$conversation->participants()->where('user_id', $branchUser->id)->exists()) {
                    $conversation->addParticipant($branchUser->id);
                }
            }
        } else {
            $conversation = Conversation::getOrCreateMCConversation($categoryId);

            // Add all MC members as participants
            $mcUsers = User::where('mc_id', $categoryId)->get();

            foreach ($mcUsers as $mcUser) {
                if (!$conversation->participants()->where('user_id', $mcUser->id)->exists()) {
                    $conversation->addParticipant($mcUser->id);
                }
            }
        }

        $conversation->load(['participants', 'lastMessage']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $conversation->id,
                'name' => $conversation->name,
                'description' => $conversation->description,
                'type' => $conversation->type,
                'participants' => $conversation->participants->map(function ($participant) {
                    return [
                        'id' => $participant->id,
                        'name' => $participant->name,
                        'email' => $participant->email,
                        'avatar' => $participant->avatar,
                    ];
                }),
                'created_at' => $conversation->created_at,
                'updated_at' => $conversation->updated_at,
            ],
        ]);
    }

    /**
     * Create a new group conversation
     */
    public function createConversation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'type' => 'required|in:individual,group,mc,branch,announcement',
            // participant_ids are required for group/individual types but optional for branch/mc/announcement
            'participant_ids' => 'nullable|array',
            'participant_ids.*' => 'exists:users,id',
            'branch_id' => 'nullable|exists:branches,id',
            'mc_id' => 'nullable|exists:missional_communities,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors(),
            ], 422);
        }

        /** @var User $user */
        $user = Auth::user();

        // Permission checks based on conversation type
        $type = $request->type;

        // Only super admins can create announcement/global conversations
        if ($type === 'announcement' && !$user->isSuperAdmin()) {
            return response()->json(['success' => false, 'message' => 'Permission denied: only super admins can create global announcements'], 403);
        }

        // Branch conversations: only branch admins or super admin can create for a branch
        if ($type === 'branch') {
            $branchId = $request->branch_id;
            if (!$branchId) {
                return response()->json(['success' => false, 'message' => 'branch_id is required for branch conversations'], 422);
            }
            if (!($user->isSuperAdmin() || $user->isBranchAdmin())) {
                return response()->json(['success' => false, 'message' => 'Permission denied: only branch admins or super admins can create branch conversations'], 403);
            }
            // If branch admin ensure they belong to the branch
            if ($user->isBranchAdmin() && $user->branch_id !== (int) $branchId) {
                return response()->json(['success' => false, 'message' => 'Permission denied: you can only create conversations for your own branch'], 403);
            }
        }

        // MC conversations: only MC leaders, branch admins (for MCs in their branch), or super admins
        if ($type === 'mc') {
            $mcId = $request->mc_id;
            if (!$mcId) {
                return response()->json(['success' => false, 'message' => 'mc_id is required for mc conversations'], 422);
            }
            $canCreateMC = false;
            if ($user->isSuperAdmin()) {
                $canCreateMC = true;
            } elseif ($user->isMCLeader() && $user->mc_id === (int) $mcId) {
                $canCreateMC = true;
            } elseif ($user->isBranchAdmin()) {
                // allow branch admin if MC belongs to their branch
                $mc = \App\Models\MC::find($mcId);
                if ($mc && $mc->branch_id === $user->branch_id) {
                    $canCreateMC = true;
                }
            }
            if (!$canCreateMC) {
                return response()->json(['success' => false, 'message' => 'Permission denied: cannot create MC conversation'], 403);
            }
        }

        $conversationData = [
            'name' => $request->name,
            'description' => $request->description,
            'type' => $request->type,
            'created_by' => $user->id,
        ];

        // Add branch_id or mc_id if provided
        if ($request->branch_id) {
            $conversationData['branch_id'] = $request->branch_id;
        }
        if ($request->mc_id) {
            $conversationData['mc_id'] = $request->mc_id;
        }

        // Handle category-based conversations and permissions
        if ($type === 'branch') {
            $branchId = $request->branch_id;
            // Use helper to get or create a branch conversation
            $conversation = Conversation::getOrCreateBranchConversation($branchId);

            // Add all branch users as participants
            $branchUsers = User::where('branch_id', $branchId)->get();
            foreach ($branchUsers as $branchUser) {
                if (!$conversation->participants()->where('user_id', $branchUser->id)->exists()) {
                    $conversation->addParticipant($branchUser->id);
                }
            }
        } elseif ($type === 'mc') {
            $mcId = $request->mc_id;
            $conversation = Conversation::getOrCreateMCConversation($mcId);

            // Add all MC members as participants
            $mcUsers = User::where('mc_id', $mcId)->get();
            foreach ($mcUsers as $mcUser) {
                if (!$conversation->participants()->where('user_id', $mcUser->id)->exists()) {
                    $conversation->addParticipant($mcUser->id);
                }
            }
        } elseif ($type === 'announcement') {
            // Global announcement: create a single announcement conversation
            $conversation = Conversation::create($conversationData);

            // Add all users as participants so announcements are visible to everyone
            $allUsers = User::all();
            foreach ($allUsers as $u) {
                if (!$conversation->participants()->where('user_id', $u->id)->exists()) {
                    $conversation->addParticipant($u->id);
                }
            }
        } else {
            // Group or individual: participant_ids must be provided
            if (empty($request->participant_ids) || !is_array($request->participant_ids)) {
                return response()->json(['success' => false, 'message' => 'participant_ids is required for group or individual conversations'], 422);
            }

            $conversation = Conversation::create($conversationData);

            // Add creator as admin participant
            $conversation->addParticipant($user->id, [
                'is_admin' => true,
                'can_add_members' => true,
            ]);

            // Add other participants
            foreach ($request->participant_ids as $participantId) {
                if ($participantId != $user->id) {
                    $conversation->addParticipant($participantId);
                }
            }
        }

        $conversation->load(['participants', 'lastMessage']);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $conversation->id,
                'name' => $conversation->name,
                'description' => $conversation->description,
                'type' => $conversation->type,
                'participants' => $conversation->participants->map(function ($participant) {
                    return [
                        'id' => $participant->id,
                        'name' => $participant->name,
                        'email' => $participant->email,
                        'avatar' => $participant->avatar,
                    ];
                }),
                'created_at' => $conversation->created_at,
            ],
        ]);
    }

    /**
     * Get conversation name based on type and user
     */
    private function getConversationName(Conversation $conversation, User $user): string
    {
        if ($conversation->type === 'individual' && $conversation->participants->count() === 2) {
            $otherUser = $conversation->participants->where('id', '!=', $user->id)->first();
            return $otherUser ? $otherUser->name : 'Unknown User';
        }

        return $conversation->name;
    }
}

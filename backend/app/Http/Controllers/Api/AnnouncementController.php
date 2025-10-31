<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use App\Models\User;
use App\Models\Branch;
use App\Models\MC;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class AnnouncementController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of announcements with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = Announcement::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active();

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('title', 'LIKE', "%{$search}%")
                  ->orWhere('content', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('priority')) {
            $query->byPriority($request->get('priority'));
        }

        if ($request->filled('visibility')) {
            $query->where('visibility', $request->get('visibility'));
        }

        if ($request->filled('branch_id')) {
            $query->where('branch_id', $request->get('branch_id'));
        }

        if ($request->filled('mc_id')) {
            $query->where('mc_id', $request->get('mc_id'));
        }

        if ($request->filled('recent_days')) {
            $query->recent($request->get('recent_days'));
        }

        // Sort options
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $announcements = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'announcements' => $announcements->items(),
            'pagination' => [
                'current_page' => $announcements->currentPage(),
                'last_page' => $announcements->lastPage(),
                'per_page' => $announcements->perPage(),
                'total' => $announcements->total()
            ]
        ]);
    }

    /**
     * Store a newly created announcement
     */
    public function store(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only MC leaders and higher can create announcements
        if (!$user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'content' => 'required|string|max:5000',
            'priority' => 'required|in:low,normal,high,urgent',
            'visibility' => 'required|in:all,branch,mc',
            'branch_id' => 'nullable|exists:branches,id',
            'mc_id' => 'nullable|exists:missional_communities,id',
            'expires_at' => 'nullable|date|after:now',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Set visibility constraints based on user role
        if ($user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            // MC leaders can only create announcements for their MC or branch
            if ($data['visibility'] === 'all') {
                return response()->json(['error' => 'MC leaders cannot create announcements visible to all'], 403);
            }

            if ($data['visibility'] === 'mc' && (!isset($data['mc_id']) || $data['mc_id'] !== $user->mc_id)) {
                return response()->json(['error' => 'Can only create MC announcements for your own MC'], 403);
            }

            if ($data['visibility'] === 'branch') {
                $data['branch_id'] = $user->branch_id;
            }
        } elseif ($user->isBranchAdmin() && !$user->isSuperAdmin()) {
            // Branch admins can create announcements for their branch or MCs in their branch
            if ($data['visibility'] === 'branch') {
                $data['branch_id'] = $user->branch_id;
            }

            if ($data['visibility'] === 'mc' && isset($data['mc_id'])) {
                $mc = MC::find($data['mc_id']);
                if (!$mc || $mc->branch_id !== $user->branch_id) {
                    return response()->json(['error' => 'Can only create announcements for MCs in your branch'], 403);
                }
            }
        }

        // Validate branch/MC constraints
        if ($data['visibility'] === 'branch' && !isset($data['branch_id'])) {
            return response()->json(['error' => 'Branch ID is required for branch visibility'], 422);
        }

        if ($data['visibility'] === 'mc' && !isset($data['mc_id'])) {
            return response()->json(['error' => 'MC ID is required for MC visibility'], 422);
        }

        $data['created_by'] = $user->id;
        $data['is_active'] = $data['is_active'] ?? true;

        $announcement = Announcement::create($data);
        $announcement->load(['createdBy', 'branch', 'mc']);

        return response()->json([
            'message' => 'Announcement created successfully',
            'announcement' => $announcement
        ], 201);
    }

    /**
     * Display the specified announcement
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $announcement = Announcement::with(['createdBy', 'branch', 'mc'])->find($id);

        if (!$announcement) {
            return response()->json(['error' => 'Announcement not found'], 404);
        }

        // Check visibility
        $canView = Announcement::where('id', $id)->visibleToUser($user)->exists();

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json(['announcement' => $announcement]);
    }

    /**
     * Update the specified announcement
     */
    public function update(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $announcement = Announcement::find($id);

        if (!$announcement) {
            return response()->json(['error' => 'Announcement not found'], 404);
        }

        // Role-based access control
        $canUpdate = false;

        if ($user->isSuperAdmin()) {
            $canUpdate = true;
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can update announcements in their branch or created by them
            $canUpdate = $announcement->created_by === $user->id ||
                        ($announcement->branch_id === $user->branch_id) ||
                        ($announcement->mc && $announcement->mc->branch_id === $user->branch_id);
        } elseif ($user->isMCLeader()) {
            // MC leaders can update announcements they created
            $canUpdate = $announcement->created_by === $user->id;
        }

        if (!$canUpdate) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'content' => 'sometimes|string|max:5000',
            'priority' => 'sometimes|in:low,normal,high,urgent',
            'visibility' => 'sometimes|in:all,branch,mc',
            'branch_id' => 'nullable|exists:branches,id',
            'mc_id' => 'nullable|exists:missional_communities,id',
            'expires_at' => 'nullable|date',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Apply same visibility constraints as create
        if (isset($data['visibility'])) {
            if ($user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
                if ($data['visibility'] === 'all') {
                    return response()->json(['error' => 'MC leaders cannot set visibility to all'], 403);
                }
            }
        }

        $announcement->update($data);
        $announcement->load(['createdBy', 'branch', 'mc']);

        return response()->json([
            'message' => 'Announcement updated successfully',
            'announcement' => $announcement
        ]);
    }

    /**
     * Remove the specified announcement from storage
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $announcement = Announcement::find($id);

        if (!$announcement) {
            return response()->json(['error' => 'Announcement not found'], 404);
        }

        // Role-based access control
        $canDelete = false;

        if ($user->isSuperAdmin()) {
            $canDelete = true;
        } elseif ($user->isBranchAdmin()) {
            $canDelete = $announcement->created_by === $user->id ||
                        ($announcement->branch_id === $user->branch_id) ||
                        ($announcement->mc && $announcement->mc->branch_id === $user->branch_id);
        } elseif ($user->isMCLeader()) {
            $canDelete = $announcement->created_by === $user->id;
        }

        if (!$canDelete) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $announcement->delete();

        return response()->json(['message' => 'Announcement deleted successfully']);
    }

    /**
     * Get recent announcements
     */
    public function recent(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $days = $request->get('days', 7); // Default to last 7 days

        $announcements = Announcement::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active()
            ->recent($days)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['recent_announcements' => $announcements]);
    }

    /**
     * Get urgent announcements
     */
    public function urgent(): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $announcements = Announcement::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active()
            ->byPriority('urgent')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['urgent_announcements' => $announcements]);
    }

    /**
     * Get announcements by priority
     */
    public function byPriority(Request $request, string $priority): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        if (!in_array($priority, ['low', 'normal', 'high', 'urgent'])) {
            return response()->json(['error' => 'Invalid priority'], 422);
        }

        $announcements = Announcement::with(['createdBy', 'branch', 'mc'])
            ->visibleToUser($user)
            ->active()
            ->byPriority($priority)
            ->orderBy('created_at', 'desc')
            ->paginate($request->get('per_page', 15));

        return response()->json([
            'announcements' => $announcements->items(),
            'priority' => $priority,
            'pagination' => [
                'current_page' => $announcements->currentPage(),
                'last_page' => $announcements->lastPage(),
                'per_page' => $announcements->perPage(),
                'total' => $announcements->total()
            ]
        ]);
    }

    /**
     * Mark announcement as read (placeholder for future read tracking)
     */
    public function markAsRead(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $announcement = Announcement::find($id);

        if (!$announcement) {
            return response()->json(['error' => 'Announcement not found'], 404);
        }

        // Check visibility
        $canView = Announcement::where('id', $id)->visibleToUser($user)->exists();

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // For now, just return success. In the future, this could track read status
        return response()->json(['message' => 'Announcement marked as read']);
    }
}

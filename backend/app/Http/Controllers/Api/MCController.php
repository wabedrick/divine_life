<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MC;
use App\Models\User;
use App\Models\Branch;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class MCController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of MCs with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = MC::with(['leader', 'branch', 'members']);

        // Role-based access control
        if ($user->isBranchAdmin()) {
            // Branch admins can only see MCs in their branch
            $query->where('branch_id', $user->branch_id);
        } elseif ($user->isMCLeader()) {
            // MC leaders can only see their own MC
            $query->where('leader_id', $user->id);
        } elseif ($user->isMember()) {
            // Members can only see their own MC
            if ($user->mc_id) {
                $query->where('id', $user->mc_id);
            } else {
                // Members without MC can't see any MCs
                $query->whereRaw('1 = 0');
            }
        }

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('vision', 'LIKE', "%{$search}%")
                  ->orWhere('purpose', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('branch_id')) {
            $query->where('branch_id', $request->get('branch_id'));
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        if ($request->filled('leader_id')) {
            $query->where('leader_id', $request->get('leader_id'));
        }

        // Sort options
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $mcs = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'mcs' => $mcs->items(),
            'pagination' => [
                'current_page' => $mcs->currentPage(),
                'last_page' => $mcs->lastPage(),
                'per_page' => $mcs->perPage(),
                'total' => $mcs->total()
            ]
        ]);
    }

    /**
     * Store a newly created MC
     */
    public function store(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only super admins and branch admins can create MCs
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'vision' => 'nullable|string|max:1000',
            'goals' => 'nullable|string|max:1000',
            'purpose' => 'nullable|string|max:1000',
            'location' => 'nullable|string|max:255',
            'leader_id' => 'required|exists:users,id',
            'leader_phone' => 'nullable|string|max:20',
            'branch_id' => 'required|exists:branches,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Role-based restrictions
        if ($user->isBranchAdmin()) {
            // Branch admin can only create MCs in their branch
            $data['branch_id'] = $user->branch_id;
        }

        // Validate that the leader belongs to the specified branch
        $leader = User::find($data['leader_id']);
        if ($leader->branch_id !== (int)$data['branch_id']) {
            return response()->json(['error' => 'Leader must belong to the specified branch'], 422);
        }

        // Validate leader role
        if (!in_array($leader->role, ['mc_leader', 'branch_admin', 'super_admin'])) {
            return response()->json(['error' => 'User must have mc_leader role or higher'], 422);
        }

        $data['is_active'] = $data['is_active'] ?? true;

        $mc = MC::create($data);

        // Update the leader's MC assignment
        $leader->update(['mc_id' => $mc->id]);

        $mc->load(['leader', 'branch', 'members']);

        return response()->json([
            'message' => 'MC created successfully',
            'mc' => $mc
        ], 201);
    }

    /**
     * Display the specified MC
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $mc = MC::with(['leader', 'branch', 'members', 'reports'])->find($id);

        if (!$mc) {
            return response()->json(['error' => 'MC not found'], 404);
        }

        // Role-based access control
        $canView = false;

        if ($user->isSuperAdmin()) {
            $canView = true;
        } elseif ($user->isBranchAdmin()) {
            $canView = $user->branch_id === $mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canView = $user->id === $mc->leader_id;
        } elseif ($user->isMember()) {
            $canView = $user->mc_id === $mc->id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json(['mc' => $mc]);
    }

    /**
     * Update the specified MC
     */
    public function update(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $mc = MC::find($id);

        if (!$mc) {
            return response()->json(['error' => 'MC not found'], 404);
        }

        // Role-based access control
        $canUpdate = false;

        if ($user->isSuperAdmin()) {
            $canUpdate = true;
        } elseif ($user->isBranchAdmin()) {
            $canUpdate = $user->branch_id === $mc->branch_id;
        } elseif ($user->isMCLeader()) {
            // MC leaders can update some fields of their own MC
            $canUpdate = $user->id === $mc->leader_id;
        }

        if (!$canUpdate) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $rules = [
            'name' => 'sometimes|string|max:255',
            'vision' => 'nullable|string|max:1000',
            'goals' => 'nullable|string|max:1000',
            'purpose' => 'nullable|string|max:1000',
            'location' => 'nullable|string|max:255',
            'leader_phone' => 'nullable|string|max:20',
        ];

        // Admin-only fields
        if ($user->isSuperAdmin() || $user->isBranchAdmin()) {
            $rules['leader_id'] = 'sometimes|exists:users,id';
            $rules['branch_id'] = 'sometimes|exists:branches,id';
            $rules['is_active'] = 'sometimes|boolean';
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Additional validations for admin-only updates
        if (isset($data['leader_id'])) {
            $leader = User::find($data['leader_id']);
            $branchId = $data['branch_id'] ?? $mc->branch_id;

            if ($leader->branch_id !== (int)$branchId) {
                return response()->json(['error' => 'Leader must belong to the specified branch'], 422);
            }

            if (!in_array($leader->role, ['mc_leader', 'branch_admin', 'super_admin'])) {
                return response()->json(['error' => 'User must have mc_leader role or higher'], 422);
            }
        }

        // Role-based restrictions for branch updates
        if ($user->isBranchAdmin() && isset($data['branch_id'])) {
            if ((int)$data['branch_id'] !== $user->branch_id) {
                return response()->json(['error' => 'Cannot move MC to different branch'], 422);
            }
        }

        $oldLeaderId = $mc->leader_id;
        $mc->update($data);

        // Update leader MC assignment if leader changed
        if (isset($data['leader_id']) && $data['leader_id'] !== $oldLeaderId) {
            // Remove old leader's MC assignment
            if ($oldLeaderId) {
                User::where('id', $oldLeaderId)->update(['mc_id' => null]);
            }
            // Assign new leader
            User::where('id', $data['leader_id'])->update(['mc_id' => $mc->id]);
        }

        $mc->load(['leader', 'branch', 'members']);

        return response()->json([
            'message' => 'MC updated successfully',
            'mc' => $mc
        ]);
    }

    /**
     * Remove the specified MC from storage
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $mc = MC::find($id);

        if (!$mc) {
            return response()->json(['error' => 'MC not found'], 404);
        }

        // Only super admins and branch admins can delete MCs
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        if ($user->isBranchAdmin() && $user->branch_id !== $mc->branch_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Check if MC has members
        if ($mc->members()->count() > 0) {
            return response()->json([
                'error' => 'Cannot delete MC with existing members. Please reassign members first.'
            ], 422);
        }

        // Remove leader's MC assignment
        if ($mc->leader_id) {
            User::where('id', $mc->leader_id)->update(['mc_id' => null]);
        }

        $mc->delete();

        return response()->json(['message' => 'MC deleted successfully']);
    }

    /**
     * Get members of a specific MC
     */
    public function getMembers(string $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $mc = MC::find($id);

        if (!$mc) {
            return response()->json(['error' => 'MC not found'], 404);
        }

        // Role-based access control
        $canView = false;

        if ($user->isSuperAdmin()) {
            $canView = true;
        } elseif ($user->isBranchAdmin()) {
            $canView = $user->branch_id === $mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canView = $user->id === $mc->leader_id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = $mc->members();

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->get('role'));
        }

        $members = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'mc' => [
                'id' => $mc->id,
                'name' => $mc->name,
                'leader' => $mc->leader
            ],
            'members' => $members->items(),
            'pagination' => [
                'current_page' => $members->currentPage(),
                'last_page' => $members->lastPage(),
                'per_page' => $members->perPage(),
                'total' => $members->total()
            ]
        ]);
    }

    /**
     * Add a member to MC
     */
    public function addMember(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $mc = MC::find($id);

        if (!$mc) {
            return response()->json(['error' => 'MC not found'], 404);
        }

        // Only super admins, branch admins, and MC leaders can add members
        $canAdd = false;

        if ($user->isSuperAdmin()) {
            $canAdd = true;
        } elseif ($user->isBranchAdmin()) {
            $canAdd = $user->branch_id === $mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canAdd = $user->id === $mc->leader_id;
        }

        if (!$canAdd) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $member = User::find($request->user_id);

        // Validate member belongs to same branch
        if ($member->branch_id !== $mc->branch_id) {
            return response()->json(['error' => 'Member must belong to the same branch as MC'], 422);
        }

        // Check if member is already in an MC
        if ($member->mc_id) {
            return response()->json(['error' => 'Member is already assigned to an MC'], 422);
        }

        $member->update(['mc_id' => $mc->id]);

        return response()->json([
            'message' => 'Member added to MC successfully',
            'member' => $member
        ]);
    }

    /**
     * Remove a member from MC
     */
    public function removeMember(string $mcId, string $userId): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $mc = MC::find($mcId);

        if (!$mc) {
            return response()->json(['error' => 'MC not found'], 404);
        }

        $member = User::find($userId);

        if (!$member) {
            return response()->json(['error' => 'Member not found'], 404);
        }

        // Only super admins, branch admins, and MC leaders can remove members
        $canRemove = false;

        if ($user->isSuperAdmin()) {
            $canRemove = true;
        } elseif ($user->isBranchAdmin()) {
            $canRemove = $user->branch_id === $mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canRemove = $user->id === $mc->leader_id;
        }

        if (!$canRemove) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Check if member is actually in this MC
        if ($member->mc_id !== $mc->id) {
            return response()->json(['error' => 'Member is not in this MC'], 422);
        }

        // Cannot remove the MC leader
        if ($member->id === $mc->leader_id) {
            return response()->json(['error' => 'Cannot remove MC leader. Change leader first.'], 422);
        }

        $member->update(['mc_id' => null]);

        return response()->json(['message' => 'Member removed from MC successfully']);
    }
}

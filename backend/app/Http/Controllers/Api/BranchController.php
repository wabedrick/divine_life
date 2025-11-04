<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use App\Models\User;
use App\Models\MC;
use App\Models\Report;
use App\Traits\WeekPeriodCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class BranchController extends Controller
{
    use WeekPeriodCalculator;

    public function __construct()
    {
        $this->middleware('auth:api', ['except' => ['publicIndex']]);
    }

    /**
     * Public endpoint to get branches for registration
     * No authentication required
     */
    public function publicIndex(): JsonResponse
    {
        $branches = Branch::where('is_active', true)
            ->select('id', 'name', 'location', 'description', 'address', 'phone_number', 'email', 'admin_id', 'is_active', 'created_at', 'updated_at')
            ->orderBy('name')
            ->get();

        return response()->json([
            'branches' => $branches,
            'total' => $branches->count()
        ]);
    }

    /**
     * Display a listing of branches with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = Branch::with(['admin', 'users', 'missionalCommunities']);

        // Role-based access control
        if ($user->isBranchAdmin()) {
            // Branch admins can only see their own branch
            $query->where('id', $user->branch_id);
        } elseif ($user->isMCLeader() || $user->isMember()) {
            // MC leaders and members can only see their branch
            $query->where('id', $user->branch_id);
        }

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('location', 'LIKE', "%{$search}%")
                    ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        if ($request->filled('admin_id')) {
            $query->where('admin_id', $request->get('admin_id'));
        }

        // Sort options
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $branches = $query->paginate($request->get('per_page', 15));

        // Add statistics for each branch
        foreach ($branches->items() as $branch) {
            $branch->statistics = [
                'total_users' => $branch->users()->count(),
                'total_mcs' => $branch->missionalCommunities()->count(),
                'active_mcs' => $branch->activeMCs()->count(),
                'pending_users' => $branch->users()->where('is_approved', false)->count(),
            ];
        }

        return response()->json([
            'branches' => $branches->items(),
            'pagination' => [
                'current_page' => $branches->currentPage(),
                'last_page' => $branches->lastPage(),
                'per_page' => $branches->perPage(),
                'total' => $branches->total()
            ]
        ]);
    }

    /**
     * Store a newly created branch
     */
    public function store(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only super admins can create branches
        if (!$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:branches',
            'description' => 'nullable|string|max:1000',
            'location' => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone_number' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:255',
            'admin_id' => 'required|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Validate that the admin has appropriate role
        $admin = User::find($data['admin_id']);
        if (!in_array($admin->role, ['branch_admin', 'super_admin'])) {
            return response()->json(['error' => 'User must have branch_admin role or higher'], 422);
        }

        // Check if admin is already assigned to another branch
        if ($admin->branch_id && $admin->role === 'branch_admin') {
            return response()->json(['error' => 'User is already assigned as admin to another branch'], 422);
        }

        $data['is_active'] = $data['is_active'] ?? true;

        $branch = Branch::create($data);

        // Update the admin's branch assignment
        $admin->update(['branch_id' => $branch->id]);

        $branch->load(['admin', 'users', 'missionalCommunities']);

        return response()->json([
            'message' => 'Branch created successfully',
            'branch' => $branch
        ], 201);
    }

    /**
     * Display the specified branch
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branch = Branch::with(['admin', 'users', 'missionalCommunities.leader'])->find($id);

        if (!$branch) {
            return response()->json(['error' => 'Branch not found'], 404);
        }

        // Role-based access control
        $canView = false;

        if ($user->isSuperAdmin()) {
            $canView = true;
        } else {
            // All other roles can only view their own branch
            $canView = $user->branch_id === $branch->id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Add detailed statistics
        $branch->statistics = [
            'total_users' => $branch->users()->count(),
            'users_by_role' => [
                'branch_admin' => $branch->users()->where('role', 'branch_admin')->count(),
                'mc_leader' => $branch->users()->where('role', 'mc_leader')->count(),
                'member' => $branch->users()->where('role', 'member')->count(),
            ],
            'total_mcs' => $branch->missionalCommunities()->count(),
            'active_mcs' => $branch->activeMCs()->count(),
            'pending_users' => $branch->users()->where('is_approved', false)->count(),
            'approved_users' => $branch->users()->where('is_approved', true)->count(),
        ];

        return response()->json(['branch' => $branch]);
    }

    /**
     * Update the specified branch
     */
    public function update(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branch = Branch::find($id);

        if (!$branch) {
            return response()->json(['error' => 'Branch not found'], 404);
        }

        // Role-based access control
        $canUpdate = false;

        if ($user->isSuperAdmin()) {
            $canUpdate = true;
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can update their own branch (limited fields)
            $canUpdate = $user->branch_id === $branch->id;
        }

        if (!$canUpdate) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $rules = [
            'name' => 'sometimes|string|max:255|unique:branches,name,' . $branch->id,
            'description' => 'nullable|string|max:1000',
            'location' => 'sometimes|string|max:255',
            'address' => 'nullable|string|max:500',
            'phone_number' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:255',
        ];

        // Admin-only fields
        if ($user->isSuperAdmin()) {
            $rules['admin_id'] = 'sometimes|exists:users,id';
            $rules['is_active'] = 'sometimes|boolean';
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Additional validations for admin-only updates
        if (isset($data['admin_id'])) {
            $newAdmin = User::find($data['admin_id']);

            if (!in_array($newAdmin->role, ['branch_admin', 'super_admin'])) {
                return response()->json(['error' => 'User must have branch_admin role or higher'], 422);
            }

            // Check if new admin is already assigned to another branch (unless they're super admin)
            if ($newAdmin->branch_id && $newAdmin->branch_id !== $branch->id && $newAdmin->role === 'branch_admin') {
                return response()->json(['error' => 'User is already assigned as admin to another branch'], 422);
            }
        }

        $oldAdminId = $branch->admin_id;
        $branch->update($data);

        // Update admin branch assignments if admin changed
        if (isset($data['admin_id']) && $data['admin_id'] !== $oldAdminId) {
            // Remove old admin's branch assignment (if they're only branch admin)
            if ($oldAdminId) {
                $oldAdmin = User::find($oldAdminId);
                if ($oldAdmin && $oldAdmin->role === 'branch_admin') {
                    $oldAdmin->update(['branch_id' => null]);
                }
            }
            // Assign new admin
            User::where('id', $data['admin_id'])->update(['branch_id' => $branch->id]);
        }

        $branch->load(['admin', 'users', 'missionalCommunities']);

        return response()->json([
            'message' => 'Branch updated successfully',
            'branch' => $branch
        ]);
    }

    /**
     * Remove the specified branch from storage
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branch = Branch::find($id);

        if (!$branch) {
            return response()->json(['error' => 'Branch not found'], 404);
        }

        // Only super admins can delete branches
        if (!$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Check if branch has users or MCs
        $userCount = $branch->users()->count();
        $mcCount = $branch->missionalCommunities()->count();

        if ($userCount > 0 || $mcCount > 0) {
            return response()->json([
                'error' => 'Cannot delete branch with existing users or MCs. Please reassign them first.',
                'users_count' => $userCount,
                'mcs_count' => $mcCount
            ], 422);
        }

        $branch->delete();

        return response()->json(['message' => 'Branch deleted successfully']);
    }

    /**
     * Get users of a specific branch
     */
    public function getUsers(string $id, Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branch = Branch::find($id);

        if (!$branch) {
            return response()->json(['error' => 'Branch not found'], 404);
        }

        // Role-based access control
        $canView = false;

        if ($user->isSuperAdmin()) {
            $canView = true;
        } elseif ($user->isBranchAdmin()) {
            $canView = $user->branch_id === $branch->id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = $branch->users()->with(['mc']);

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                    ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->get('role'));
        }

        if ($request->filled('is_approved')) {
            $query->where('is_approved', $request->boolean('is_approved'));
        }

        if ($request->filled('mc_id')) {
            $query->where('mc_id', $request->get('mc_id'));
        }

        $users = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'branch' => [
                'id' => $branch->id,
                'name' => $branch->name,
                'admin' => $branch->admin
            ],
            'users' => $users->items(),
            'pagination' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total()
            ]
        ]);
    }

    /**
     * Assign a user to branch
     */
    public function assignUser(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branch = Branch::find($id);

        if (!$branch) {
            return response()->json(['error' => 'Branch not found'], 404);
        }

        // Only super admins can assign users to branches
        if (!$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $targetUser = User::find($request->user_id);

        // Check if user is already in this branch
        if ($targetUser->branch_id === $branch->id) {
            return response()->json(['error' => 'User is already assigned to this branch'], 422);
        }

        // If user is currently an MC leader, remove them from their MC
        if ($targetUser->role === 'mc_leader' && $targetUser->mc_id) {
            $mc = MC::find($targetUser->mc_id);
            if ($mc && $mc->leader_id === $targetUser->id) {
                $mc->update(['leader_id' => null]);
            }
        }

        $targetUser->update([
            'branch_id' => $branch->id,
            'mc_id' => null // Remove MC assignment when changing branch
        ]);

        return response()->json([
            'message' => 'User assigned to branch successfully',
            'user' => $targetUser
        ]);
    }

    /**
     * Get branch statistics
     */
    public function getStatistics(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branch = Branch::find($id);

        if (!$branch) {
            return response()->json(['error' => 'Branch not found'], 404);
        }

        // Role-based access control
        $canView = false;

        if ($user->isSuperAdmin()) {
            $canView = true;
        } elseif ($user->isBranchAdmin()) {
            $canView = $user->branch_id === $branch->id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Get current week period information
        $weekInfo = $this->getDateRangeWeekInfo();

        // Get report statistics for current week
        $reportQuery = Report::whereHas('mc', function ($q) use ($branch) {
            $q->where('branch_id', $branch->id);
        })->where('week_ending', '>=', $weekInfo['start_date'])
            ->where('week_ending', '<=', $weekInfo['end_date']);

        $statistics = [
            'branch_info' => [
                'id' => $branch->id,
                'name' => $branch->name,
                'admin' => $branch->admin,
                'is_active' => $branch->is_active
            ],
            'users' => [
                'total' => $branch->users()->count(),
                'approved' => $branch->users()->where('is_approved', true)->count(),
                'pending' => $branch->users()->where('is_approved', false)->count(),
                'by_role' => [
                    'branch_admin' => $branch->users()->where('role', 'branch_admin')->count(),
                    'mc_leader' => $branch->users()->where('role', 'mc_leader')->count(),
                    'member' => $branch->users()->where('role', 'member')->count(),
                ],
            ],
            'missional_communities' => [
                'total' => $branch->missionalCommunities()->count(),
                'active' => $branch->activeMCs()->count(),
                'inactive' => $branch->missionalCommunities()->where('is_active', false)->count(),
            ],
            'reports' => [
                'current_week' => [
                    'total' => (clone $reportQuery)->count(),
                    'pending' => (clone $reportQuery)->where('status', 'pending')->count(),
                    'approved' => (clone $reportQuery)->where('status', 'approved')->count(),
                    'rejected' => (clone $reportQuery)->where('status', 'rejected')->count(),
                ],
                'totals_current_week' => [
                    'members_met' => (clone $reportQuery)->where('status', 'approved')->sum('members_met'),
                    'new_members' => (clone $reportQuery)->where('status', 'approved')->sum('new_members'),
                    'salvations' => (clone $reportQuery)->where('status', 'approved')->sum('salvations'),
                    'anagkazo' => (clone $reportQuery)->where('status', 'approved')->sum('anagkazo'),
                    'offerings' => (clone $reportQuery)->where('status', 'approved')->sum('offerings'),
                ],
            ],
            'period' => [
                'type' => $weekInfo['period_type'],
                'start_date' => $weekInfo['start_date'],
                'end_date' => $weekInfo['end_date'],
                'display_text' => $weekInfo['display_text'],
                'is_single_week' => $weekInfo['is_single_week'],
            ],
            'recent_activity' => [
                'recent_users' => $branch->users()->orderBy('created_at', 'desc')->limit(5)->get(['id', 'name', 'email', 'created_at']),
                'recent_mcs' => $branch->missionalCommunities()->with('leader')->orderBy('created_at', 'desc')->limit(5)->get(['id', 'name', 'leader_id', 'created_at']),
            ]
        ];

        return response()->json(['statistics' => $statistics]);
    }
}

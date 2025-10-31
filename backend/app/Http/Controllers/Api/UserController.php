<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Branch;
use App\Models\MC;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Get the authenticated user as User model
     */
    private function getAuthenticatedUser(): User
    {
        return Auth::user();
    }

    /**
     * Display a listing of users with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        /** @var \App\Models\User $user */
        $user = $this->getAuthenticatedUser();

        // Role-based access control
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json([
                'error' => [
                    'message' => 'Insufficient permissions to view users',
                    'code' => 'INSUFFICIENT_PERMISSIONS'
                ]
            ], 403);
        }

        $query = User::with(['branch', 'mc']);

        // Branch admins can only see users in their branch
        if ($user->isBranchAdmin()) {
            $query->where('branch_id', $user->branch_id);
        }

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%")
                  ->orWhere('phone_number', 'LIKE', "%{$search}%");
            });
        }

        if ($request->filled('role')) {
            $query->where('role', $request->get('role'));
        }

        if ($request->filled('is_approved')) {
            $query->where('is_approved', $request->boolean('is_approved'));
        }

        if ($request->filled('branch_id')) {
            $query->where('branch_id', $request->get('branch_id'));
        }

        if ($request->filled('mc_id')) {
            $query->where('mc_id', $request->get('mc_id'));
        }

        // Sort options
        $sortBy = $request->get('sort_by', 'created_at');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $users = $query->paginate($request->get('per_page', 15));

        return response()->json([
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
     * Store a newly created user (Admin only)
     */
    public function store(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser();

        // Only super admins and branch admins can create users
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'phone_number' => 'nullable|string|max:20',
            'birth_date' => 'nullable|date',
            'gender' => 'nullable|in:male,female',
            'role' => 'required|in:super_admin,branch_admin,mc_leader,member',
            'branch_id' => 'nullable|exists:branches,id',
            'mc_id' => 'nullable|exists:m_c_s,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Role-based restrictions
        if ($user->isBranchAdmin()) {
            // Branch admins can't create super admins or other branch admins
            if (in_array($data['role'], ['super_admin', 'branch_admin'])) {
                return response()->json(['error' => 'Cannot create users with that role'], 403);
            }
            // Must be in the same branch
            $data['branch_id'] = $user->branch_id;
        }

        // Validate branch and MC relationship
        if ($data['mc_id'] && $data['branch_id']) {
            $mc = MC::find($data['mc_id']);
            if ($mc->branch_id !== (int)$data['branch_id']) {
                return response()->json(['error' => 'MC does not belong to the specified branch'], 422);
            }
        }

        $data['password'] = Hash::make($data['password']);
        $data['is_approved'] = true; // Admin-created users are pre-approved

        $newUser = User::create($data);
        $newUser->load(['branch', 'mc']);

        return response()->json([
            'message' => 'User created successfully',
            'user' => $newUser
        ], 201);
    }

    /**
     * Display the specified user
     */
    public function show(string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $targetUser = User::with(['branch', 'mc', 'weeklyReports'])->find($id);

        if (!$targetUser) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Role-based access control
        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            // Regular users can only view their own profile
            if ($user->id !== $targetUser->id) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can only view users in their branch
            if ($user->branch_id !== $targetUser->branch_id) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
        }

        return response()->json(['user' => $targetUser]);
    }

    /**
     * Update the specified user
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $targetUser = User::find($id);

        if (!$targetUser) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Role-based access control
        $canUpdate = false;

        if ($user->isSuperAdmin()) {
            $canUpdate = true;
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can update users in their branch (except other admins)
            if ($user->branch_id === $targetUser->branch_id &&
                !in_array($targetUser->role, ['super_admin', 'branch_admin'])) {
                $canUpdate = true;
            }
        } elseif ($user->id === $targetUser->id) {
            // Users can update their own profile (limited fields)
            $canUpdate = true;
        }

        if (!$canUpdate) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $rules = [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|max:255|unique:users,email,' . $id,
            'phone_number' => 'nullable|string|max:20',
            'birth_date' => 'nullable|date',
            'gender' => 'nullable|in:male,female',
        ];

        // Admin-only fields
        if ($user->isSuperAdmin() || ($user->isBranchAdmin() && $user->id !== $targetUser->id)) {
            $rules['role'] = 'sometimes|in:super_admin,branch_admin,mc_leader,member';
            $rules['branch_id'] = 'nullable|exists:branches,id';
            $rules['mc_id'] = 'nullable|exists:m_c_s,id';
            $rules['is_approved'] = 'sometimes|boolean';
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Role-based restrictions for updates
        if ($user->isBranchAdmin() && isset($data['role'])) {
            if (in_array($data['role'], ['super_admin', 'branch_admin'])) {
                return response()->json(['error' => 'Cannot assign that role'], 403);
            }
        }

        // Validate branch and MC relationship
        if (isset($data['mc_id']) && isset($data['branch_id'])) {
            $mc = MC::find($data['mc_id']);
            if ($mc && $mc->branch_id !== (int)$data['branch_id']) {
                return response()->json(['error' => 'MC does not belong to the specified branch'], 422);
            }
        }

        $targetUser->update($data);
        $targetUser->load(['branch', 'mc']);

        return response()->json([
            'message' => 'User updated successfully',
            'user' => $targetUser
        ]);
    }

    /**
     * Remove the specified user from storage
     */
    public function destroy(string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $targetUser = User::find($id);

        if (!$targetUser) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Role-based access control
        $canDelete = false;

        if ($user->isSuperAdmin()) {
            $canDelete = true;
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can delete users in their branch (except other admins)
            if ($user->branch_id === $targetUser->branch_id &&
                !in_array($targetUser->role, ['super_admin', 'branch_admin'])) {
                $canDelete = true;
            }
        }

        if (!$canDelete) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Prevent deletion of the last super admin
        if ($targetUser->role === 'super_admin') {
            $superAdminCount = User::where('role', 'super_admin')->count();
            if ($superAdminCount <= 1) {
                return response()->json(['error' => 'Cannot delete the last super admin'], 422);
            }
        }

        $targetUser->delete();

        return response()->json(['message' => 'User deleted successfully']);
    }

    /**
     * Approve or reject pending users
     */
    public function updateApprovalStatus(Request $request, string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();

        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $targetUser = User::find($id);

        if (!$targetUser) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Branch admins can only approve users in their branch
        if ($user->isBranchAdmin() && $user->branch_id !== $targetUser->branch_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'is_approved' => 'required|boolean',
            'rejection_reason' => 'required_if:is_approved,false|nullable|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $updateData = ['is_approved' => $request->boolean('is_approved')];

        if (!$request->boolean('is_approved') && $request->filled('rejection_reason')) {
            $updateData['rejection_reason'] = $request->rejection_reason;
        } else {
            $updateData['rejection_reason'] = null;
            $updateData['approved_at'] = now();
            $updateData['approved_by'] = Auth::user()->id;
        }

        $targetUser->update($updateData);

        return response()->json([
            'message' => 'User approval status updated successfully',
            'user' => $targetUser
        ]);
    }

    /**
     * Change user password
     */
    public function changePassword(Request $request, string $id): JsonResponse
    {
        $user = $this->getAuthenticatedUser();
        $targetUser = User::find($id);

        if (!$targetUser) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Role-based access control
        $canChangePassword = false;

        if ($user->isSuperAdmin()) {
            $canChangePassword = true;
        } elseif ($user->isBranchAdmin()) {
            // Branch admins can change passwords for users in their branch (except other admins)
            if ($user->branch_id === $targetUser->branch_id &&
                !in_array($targetUser->role, ['super_admin', 'branch_admin'])) {
                $canChangePassword = true;
            }
        } elseif ($user->id === $targetUser->id) {
            // Users can change their own password
            $canChangePassword = true;
        }

        if (!$canChangePassword) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $rules = [
            'new_password' => 'required|string|min:6|confirmed',
        ];

        // Users changing their own password must provide current password
        if ($user->id === $targetUser->id) {
            $rules['current_password'] = 'required|string';
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Verify current password if user is changing their own
        if ($user->id === $targetUser->id) {
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json(['error' => 'Current password is incorrect'], 422);
            }
        }

        $targetUser->update([
            'password' => Hash::make($request->new_password)
        ]);

        return response()->json(['message' => 'Password changed successfully']);
    }

    /**
     * Get pending users for approval
     */
    public function pending(Request $request): JsonResponse
    {
        $user = $this->getAuthenticatedUser();

        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = User::with(['branch', 'mc'])
            ->where('is_approved', false);

        // Branch admins can only see pending users in their branch
        if ($user->isBranchAdmin()) {
            $query->where('branch_id', $user->branch_id);
        }

        $pendingUsers = $query->orderBy('created_at', 'desc')
            ->paginate($request->get('per_page', 15));

        return response()->json([
            'pending_users' => $pendingUsers->items(),
            'pagination' => [
                'current_page' => $pendingUsers->currentPage(),
                'last_page' => $pendingUsers->lastPage(),
                'per_page' => $pendingUsers->perPage(),
                'total' => $pendingUsers->total()
            ]
        ]);
    }

    /**
     * Get user statistics
     */
    public function statistics(): JsonResponse
    {
        $user = $this->getAuthenticatedUser();

        if (!$user->isSuperAdmin() && !$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = User::query();

        // Branch admins can only see statistics for their branch
        if ($user->isBranchAdmin()) {
            $query->where('branch_id', $user->branch_id);
        }

        $baseQuery = clone $query;

        $statistics = [
            'total_users' => $baseQuery->count(),
            'approved_users' => (clone $baseQuery)->where('is_approved', true)->count(),
            'pending_users' => (clone $baseQuery)->where('is_approved', false)->count(),
            'users_by_role' => $baseQuery->select('role', DB::raw('count(*) as count'))
                ->groupBy('role')
                ->pluck('count', 'role'),
            'recent_registrations' => (clone $baseQuery)->where('created_at', '>=', now()->subDays(30))->count()
        ];

        return response()->json(['statistics' => $statistics]);
    }

    /**
     * Get member dashboard data (for regular users)
     */
    public function memberDashboard(): JsonResponse
    {
        $user = $this->getAuthenticatedUser();

        // Any authenticated user can access their own dashboard
        $statistics = [
            'my_branch' => $user->branch ? [
                'id' => $user->branch->id,
                'name' => $user->branch->name,
                'location' => $user->branch->location,
            ] : null,
            'my_mc' => $user->mc ? [
                'id' => $user->mc->id,
                'name' => $user->mc->name,
                'location' => $user->mc->location,
            ] : null,
            'profile_completion' => $this->calculateProfileCompletion($user),
            'recent_activities' => 'Coming soon', // Placeholder for future features
        ];

        return response()->json(['dashboard' => $statistics]);
    }

    /**
     * Calculate profile completion percentage
     */
    private function calculateProfileCompletion(User $user): int
    {
        $fields = [
            'name', 'email', 'phone_number', 'birth_date',
            'gender', 'branch_id'
        ];

        $completed = 0;
        foreach ($fields as $field) {
            if (!empty($user->$field)) {
                $completed++;
            }
        }

        return round(($completed / count($fields)) * 100);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api', ['except' => ['login', 'register']]);
    }

    /**
     * User login
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => [
                    'message' => 'Validation failed',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        $credentials = $request->only('email', 'password');

        if (!$token = Auth::guard('api')->attempt($credentials)) {
            return response()->json([
                'error' => [
                    'message' => 'Invalid credentials',
                    'code' => 'INVALID_CREDENTIALS'
                ]
            ], 401);
        }

        $user = Auth::guard('api')->user();

        if (!$user->is_approved) {
            Auth::guard('api')->logout();
            return response()->json([
                'error' => [
                    'message' => 'Account not approved. Please contact your administrator.',
                    'code' => 'ACCOUNT_NOT_APPROVED'
                ]
            ], 403);
        }

        return response()->json([
            'access_token' => $token,
            'token_type' => 'bearer',
            'expires_in' => JWTAuth::factory()->getTTL() * 60,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'branch_id' => $user->branch_id,
                'mc_id' => $user->mc_id,
                'phone_number' => $user->phone_number,
            ]
        ]);
    }

    /**
     * User registration
     */
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'phone_number' => 'required|string|max:20',
            'birth_date' => 'required|date',
            'gender' => 'required|in:male,female',
            'branch_id' => 'required|exists:branches,id',
            'mc_id' => 'nullable|exists:missional_communities,id',
            'role' => 'in:mc_leader,member'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => [
                    'message' => 'Validation failed',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone_number' => $request->phone_number,
            'birth_date' => $request->birth_date,
            'gender' => $request->gender,
            'branch_id' => $request->branch_id,
            'mc_id' => $request->mc_id,
            'role' => $request->role ?? 'member',
            'is_approved' => false, // Requires admin approval
        ]);

        return response()->json([
            'message' => 'Registration successful. Your account is pending approval.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ]
        ], 201);
    }

    /**
     * Refresh JWT token
     */
    public function refresh(): JsonResponse
    {
        try {
            $token = JWTAuth::refresh();
            return response()->json([
                'access_token' => $token,
                'token_type' => 'bearer',
                'expires_in' => JWTAuth::factory()->getTTL() * 60
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => [
                    'message' => 'Token refresh failed',
                    'code' => 'TOKEN_REFRESH_FAILED'
                ]
            ], 401);
        }
    }

    /**
     * User logout
     */
    public function logout(): JsonResponse
    {
        Auth::guard('api')->logout();
        return response()->json(['message' => 'Successfully logged out']);
    }

    /**
     * Get authenticated user profile
     */
    public function profile(): JsonResponse
    {
        $user = Auth::guard('api')->user();
        // Load relationships
        if ($user) {
            $user = User::with(['branch', 'mc'])->find($user->id);
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->phone_number,
                'birth_date' => $user->birth_date,
                'gender' => $user->gender,
                'role' => $user->role,
                'is_approved' => $user->is_approved,
                'branch' => $user->branch,
                'mc' => $user->mc,
                'created_at' => $user->created_at,
            ]
        ]);
    }
}

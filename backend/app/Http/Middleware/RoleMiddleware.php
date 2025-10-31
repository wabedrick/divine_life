<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  string  $role
     */
    public function handle(Request $request, Closure $next, string $role): Response
    {
        if (!Auth::check()) {
            return response()->json([
                'error' => [
                    'message' => 'Unauthenticated',
                    'code' => 'UNAUTHENTICATED'
                ]
            ], 401);
        }

        $user = Auth::user();

        // Check if user has the required role or higher
        if (!$this->hasPermission($user->role, $role)) {
            return response()->json([
                'error' => [
                    'message' => 'Insufficient permissions',
                    'code' => 'INSUFFICIENT_PERMISSIONS'
                ]
            ], 403);
        }

        return $next($request);
    }

    /**
     * Check if user role has permission for required role
     */
    private function hasPermission(string $userRole, string $requiredRole): bool
    {
        $hierarchy = [
            'super_admin' => 4,
            'branch_admin' => 3,
            'mc_leader' => 2,
            'member' => 1,
        ];

        return ($hierarchy[$userRole] ?? 0) >= ($hierarchy[$requiredRole] ?? 0);
    }
}

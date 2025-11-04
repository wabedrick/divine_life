<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;

class BirthdayController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Get birthday notifications for the authenticated user
     */
    public function getBirthdayNotifications(): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();
        $birthdays = collect();

        try {
            if ($user->isMCLeader() && $user->mc_id) {
                // Get birthdays for MC members
                $mcBirthdays = User::getBirthdaysForMCLeader($user->mc_id);
                $birthdays = $birthdays->merge($mcBirthdays->map(function ($birthdayUser) {
                    return [
                        'id' => $birthdayUser->id,
                        'name' => $birthdayUser->name,
                        'email' => $birthdayUser->email,
                        'birth_date' => $birthdayUser->birth_date,
                        'context' => 'mc_member',
                        'context_name' => 'MC Member'
                    ];
                }));
            }

            if ($user->isBranchAdmin() && $user->branch_id) {
                // Get birthdays for branch members (including MC members)
                $branchBirthdays = User::getBirthdaysForBranchAdmin($user->branch_id);
                $birthdays = $birthdays->merge($branchBirthdays->map(function ($birthdayUser) {
                    $contextName = 'Branch Member';
                    if ($birthdayUser->isMCLeader()) {
                        $contextName = 'MC Leader';
                    } elseif ($birthdayUser->mc_id) {
                        $contextName = 'MC Member';
                    }

                    return [
                        'id' => $birthdayUser->id,
                        'name' => $birthdayUser->name,
                        'email' => $birthdayUser->email,
                        'birth_date' => $birthdayUser->birth_date,
                        'context' => 'branch_member',
                        'context_name' => $contextName,
                        'mc_id' => $birthdayUser->mc_id
                    ];
                }));
            }

            if ($user->isSuperAdmin()) {
                // Super admins can see all birthdays
                $allBirthdays = User::whereNotNull('birth_date')
                    ->get()
                    ->filter(function ($birthdayUser) {
                        return $birthdayUser->isBirthdayToday();
                    });

                $birthdays = $birthdays->merge($allBirthdays->map(function ($birthdayUser) {
                    $contextName = 'User';
                    if ($birthdayUser->isSuperAdmin()) {
                        $contextName = 'Super Admin';
                    } elseif ($birthdayUser->isBranchAdmin()) {
                        $contextName = 'Branch Admin';
                    } elseif ($birthdayUser->isMCLeader()) {
                        $contextName = 'MC Leader';
                    } elseif ($birthdayUser->mc_id) {
                        $contextName = 'MC Member';
                    } else {
                        $contextName = 'Branch Member';
                    }

                    return [
                        'id' => $birthdayUser->id,
                        'name' => $birthdayUser->name,
                        'email' => $birthdayUser->email,
                        'birth_date' => $birthdayUser->birth_date,
                        'context' => 'system_wide',
                        'context_name' => $contextName,
                        'branch_id' => $birthdayUser->branch_id,
                        'mc_id' => $birthdayUser->mc_id
                    ];
                }));
            }

            // Remove duplicates based on user ID
            $birthdays = $birthdays->unique('id')->values();

            return response()->json([
                'success' => true,
                'birthdays' => $birthdays,
                'count' => $birthdays->count(),
                'date' => now()->format('Y-m-d')
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch birthday notifications',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mark birthday notification as acknowledged
     */
    public function acknowledgeBirthday(Request $request): JsonResponse
    {
        // This could be extended to track which birthdays have been acknowledged
        // For now, just return success
        return response()->json([
            'success' => true,
            'message' => 'Birthday notification acknowledged'
        ]);
    }

    /**
     * Get upcoming birthdays (next 7 days) for planning
     */
    public function getUpcomingBirthdays(): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();
        $upcomingBirthdays = collect();

        try {
            $query = User::whereNotNull('birth_date');

            // Apply role-based filtering
            if ($user->isMCLeader() && $user->mc_id) {
                $query->where('mc_id', $user->mc_id);
            } elseif ($user->isBranchAdmin() && $user->branch_id) {
                $query->where('branch_id', $user->branch_id);
            } elseif (!$user->isSuperAdmin()) {
                // Regular members can't access this endpoint
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized access'
                ], 403);
            }

            $users = $query->get();

            // Filter for upcoming birthdays (next 7 days)
            $upcomingBirthdays = $users->filter(function ($birthdayUser) {
                if (!$birthdayUser->birth_date) {
                    return false;
                }

                $today = now();
                $birthDate = \Carbon\Carbon::parse($birthdayUser->birth_date);

                // Get this year's birthday
                $thisYearBirthday = $birthDate->copy()->year($today->year);

                // If birthday has passed this year, check next year
                if ($thisYearBirthday->lt($today)) {
                    $thisYearBirthday = $thisYearBirthday->addYear();
                }

                // Check if birthday is in the next 7 days
                return $thisYearBirthday->between($today, $today->copy()->addDays(7));
            })->map(function ($birthdayUser) {
                $today = now();
                $birthDate = \Carbon\Carbon::parse($birthdayUser->birth_date);
                $thisYearBirthday = $birthDate->copy()->year($today->year);

                if ($thisYearBirthday->lt($today)) {
                    $thisYearBirthday = $thisYearBirthday->addYear();
                }

                $daysUntil = $today->diffInDays($thisYearBirthday, false);

                return [
                    'id' => $birthdayUser->id,
                    'name' => $birthdayUser->name,
                    'email' => $birthdayUser->email,
                    'birth_date' => $birthdayUser->birth_date,
                    'birthday_this_year' => $thisYearBirthday->format('Y-m-d'),
                    'days_until_birthday' => $daysUntil,
                    'is_today' => $daysUntil === 0,
                    'age_turning' => $thisYearBirthday->year - $birthDate->year
                ];
            })->sortBy('days_until_birthday')->values();

            return response()->json([
                'success' => true,
                'upcoming_birthdays' => $upcomingBirthdays,
                'count' => $upcomingBirthdays->count(),
                'date_range' => [
                    'from' => now()->format('Y-m-d'),
                    'to' => now()->addDays(7)->format('Y-m-d')
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch upcoming birthdays',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

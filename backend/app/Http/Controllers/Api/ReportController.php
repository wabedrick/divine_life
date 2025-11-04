<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\User;
use App\Models\MC;
use App\Traits\WeekPeriodCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ReportController extends Controller
{
    use WeekPeriodCalculator;

    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of reports with filters and pagination
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = Report::with(['mc', 'submittedBy', 'reviewedBy']);

        // Role-based access control
        if ($user->isBranchAdmin()) {
            // Branch admins can see reports from MCs in their branch
            $query->whereHas('mc', function ($q) use ($user) {
                $q->where('branch_id', $user->branch_id);
            });
        } elseif ($user->isMCLeader()) {
            // MC leaders can only see their own MC reports
            $query->whereHas('mc', function ($q) use ($user) {
                $q->where('leader_id', $user->id);
            });
        } elseif ($user->isMember()) {
            // Members can only see reports from their MC
            if ($user->mc_id) {
                $query->where('mc_id', $user->mc_id);
            } else {
                // Members without MC can't see any reports
                $query->whereRaw('1 = 0');
            }
        }

        // Apply filters
        if ($request->filled('search')) {
            $search = $request->get('search');
            $query->where(function ($q) use ($search) {
                $q->where('comments', 'LIKE', "%{$search}%")
                    ->orWhere('evangelism_activities', 'LIKE', "%{$search}%")
                    ->orWhereHas('mc', function ($mcQuery) use ($search) {
                        $mcQuery->where('name', 'LIKE', "%{$search}%");
                    });
            });
        }

        if ($request->filled('mc_id')) {
            $query->where('mc_id', $request->get('mc_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->get('status'));
        }

        if ($request->filled('week_ending')) {
            $query->where('week_ending', $request->get('week_ending'));
        }

        if ($request->filled('date_from')) {
            $query->where('week_ending', '>=', $request->get('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->where('week_ending', '<=', $request->get('date_to'));
        }

        if ($request->filled('submitted_by')) {
            $query->where('submitted_by', $request->get('submitted_by'));
        }

        // Sort options
        $sortBy = $request->get('sort_by', 'week_ending');
        $sortOrder = $request->get('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $reports = $query->paginate($request->get('per_page', 15));

        return response()->json([
            'reports' => $reports->items(),
            'pagination' => [
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
                'per_page' => $reports->perPage(),
                'total' => $reports->total()
            ]
        ]);
    }

    /**
     * Store a newly created report
     */
    public function store(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only MC leaders and higher can create MC reports
        // Note: Branch Admins should use /branch-reports endpoint instead
        if (!$user->isMCLeader() && !$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized to create MC reports'], 403);
        }

        $validator = Validator::make($request->all(), [
            'mc_id' => 'required|exists:missional_communities,id',
            'week_ending' => 'required|date',
            'members_met' => 'required|integer|min:0',
            'new_members' => 'required|integer|min:0',
            'salvations' => 'required|integer|min:0',
            'anagkazo' => 'nullable|integer|min:0',
            'offerings' => 'required|numeric|min:0',
            'evangelism_activities' => 'nullable|string|max:1000',
            'comments' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Validate MC access
        $mc = MC::find($data['mc_id']);

        $canCreateForMC = false;
        if ($user->isSuperAdmin()) {
            $canCreateForMC = true;
        } elseif ($user->isBranchAdmin()) {
            $canCreateForMC = $user->branch_id === $mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canCreateForMC = $user->id === $mc->leader_id;
        }

        if (!$canCreateForMC) {
            return response()->json(['error' => 'Cannot create report for this MC'], 403);
        }

        // Check for duplicate report for the same week
        $existingReport = Report::where('mc_id', $data['mc_id'])
            ->where('week_ending', $data['week_ending'])
            ->first();

        if ($existingReport) {
            return response()->json(['error' => 'Report already exists for this MC and week'], 422);
        }

        $data['submitted_by'] = $user->id;
        $data['status'] = 'pending';

        $report = Report::create($data);
        $report->load(['mc', 'submittedBy', 'reviewedBy']);

        return response()->json([
            'message' => 'Report created successfully',
            'report' => $report
        ], 201);
    }

    /**
     * Display the specified report
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $report = Report::with(['mc', 'submittedBy', 'reviewedBy'])->find($id);

        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        // Role-based access control
        $canView = false;

        if ($user->isSuperAdmin()) {
            $canView = true;
        } elseif ($user->isBranchAdmin()) {
            $canView = $user->branch_id === $report->mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canView = $user->id === $report->mc->leader_id;
        } elseif ($user->isMember()) {
            $canView = $user->mc_id === $report->mc_id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json(['report' => $report]);
    }

    /**
     * Update the specified report
     */
    public function update(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $report = Report::find($id);

        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        // Check if report can be edited
        if (!$report->canBeEdited()) {
            return response()->json(['error' => 'Cannot edit report that has been reviewed'], 422);
        }

        // Role-based access control
        $canUpdate = false;

        if ($user->isSuperAdmin()) {
            $canUpdate = true;
        } elseif ($user->isBranchAdmin()) {
            $canUpdate = $user->branch_id === $report->mc->branch_id;
        } elseif ($user->isMCLeader()) {
            $canUpdate = $user->id === $report->mc->leader_id;
        }

        if (!$canUpdate) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'week_ending' => 'sometimes|date|date_format:Y-m-d',
            'members_met' => 'sometimes|integer|min:0',
            'new_members' => 'sometimes|integer|min:0',
            'salvations' => 'sometimes|integer|min:0',
            'anagkazo' => 'sometimes|integer|min:0',
            'offerings' => 'sometimes|numeric|min:0',
            'evangelism_activities' => 'nullable|string|max:1000',
            'comments' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $report->update($request->all());
        $report->load(['mc', 'submittedBy', 'reviewedBy']);

        return response()->json([
            'message' => 'Report updated successfully',
            'report' => $report
        ]);
    }

    /**
     * Remove the specified report from storage
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $report = Report::find($id);

        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        // Check if report can be deleted (only pending reports)
        if (!$report->canBeEdited()) {
            return response()->json(['error' => 'Cannot delete report that has been reviewed'], 422);
        }

        // Role-based access control
        $canDelete = false;

        if ($user->isSuperAdmin()) {
            $canDelete = true;
        } elseif ($user->isBranchAdmin()) {
            $canDelete = $user->branch_id === $report->mc->branch_id;
        } elseif ($user->isMCLeader()) {
            // MC leaders can delete their own reports
            $canDelete = $user->id === $report->mc->leader_id;
        }

        if (!$canDelete) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $report->delete();

        return response()->json(['message' => 'Report deleted successfully']);
    }

    /**
     * Approve a report
     */
    public function approve(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $report = Report::find($id);

        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        // Only branch admins and super admins can approve reports
        if (!$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        if ($user->isBranchAdmin() && $user->branch_id !== $report->mc->branch_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        if ($report->status !== 'pending') {
            return response()->json(['error' => 'Only pending reports can be approved'], 422);
        }

        $validator = Validator::make($request->all(), [
            'review_comments' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $report->approve($user, $request->get('review_comments'));
        $report->load(['mc', 'submittedBy', 'reviewedBy']);

        return response()->json([
            'message' => 'Report approved successfully',
            'report' => $report
        ]);
    }

    /**
     * Reject a report
     */
    public function reject(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $report = Report::find($id);

        if (!$report) {
            return response()->json(['error' => 'Report not found'], 404);
        }

        // Only branch admins and super admins can reject reports
        if (!$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        if ($user->isBranchAdmin() && $user->branch_id !== $report->mc->branch_id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        if ($report->status !== 'pending') {
            return response()->json(['error' => 'Only pending reports can be rejected'], 422);
        }

        $validator = Validator::make($request->all(), [
            'review_comments' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $report->reject($user, $request->get('review_comments'));
        $report->load(['mc', 'submittedBy', 'reviewedBy']);

        return response()->json([
            'message' => 'Report rejected successfully',
            'report' => $report
        ]);
    }

    /**
     * Get statistics for reports
     */
    public function statistics(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = Report::query();

        // Role-based filtering
        if ($user->isBranchAdmin()) {
            $query->whereHas('mc', function ($q) use ($user) {
                $q->where('branch_id', $user->branch_id);
            });
        } elseif ($user->isMCLeader()) {
            $query->whereHas('mc', function ($q) use ($user) {
                $q->where('leader_id', $user->id);
            });
        } elseif ($user->isMember()) {
            if ($user->mc_id) {
                $query->where('mc_id', $user->mc_id);
            } else {
                $query->whereRaw('1 = 0');
            }
        }

        // Apply date filters if provided
        if ($request->filled('date_from')) {
            $query->where('week_ending', '>=', $request->get('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->where('week_ending', '<=', $request->get('date_to'));
        }

        // Get week period information
        $weekInfo = $this->getDateRangeWeekInfo(
            $request->get('date_from'),
            $request->get('date_to')
        );

        $statistics = [
            'total_reports' => $query->count(),
            'by_status' => [
                'pending' => (clone $query)->where('status', 'pending')->count(),
                'approved' => (clone $query)->where('status', 'approved')->count(),
                'rejected' => (clone $query)->where('status', 'rejected')->count(),
            ],
            'totals' => [
                'total_members_met' => (clone $query)->where('status', 'approved')->sum('members_met'),
                'total_new_members' => (clone $query)->where('status', 'approved')->sum('new_members'),
                'total_salvations' => (clone $query)->where('status', 'approved')->sum('salvations'),
                'total_anagkazo' => (clone $query)->where('status', 'approved')->sum('anagkazo'),
                'total_testimonies' => (clone $query)->where('status', 'approved')->sum('testimonies'),
                'total_offerings' => (clone $query)->where('status', 'approved')->sum('offerings'),
            ],
            'period' => [
                'type' => $weekInfo['period_type'],
                'start_date' => $weekInfo['start_date'],
                'end_date' => $weekInfo['end_date'],
                'display_text' => $weekInfo['display_text'],
                'is_single_week' => $weekInfo['is_single_week'],
            ],
        ];

        // Add averages
        $approvedCount = $statistics['by_status']['approved'];
        if ($approvedCount > 0) {
            $statistics['averages'] = [
                'avg_members_met' => round($statistics['totals']['total_members_met'] / $approvedCount, 2),
                'avg_new_members' => round($statistics['totals']['total_new_members'] / $approvedCount, 2),
                'avg_salvations' => round($statistics['totals']['total_salvations'] / $approvedCount, 2),
                'avg_anagkazo' => round($statistics['totals']['total_anagkazo'] / $approvedCount, 2),
                'avg_testimonies' => round($statistics['totals']['total_testimonies'] / $approvedCount, 2),
                'avg_offerings' => round($statistics['totals']['total_offerings'] / $approvedCount, 2),
            ];
        } else {
            $statistics['averages'] = [
                'avg_members_met' => 0,
                'avg_new_members' => 0,
                'avg_salvations' => 0,
                'avg_anagkazo' => 0,
                'avg_testimonies' => 0,
                'avg_offerings' => 0,
            ];
        }

        return response()->json(['statistics' => $statistics]);
    }

    /**
     * Get pending reports that need review
     */
    public function pending(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only branch admins and super admins can view pending reports for review
        if (!$user->isBranchAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = Report::with(['mc', 'submittedBy'])->pending();

        // Role-based filtering
        if ($user->isBranchAdmin()) {
            $query->whereHas('mc', function ($q) use ($user) {
                $q->where('branch_id', $user->branch_id);
            });
        }

        $reports = $query->orderBy('created_at', 'asc')->paginate($request->get('per_page', 15));

        return response()->json([
            'pending_reports' => $reports->items(),
            'pagination' => [
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
                'per_page' => $reports->perPage(),
                'total' => $reports->total()
            ]
        ]);
    }
}

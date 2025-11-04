<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BranchReport;
use App\Models\Report;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class BranchReportController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth:api');
    }

    /**
     * Display a listing of branch reports
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $query = BranchReport::with(['branch', 'submittedBy', 'reviewedBy']);

        // Role-based access control
        if ($user->isBranchAdmin()) {
            // Branch admins can only see their own branch reports
            $query->where('branch_id', $user->branch_id);
        } elseif (!$user->isSuperAdmin()) {
            // Only Super Admin and Branch Admin can view branch reports
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Apply filters
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('week_ending')) {
            $query->where('week_ending', $request->week_ending);
        }

        if ($request->has('branch_id') && $user->isSuperAdmin()) {
            $query->where('branch_id', $request->branch_id);
        }

        $perPage = min($request->get('per_page', 10), 100);
        $reports = $query->orderBy('week_ending', 'desc')
            ->paginate($perPage);

        return response()->json($reports);
    }

    /**
     * Store a newly created branch report
     * Only Branch Admins can create branch reports
     */
    public function store(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only Branch Admins can create branch reports
        if (!$user->isBranchAdmin()) {
            return response()->json(['error' => 'Only Branch Admins can submit branch reports'], 403);
        }

        $validator = Validator::make($request->all(), [
            'week_ending' => 'required|date',
            'total_mcs_reporting' => 'required|integer|min:0',
            'total_members_met' => 'required|integer|min:0',
            'total_new_members' => 'required|integer|min:0',
            'total_salvations' => 'required|integer|min:0',
            'total_anagkazo' => 'nullable|integer|min:0',
            'total_offerings' => 'required|numeric|min:0',
            'branch_activities' => 'nullable|string|max:1000',
            'training_conducted' => 'nullable|string|max:1000',
            'challenges' => 'nullable|string|max:1000',
            'prayer_requests' => 'nullable|string|max:1000',
            'goals_next_week' => 'nullable|string|max:1000',
            'comments' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Check for duplicate report for the same week
        $existingReport = BranchReport::where('branch_id', $user->branch_id)
            ->where('week_ending', $request->week_ending)
            ->first();

        if ($existingReport) {
            return response()->json(['error' => 'Branch report already exists for this week'], 422);
        }

        $data = $request->all();
        $data['branch_id'] = $user->branch_id;
        $data['submitted_by'] = $user->id;

        $branchReport = BranchReport::create($data);

        return response()->json([
            'message' => 'Branch report submitted successfully',
            'report' => $branchReport->load(['branch', 'submittedBy'])
        ], 201);
    }

    /**
     * Display the specified branch report
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branchReport = BranchReport::with(['branch', 'submittedBy', 'reviewedBy'])
            ->findOrFail($id);

        // Check access permissions
        $canView = false;
        if ($user->isSuperAdmin()) {
            $canView = true;
        } elseif ($user->isBranchAdmin()) {
            $canView = $user->branch_id === $branchReport->branch_id;
        }

        if (!$canView) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json($branchReport);
    }

    /**
     * Update the specified branch report
     */
    public function update(Request $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branchReport = BranchReport::findOrFail($id);

        // Only the submitter or super admin can update
        if ($branchReport->submitted_by !== $user->id && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Cannot update approved/rejected reports
        if ($branchReport->status !== 'pending') {
            return response()->json(['error' => 'Cannot update non-pending reports'], 422);
        }

        $validator = Validator::make($request->all(), [
            'week_ending' => 'sometimes|date',
            'total_mcs_reporting' => 'sometimes|integer|min:0',
            'total_members_met' => 'sometimes|integer|min:0',
            'total_new_members' => 'sometimes|integer|min:0',
            'total_salvations' => 'sometimes|integer|min:0',
            'total_anagkazo' => 'nullable|integer|min:0',
            'total_offerings' => 'sometimes|numeric|min:0',
            'branch_activities' => 'nullable|string|max:1000',
            'training_conducted' => 'nullable|string|max:1000',
            'challenges' => 'nullable|string|max:1000',
            'prayer_requests' => 'nullable|string|max:1000',
            'goals_next_week' => 'nullable|string|max:1000',
            'comments' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $branchReport->update($request->all());

        return response()->json([
            'message' => 'Branch report updated successfully',
            'report' => $branchReport->load(['branch', 'submittedBy'])
        ]);
    }

    /**
     * Remove the specified branch report
     */
    public function destroy(string $id): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        $branchReport = BranchReport::findOrFail($id);

        // Only super admin or the submitter can delete (and only if pending)
        if (
            !$user->isSuperAdmin() &&
            ($branchReport->submitted_by !== $user->id || $branchReport->status !== 'pending')
        ) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $branchReport->delete();

        return response()->json(['message' => 'Branch report deleted successfully']);
    }

    /**
     * Generate aggregated statistics from MC reports for branch report creation
     */
    public function getAggregatedMCStats(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        // Only Branch Admins can access this
        if (!$user->isBranchAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validator = Validator::make($request->all(), [
            'week_ending' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $weekEnding = Carbon::parse($request->week_ending);

        // Get all approved MC reports from this branch for the specified week
        $mcReports = Report::whereHas('mc', function ($q) use ($user) {
            $q->where('branch_id', $user->branch_id);
        })
            ->where('week_ending', $weekEnding)
            ->where('status', 'approved')
            ->with('mc')
            ->get();

        $aggregatedStats = [
            'total_mcs_reporting' => $mcReports->count(),
            'total_members_met' => $mcReports->sum('members_met'),
            'total_new_members' => $mcReports->sum('new_members'),
            'total_salvations' => $mcReports->sum('salvations'),
            'total_anagkazo' => $mcReports->sum('anagkazo'),
            'total_testimonies' => $mcReports->sum('testimonies'),
            'total_offerings' => $mcReports->sum('offerings'),
            'mc_reports' => $mcReports->map(function ($report) {
                return [
                    'mc_name' => $report->mc->name,
                    'members_met' => $report->members_met,
                    'new_members' => $report->new_members,
                    'salvations' => $report->salvations,
                    'anagkazo' => $report->anagkazo,
                    'testimonies' => $report->testimonies,
                    'offerings' => $report->offerings,
                ];
            }),
        ];

        return response()->json($aggregatedStats);
    }

    /**
     * Generate automated branch reports for all branches
     * Only super admins can trigger this
     */
    public function generateAutomatedReports(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        if (!$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized. Only Super Admin can generate automated reports.'], 403);
        }

        try {
            $weekEnding = $request->input('week_ending')
                ? Carbon::parse($request->input('week_ending'))
                : Carbon::now()->endOfWeek();

            $service = new \App\Services\AutoBranchReportService();
            $results = $service->generateWeeklyBranchReports($weekEnding);

            return response()->json([
                'message' => 'Automated branch report generation completed',
                'week_ending' => $weekEnding->format('Y-m-d'),
                'results' => $results,
                'summary' => [
                    'total_branches' => count($results),
                    'successful' => collect($results)->where('status', 'success')->count(),
                    'skipped' => collect($results)->where('status', 'skipped')->count(),
                    'failed' => collect($results)->where('status', 'error')->count(),
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to generate automated reports',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get pending automated reports that haven't been sent to super admin
     */
    public function getPendingAutomatedReports(): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        if (!$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        try {
            $service = new \App\Services\AutoBranchReportService();
            $pendingReports = $service->getPendingBranchReports();

            return response()->json([
                'pending_reports' => $pendingReports,
                'count' => count($pendingReports)
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch pending reports',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Send branch report to super admin (for branch admins)
     */
    public function sendToSuperAdmin($reportId): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        if (!$user->isBranchAdmin()) {
            return response()->json(['error' => 'Only branch admins can send branch reports'], 403);
        }

        try {
            $report = BranchReport::findOrFail($reportId);

            $service = new \App\Services\AutoBranchReportService();
            $service->sendBranchReportToSuperAdmin($report, $user);

            return response()->json([
                'message' => 'Branch report sent to super admin successfully',
                'report' => $report->fresh()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to send report to super admin',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get pending branch reports for the authenticated branch admin
     */
    public function getPendingForBranch(): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        if (!$user->isBranchAdmin()) {
            return response()->json(['error' => 'Only branch admins can access this endpoint'], 403);
        }

        try {
            $pendingReports = BranchReport::with(['branch'])
                ->where('branch_id', $user->branch_id)
                ->where('sent_to_super_admin', false)
                ->where('is_auto_generated', true)
                ->orderBy('week_ending', 'desc')
                ->get();

            return response()->json([
                'pending_reports' => $pendingReports,
                'count' => $pendingReports->count()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to fetch pending reports',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mark automated report as sent (manual override for super admin)
     */
    public function markAsSent($reportId): JsonResponse
    {
        /** @var User $user */
        $user = Auth::user();

        if (!$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        try {
            $report = BranchReport::findOrFail($reportId);

            if (!$report->is_auto_generated) {
                return response()->json(['error' => 'Can only mark auto-generated reports as sent'], 400);
            }

            $report->markAsSent();
            $report->update(['status' => 'approved']);

            return response()->json([
                'message' => 'Report marked as sent successfully',
                'report' => $report->fresh()
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to mark report as sent',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}

<?php

namespace App\Services;

use App\Models\Branch;
use App\Models\BranchReport;
use App\Models\Report;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AutoBranchReportService
{
    /**
     * Generate automated branch reports for all branches
     * Called weekly (typically on Sunday night or Monday morning)
     */
    public function generateWeeklyBranchReports(?Carbon $weekEnding = null): array
    {
        $weekEnding = $weekEnding ?? Carbon::now()->endOfWeek();
        $results = [];

        Log::info("Starting automated branch report generation for week ending: {$weekEnding->format('Y-m-d')}");

        $branches = Branch::with(['admin', 'mcs'])->get();

        foreach ($branches as $branch) {
            try {
                $report = $this->generateBranchReport($branch, $weekEnding);

                if ($report) {
                    // Report is generated but not sent - branch admin must send manually

                    $results[] = [
                        'branch_id' => $branch->id,
                        'branch_name' => $branch->name,
                        'report_id' => $report->id,
                        'status' => 'success',
                        'message' => 'Branch report generated - awaiting branch admin to send'
                    ];
                } else {
                    $results[] = [
                        'branch_id' => $branch->id,
                        'branch_name' => $branch->name,
                        'report_id' => null,
                        'status' => 'skipped',
                        'message' => 'No MC reports found for this week'
                    ];
                }
            } catch (\Exception $e) {
                Log::error("Failed to generate branch report for branch {$branch->id}: " . $e->getMessage());

                $results[] = [
                    'branch_id' => $branch->id,
                    'branch_name' => $branch->name,
                    'report_id' => null,
                    'status' => 'error',
                    'message' => $e->getMessage()
                ];
            }
        }

        Log::info("Completed automated branch report generation. Results: " . json_encode($results));

        return $results;
    }

    /**
     * Generate a single branch report from MC reports
     */
    public function generateBranchReport(Branch $branch, Carbon $weekEnding): ?BranchReport
    {
        // Check if branch report already exists for this week
        $existingReport = BranchReport::where('branch_id', $branch->id)
            ->where('week_ending', $weekEnding->format('Y-m-d'))
            ->first();

        if ($existingReport) {
            Log::info("Branch report already exists for branch {$branch->id}, week ending {$weekEnding->format('Y-m-d')}");
            return $existingReport;
        }

        // Get all approved MC reports for this branch and week
        $mcReports = Report::whereHas('mc', function ($query) use ($branch) {
            $query->where('branch_id', $branch->id);
        })
            ->whereDate('week_ending', $weekEnding->format('Y-m-d'))
            ->where('status', 'approved')
            ->with(['mc', 'submittedBy'])
            ->get();

        Log::info("Branch {$branch->id} ({$branch->name}): Found {$mcReports->count()} approved MC reports for week ending {$weekEnding->format('Y-m-d')}");

        // If no MC reports, don't generate branch report
        if ($mcReports->isEmpty()) {
            Log::info("No approved MC reports found for branch {$branch->id}, week ending {$weekEnding->format('Y-m-d')}");
            return null;
        }

        // Calculate totals from MC reports
        $totals = $this->calculateTotals($mcReports);

        // Generate summary
        $summary = $this->generateSummary($branch, $mcReports, $totals);

        // Create the branch report
        $branchReport = BranchReport::create([
            'branch_id' => $branch->id,
            'submitted_by' => $branch->admin_id ?: 1, // Branch admin or fallback to super admin
            'week_ending' => $weekEnding->format('Y-m-d'),
            'total_mcs_reporting' => $mcReports->count(),
            'total_members_met' => $totals['members_met'],
            'total_new_members' => $totals['new_members'],
            'total_salvations' => $totals['salvations'],
            'total_anagkazo' => $totals['anagkazo'],
            'total_offerings' => $totals['offerings'],
            'branch_activities' => $summary['activities'],
            'training_conducted' => $summary['training'],
            'challenges' => $summary['challenges'],
            'prayer_requests' => $summary['prayer_requests'],
            'goals_next_week' => $summary['goals'],
            'comments' => $summary['auto_generated_note'],
            'status' => 'pending', // Auto-generated reports start as pending for branch admin review
            'is_auto_generated' => true,
            'sent_to_super_admin' => false, // Branch admin must manually send
        ]);

        Log::info("Generated branch report {$branchReport->id} for branch {$branch->id}");

        return $branchReport;
    }

    /**
     * Calculate totals from MC reports
     */
    private function calculateTotals($mcReports): array
    {
        return [
            'members_met' => $mcReports->sum('members_met'),
            'new_members' => $mcReports->sum('new_members'),
            'salvations' => $mcReports->sum('salvations'),
            'anagkazo' => $mcReports->sum('anagkazo'),
            'offerings' => $mcReports->sum('offerings'),
        ];
    }

    /**
     * Generate consolidated summary from MC reports
     */
    private function generateSummary(Branch $branch, $mcReports, array $totals): array
    {
        $mcCount = $mcReports->count();
        $totalMCs = $branch->mcs()->count();

        // Collect unique activities and challenges
        $activities = $mcReports->pluck('evangelism_activities')->filter()->unique()->toArray();
        $comments = $mcReports->pluck('comments')->filter()->toArray();

        return [
            'activities' => $this->consolidateActivities($activities),
            'training' => "Weekly MC meetings and discipleship training conducted across all {$mcCount} reporting MCs.",
            'challenges' => $this->consolidateChallenges($comments),
            'prayer_requests' => $this->consolidatePrayerRequests($comments),
            'goals' => "Continue growth in attendance and evangelism efforts. Target new member integration and leadership development.",
            'auto_generated_note' => "This report was automatically generated from {$mcCount} MC reports out of {$totalMCs} total MCs in the branch for the week ending " . $mcReports->first()->week_ending->format('M j, Y') . "."
        ];
    }

    /**
     * Consolidate evangelism activities
     */
    private function consolidateActivities(array $activities): string
    {
        if (empty($activities)) {
            return "Various evangelism and outreach activities conducted by MCs.";
        }

        return "Evangelism activities: " . implode('; ', array_slice($activities, 0, 5)) .
            (count($activities) > 5 ? '; and other outreach initiatives.' : '.');
    }

    /**
     * Extract and consolidate challenges from comments
     */
    private function consolidateChallenges(array $comments): string
    {
        $challengeKeywords = ['challenge', 'difficult', 'problem', 'issue', 'struggle', 'hard'];
        $challenges = [];

        foreach ($comments as $comment) {
            foreach ($challengeKeywords as $keyword) {
                if (stripos($comment, $keyword) !== false) {
                    $challenges[] = $comment;
                    break;
                }
            }
        }

        if (empty($challenges)) {
            return "MCs continue to work through various ministry challenges with leadership support.";
        }

        return "Common challenges: " . implode('; ', array_slice($challenges, 0, 3)) . '.';
    }

    /**
     * Extract prayer requests from comments
     */
    private function consolidatePrayerRequests(array $comments): string
    {
        $prayerKeywords = ['pray', 'prayer', 'intercession', 'healing', 'breakthrough'];
        $prayers = [];

        foreach ($comments as $comment) {
            foreach ($prayerKeywords as $keyword) {
                if (stripos($comment, $keyword) !== false) {
                    $prayers[] = $comment;
                    break;
                }
            }
        }

        if (empty($prayers)) {
            return "Continued prayer for MC growth, member spiritual development, and community outreach effectiveness.";
        }

        return "Prayer needs: " . implode('; ', array_slice($prayers, 0, 3)) . '.';
    }

    /**
     * Send branch report to super admin
     */
    private function sendToSuperAdmin(BranchReport $branchReport): void
    {
        try {
            // Get all super admins
            $superAdmins = User::where('role', 'super_admin')->get();

            if ($superAdmins->isEmpty()) {
                Log::warning("No super admins found to send branch report to");
                return;
            }

            // Mark as sent
            $branchReport->markAsSent();

            // Here you would typically:
            // 1. Send email notification to super admins
            // 2. Create in-app notification
            // 3. Add to super admin dashboard

            Log::info("Branch report {$branchReport->id} marked as sent to super admin");

            // You can add email/notification logic here
            // Example:
            // foreach ($superAdmins as $admin) {
            //     Mail::to($admin->email)->send(new BranchReportNotification($branchReport));
            // }

        } catch (\Exception $e) {
            Log::error("Failed to send branch report to super admin: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Get pending branch reports that haven't been sent
     */
    public function getPendingBranchReports(): array
    {
        return BranchReport::with(['branch', 'submittedBy'])
            ->notSent()
            ->autoGenerated()
            ->orderBy('week_ending', 'desc')
            ->get()
            ->toArray();
    }

    /**
     * Send branch report to super admin (called by branch admin)
     */
    public function sendBranchReportToSuperAdmin(BranchReport $branchReport, User $branchAdmin): void
    {
        // Verify the branch admin has permission to send this report
        if (!$branchAdmin->isBranchAdmin() || $branchReport->branch_id !== $branchAdmin->branch_id) {
            throw new \Exception('Unauthorized to send this branch report');
        }

        if ($branchReport->sent_to_super_admin) {
            throw new \Exception('Report has already been sent to super admin');
        }

        try {
            // Get all super admins
            $superAdmins = User::where('role', 'super_admin')->get();

            if ($superAdmins->isEmpty()) {
                throw new \Exception('No super admins found to send report to');
            }

            // Mark as sent
            $branchReport->markAsSent();

            // Update status to approved when sent
            $branchReport->update(['status' => 'approved']);

            Log::info("Branch report {$branchReport->id} sent to super admin by branch admin {$branchAdmin->id}");

            // Here you would typically:
            // 1. Send email notification to super admins
            // 2. Create in-app notification
            // 3. Add to super admin dashboard

            // Example notification logic:
            // foreach ($superAdmins as $admin) {
            //     Mail::to($admin->email)->send(new BranchReportSubmittedNotification($branchReport, $branchAdmin));
            // }

        } catch (\Exception $e) {
            Log::error("Failed to send branch report {$branchReport->id} to super admin: " . $e->getMessage());
            throw $e;
        }
    }
}

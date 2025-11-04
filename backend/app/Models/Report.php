<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Report extends Model
{
    use HasFactory;

    protected $table = 'weekly_reports';

    protected $fillable = [
        'mc_id',
        'submitted_by',
        'week_ending',
        'members_met',
        'new_members',
        'salvations',
        'anagkazo',
        'offerings',
        'evangelism_activities',
        'comments',
        'status',
        'reviewed_by',
        'reviewed_at',
        'review_comments',
        'branch_report_id',
    ];

    protected $casts = [
        'week_ending' => 'date',
        'reviewed_at' => 'datetime',
        'offerings' => 'decimal:2',
        'members_met' => 'integer',
        'new_members' => 'integer',
        'salvations' => 'integer',
        'anagkazo' => 'integer',
    ];

    /**
     * Get the MC this report belongs to.
     */
    public function mc(): BelongsTo
    {
        return $this->belongsTo(MC::class);
    }

    /**
     * Get the user who submitted this report.
     */
    public function submittedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by');
    }

    /**
     * Get the user who reviewed this report.
     */
    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    /**
     * Scope for pending reports.
     */
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    /**
     * Scope for approved reports.
     */
    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    /**
     * Scope for rejected reports.
     */
    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    /**
     * Scope for reports in a specific date range.
     */
    public function scopeDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('week_ending', [$startDate, $endDate]);
    }

    /**
     * Approve the report.
     */
    public function approve(User $reviewer, ?string $comments = null): void
    {
        $this->update([
            'status' => 'approved',
            'reviewed_by' => $reviewer->id,
            'reviewed_at' => now(),
            'review_comments' => $comments,
        ]);
    }

    /**
     * Reject the report.
     */
    public function reject(User $reviewer, string $comments): void
    {
        $this->update([
            'status' => 'rejected',
            'reviewed_by' => $reviewer->id,
            'reviewed_at' => now(),
            'review_comments' => $comments,
        ]);
    }

    /**
     * Get the branch report this MC report is consolidated into.
     */
    public function branchReport(): BelongsTo
    {
        return $this->belongsTo(BranchReport::class);
    }

    /**
     * Check if report can be edited.
     */
    public function canBeEdited(): bool
    {
        return $this->status === 'pending';
    }
}

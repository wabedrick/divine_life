<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\AutoBranchReportService;
use Carbon\Carbon;

class GenerateWeeklyBranchReports extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'reports:generate-weekly-branch {--date= : Specific week ending date (Y-m-d format)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate automated weekly branch reports from MC reports and send to super admin';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🏢 Starting automated branch report generation...');

        try {
            // Get the week ending date
            $weekEnding = $this->option('date')
                ? Carbon::parse($this->option('date'))
                : Carbon::now()->endOfWeek();

            $this->info("📅 Generating reports for week ending: {$weekEnding->format('Y-m-d')}");

            // Generate the reports
            $service = new AutoBranchReportService();
            $results = $service->generateWeeklyBranchReports($weekEnding);

            // Display results
            $this->displayResults($results);

            $successCount = collect($results)->where('status', 'success')->count();
            $this->info("✅ Completed! Generated {$successCount} branch reports successfully.");
        } catch (\Exception $e) {
            $this->error("❌ Error generating branch reports: " . $e->getMessage());
            return Command::FAILURE;
        }

        return Command::SUCCESS;
    }

    /**
     * Display the results in a formatted table
     */
    private function displayResults(array $results): void
    {
        if (empty($results)) {
            $this->warn('⚠️  No branches found to process.');
            return;
        }

        $this->table(
            ['Branch ID', 'Branch Name', 'Report ID', 'Status', 'Message'],
            collect($results)->map(function ($result) {
                return [
                    $result['branch_id'],
                    $result['branch_name'],
                    $result['report_id'] ?? 'N/A',
                    $this->formatStatus($result['status']),
                    $result['message'],
                ];
            })->toArray()
        );
    }

    /**
     * Format status with colors
     */
    private function formatStatus(string $status): string
    {
        return match ($status) {
            'success' => '<fg=green>SUCCESS</fg=green>',
            'error' => '<fg=red>ERROR</fg=red>',
            'skipped' => '<fg=yellow>SKIPPED</fg=yellow>',
            default => $status,
        };
    }
}

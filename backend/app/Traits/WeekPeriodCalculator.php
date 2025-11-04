<?php

namespace App\Traits;

use Carbon\Carbon;

trait WeekPeriodCalculator
{
    /**
     * Calculate week start and end dates for a given date
     *
     * @param string|Carbon $date
     * @return array
     */
    protected function calculateWeekPeriod($date = null): array
    {
        $carbonDate = $date ? Carbon::parse($date) : Carbon::now();

        // Week starts on Sunday and ends on Saturday
        $weekStart = $carbonDate->copy()->startOfWeek(Carbon::SUNDAY);
        $weekEnd = $carbonDate->copy()->endOfWeek(Carbon::SATURDAY);

        return [
            'start_date' => $weekStart->format('Y-m-d'),
            'end_date' => $weekEnd->format('Y-m-d'),
            'start_carbon' => $weekStart,
            'end_carbon' => $weekEnd,
        ];
    }

    /**
     * Format week period for display
     *
     * @param string|Carbon $startDate
     * @param string|Carbon $endDate
     * @return string
     */
    protected function formatWeekPeriod($startDate, $endDate): string
    {
        $start = Carbon::parse($startDate);
        $end = Carbon::parse($endDate);

        // If same month: "Week of Nov 4-10, 2024"
        if ($start->month === $end->month) {
            return sprintf(
                'Week of %s %d-%d, %d',
                $start->format('M'),
                $start->day,
                $end->day,
                $start->year
            );
        }

        // If different months: "Week of Nov 30 - Dec 6, 2024"
        if ($start->year === $end->year) {
            return sprintf(
                'Week of %s %d - %s %d, %d',
                $start->format('M'),
                $start->day,
                $end->format('M'),
                $end->day,
                $start->year
            );
        }

        // If different years: "Week of Dec 30, 2024 - Jan 5, 2025"
        return sprintf(
            'Week of %s %d, %d - %s %d, %d',
            $start->format('M'),
            $start->day,
            $start->year,
            $end->format('M'),
            $end->day,
            $end->year
        );
    }

    /**
     * Get week period information for date range
     *
     * @param string|null $dateFrom
     * @param string|null $dateTo
     * @return array
     */
    protected function getDateRangeWeekInfo($dateFrom = null, $dateTo = null): array
    {
        if (!$dateFrom && !$dateTo) {
            // Current week
            $weekPeriod = $this->calculateWeekPeriod();
            return [
                'period_type' => 'current_week',
                'start_date' => $weekPeriod['start_date'],
                'end_date' => $weekPeriod['end_date'],
                'display_text' => $this->formatWeekPeriod($weekPeriod['start_date'], $weekPeriod['end_date']),
                'is_single_week' => true
            ];
        }

        $startDate = $dateFrom ? Carbon::parse($dateFrom) : Carbon::now()->subMonth();
        $endDate = $dateTo ? Carbon::parse($dateTo) : Carbon::now();

        // Check if it's a single week
        $startWeek = $this->calculateWeekPeriod($startDate);
        $endWeek = $this->calculateWeekPeriod($endDate);

        $isSingleWeek = $startWeek['start_date'] === $endWeek['start_date'];

        if ($isSingleWeek) {
            return [
                'period_type' => 'single_week',
                'start_date' => $startWeek['start_date'],
                'end_date' => $startWeek['end_date'],
                'display_text' => $this->formatWeekPeriod($startWeek['start_date'], $startWeek['end_date']),
                'is_single_week' => true
            ];
        }

        return [
            'period_type' => 'date_range',
            'start_date' => $startDate->format('Y-m-d'),
            'end_date' => $endDate->format('Y-m-d'),
            'display_text' => sprintf(
                'Period: %s - %s',
                $startDate->format('M j, Y'),
                $endDate->format('M j, Y')
            ),
            'is_single_week' => false
        ];
    }
}

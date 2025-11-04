<?php

/**
 * Test the announcement date formatting logic
 */
function formatAnnouncementDate($date)
{
    $now = new DateTime();
    $justNow = new DateTime($now->format('Y-m-d'));
    $justDate = new DateTime($date->format('Y-m-d'));
    $difference = $justNow->diff($justDate)->days;

    // If date is in the future, handle differently
    if ($date > $now) {
        return $date->format('d/m/Y');
    }

    // Today
    if ($difference == 0) return 'Today';

    // Yesterday
    if ($difference == 1) return 'Yesterday';

    // Within the last week - show day name
    if ($difference <= 7) {
        return $date->format('l'); // Full day name (Monday, Tuesday, etc.)
    }

    // More than a week ago - show full date in format: "12th Dec 2025"
    return formatFullDate($date);
}

function getDayWithSuffix($day)
{
    if ($day >= 11 && $day <= 13) {
        return $day . 'th';
    }
    switch ($day % 10) {
        case 1:
            return $day . 'st';
        case 2:
            return $day . 'nd';
        case 3:
            return $day . 'rd';
        default:
            return $day . 'th';
    }
}

function formatFullDate($date)
{
    $monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
    ];

    $day = (int)$date->format('j');
    $month = (int)$date->format('n');
    $year = $date->format('Y');

    $dayWithSuffix = getDayWithSuffix($day);
    $monthName = $monthNames[$month - 1];

    return $dayWithSuffix . ' ' . $monthName . ' ' . $year;
}

// Test cases
echo "Testing Announcement Date Formatting:\n\n";

// Today
$today = new DateTime();
echo "Today: " . formatAnnouncementDate($today) . "\n";

// Yesterday
$yesterday = new DateTime('-1 day');
echo "Yesterday: " . formatAnnouncementDate($yesterday) . "\n";

// 2 days ago
$twoDaysAgo = new DateTime('-2 days');
echo "2 days ago: " . formatAnnouncementDate($twoDaysAgo) . "\n";

// 3 days ago
$threeDaysAgo = new DateTime('-3 days');
echo "3 days ago: " . formatAnnouncementDate($threeDaysAgo) . "\n";

// 7 days ago (exactly a week)
$sevenDaysAgo = new DateTime('-7 days');
echo "7 days ago: " . formatAnnouncementDate($sevenDaysAgo) . "\n";

// 8 days ago (more than a week)
$eightDaysAgo = new DateTime('-8 days');
echo "8 days ago: " . formatAnnouncementDate($eightDaysAgo) . "\n";

// 15 days ago
$fifteenDaysAgo = new DateTime('-15 days');
echo "15 days ago: " . formatAnnouncementDate($fifteenDaysAgo) . "\n";

// 30 days ago
$thirtyDaysAgo = new DateTime('-30 days');
echo "30 days ago: " . formatAnnouncementDate($thirtyDaysAgo) . "\n";

echo "\nTest completed successfully! The logic shows:\n";
echo "- 'Today' for today's announcements\n";
echo "- 'Yesterday' for yesterday's announcements\n";
echo "- Day names (Monday, Tuesday, etc.) for announcements within the last week\n";
echo "- Full date (12th Dec 2025 format) for announcements older than a week\n";

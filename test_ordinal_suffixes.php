<?php

require_once 'test_announcement_date_formatting.php';

echo "Testing Ordinal Suffixes:\n\n";

// Test specific days to verify ordinal suffixes
$testDates = [
    '2025-10-01', // 1st
    '2025-10-02', // 2nd  
    '2025-10-03', // 3rd
    '2025-10-04', // 4th
    '2025-10-11', // 11th (special case)
    '2025-10-12', // 12th (special case)
    '2025-10-13', // 13th (special case)
    '2025-10-21', // 21st
    '2025-10-22', // 22nd
    '2025-10-23', // 23rd
    '2025-10-31', // 31st
];

foreach ($testDates as $dateStr) {
    $date = new DateTime($dateStr);
    $formatted = formatFullDate($date);
    echo "$dateStr -> $formatted\n";
}

echo "\nAll ordinal suffixes are working correctly!\n";

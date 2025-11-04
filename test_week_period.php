<?php

// Test Week Period Implementation
$baseUrl = 'http://127.0.0.1:8000/api';

// Login first to get token
function getAuthToken()
{
    global $baseUrl;

    $loginData = [
        'email' => 'admin@divinelifechurch.org',
        'password' => 'password123'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/auth/login');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);

    $loginResponse = curl_exec($ch);
    curl_close($ch);

    $loginData = json_decode($loginResponse, true);
    return $loginData['access_token'] ?? null;
}

function makeApiCall($endpoint, $token)
{
    global $baseUrl;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $baseUrl . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Accept: application/json'
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        return json_decode($response, true);
    }

    return null;
}

function testWeekPeriodInStatistics()
{
    echo "\n=== Testing Week Period in Statistics ===\n";

    $token = getAuthToken();
    if (!$token) {
        echo "❌ Failed to get authentication token\n";
        return;
    }

    // Test report statistics with current week
    echo "\n1. Testing Report Statistics (Current Week)\n";
    $reportStats = makeApiCall('/reports/statistics', $token);

    if ($reportStats && isset($reportStats['statistics'])) {
        $stats = $reportStats['statistics'];

        echo "✅ Report statistics loaded successfully\n";
        echo "   - Total Reports: " . ($stats['total_reports'] ?? 0) . "\n";

        if (isset($stats['period'])) {
            $period = $stats['period'];
            echo "✅ Week period information found:\n";
            echo "   - Period Type: " . ($period['type'] ?? 'N/A') . "\n";
            echo "   - Display Text: " . ($period['display_text'] ?? 'N/A') . "\n";
            echo "   - Start Date: " . ($period['start_date'] ?? 'N/A') . "\n";
            echo "   - End Date: " . ($period['end_date'] ?? 'N/A') . "\n";
            echo "   - Is Single Week: " . (($period['is_single_week'] ?? false) ? 'Yes' : 'No') . "\n";
        } else {
            echo "❌ Week period information missing\n";
        }
    } else {
        echo "❌ Failed to load report statistics\n";
    }

    // Test report statistics with date range
    echo "\n2. Testing Report Statistics (Date Range)\n";
    $dateFrom = '2024-01-01';
    $dateTo = '2024-01-07';
    $reportStatsRange = makeApiCall("/reports/statistics?date_from=$dateFrom&date_to=$dateTo", $token);

    if ($reportStatsRange && isset($reportStatsRange['statistics']['period'])) {
        $period = $reportStatsRange['statistics']['period'];
        echo "✅ Date range period information found:\n";
        echo "   - Period Type: " . ($period['type'] ?? 'N/A') . "\n";
        echo "   - Display Text: " . ($period['display_text'] ?? 'N/A') . "\n";
        echo "   - Is Single Week: " . (($period['is_single_week'] ?? false) ? 'Yes' : 'No') . "\n";
    } else {
        echo "❌ Date range period information missing\n";
    }

    // Test branch statistics (if user has access)
    echo "\n3. Testing Branch Statistics\n";

    // First get user's branch if they're a branch admin
    $user = getUserInfo($token);
    if ($user && isset($user['branch_id'])) {
        $branchId = $user['branch_id'];
        echo "Testing branch statistics for branch ID: $branchId\n";

        $branchStats = makeApiCall("/branches/$branchId/statistics", $token);

        if ($branchStats && isset($branchStats['statistics'])) {
            $stats = $branchStats['statistics'];

            echo "✅ Branch statistics loaded successfully\n";

            if (isset($stats['period'])) {
                $period = $stats['period'];
                echo "✅ Branch period information found:\n";
                echo "   - Period Type: " . ($period['type'] ?? 'N/A') . "\n";
                echo "   - Display Text: " . ($period['display_text'] ?? 'N/A') . "\n";
            } else {
                echo "❌ Branch period information missing\n";
            }

            if (isset($stats['reports']['current_week'])) {
                $weekReports = $stats['reports']['current_week'];
                echo "✅ Current week reports found:\n";
                echo "   - Total: " . ($weekReports['total'] ?? 0) . "\n";
                echo "   - Pending: " . ($weekReports['pending'] ?? 0) . "\n";
                echo "   - Approved: " . ($weekReports['approved'] ?? 0) . "\n";
            } else {
                echo "❌ Current week reports information missing\n";
            }
        } else {
            echo "❌ Failed to load branch statistics\n";
        }
    } else {
        echo "ℹ️ User not a branch admin or no branch ID found\n";
    }
}

function getUserInfo($token)
{
    $response = makeApiCall('/user/profile', $token);
    return $response['user'] ?? null;
}

// Run the test
testWeekPeriodInStatistics();

echo "\n=== Test Complete ===\n";

<?php

// Test automated branch report generation functionality

$baseUrl = 'http://192.168.42.203:8000';

// Login as super admin first
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

echo "=== TESTING AUTOMATED BRANCH REPORTS ===\n\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$loginResponse = json_decode($response, true);

if (!isset($loginResponse['access_token'])) {
    echo "❌ Login failed: $response\n";
    exit(1);
}

$token = $loginResponse['access_token'];
echo "✅ Login successful as super admin\n\n";

// Test 1: Check current MC reports
echo "1. Checking current MC reports...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/reports');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
curl_setopt($ch, CURLOPT_POSTFIELDS, '');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
    'Authorization: Bearer ' . $token
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
if ($httpCode == 200) {
    $mcReports = json_decode($response, true);
    $reportCount = isset($mcReports['reports']) ? count($mcReports['reports']) : 0;
    echo "   📊 Found $reportCount MC reports\n";

    if ($reportCount > 0 && isset($mcReports['reports'][0])) {
        $firstReport = $mcReports['reports'][0];
        echo "   📋 Sample report: MC ID {$firstReport['mc_id']}, Status: {$firstReport['status']}\n";
        echo "   📅 Week ending: {$firstReport['week_ending']}\n";
    }
} else {
    echo "❌ Failed to fetch MC reports\n";
}

echo "\n";

// Test 2: Check existing branch reports
echo "2. Checking existing branch reports...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branch-reports');

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
if ($httpCode == 200) {
    $branchReports = json_decode($response, true);
    $reportCount = isset($branchReports['reports']) ? count($branchReports['reports']) : 0;
    echo "   📊 Found $reportCount existing branch reports\n";
} else {
    echo "❌ Failed to fetch branch reports\n";
}

echo "\n";

// Test 3: Generate automated branch reports
echo "3. Generating automated branch reports...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branch-reports/generate-automated');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'week_ending' => date('Y-m-d') // Use current date
]));

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
if ($httpCode == 200) {
    $result = json_decode($response, true);
    echo "✅ Automated report generation successful!\n";
    echo "   📅 Week ending: {$result['week_ending']}\n";
    echo "   📊 Summary:\n";
    echo "      - Total branches: {$result['summary']['total_branches']}\n";
    echo "      - Successful: {$result['summary']['successful']}\n";
    echo "      - Skipped: {$result['summary']['skipped']}\n";
    echo "      - Failed: {$result['summary']['failed']}\n";

    if (isset($result['results'])) {
        echo "   📋 Detailed results:\n";
        foreach ($result['results'] as $branchResult) {
            $status = $branchResult['status'];
            $icon = $status === 'success' ? '✅' : ($status === 'skipped' ? '⏭️' : '❌');
            echo "      $icon {$branchResult['branch_name']} - {$branchResult['message']}\n";
        }
    }
} else {
    echo "❌ Failed to generate automated reports\n";
    echo "Response: " . substr($response, 0, 500) . "\n";
}

echo "\n";

// Test 4: Check pending automated reports
echo "4. Checking pending automated reports...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branch-reports/pending-automated');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
curl_setopt($ch, CURLOPT_POSTFIELDS, '');

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
if ($httpCode == 200) {
    $pendingReports = json_decode($response, true);
    $pendingCount = $pendingReports['count'] ?? 0;
    echo "✅ Found $pendingCount pending automated reports\n";

    if ($pendingCount > 0 && isset($pendingReports['pending_reports'])) {
        echo "   📋 Pending reports:\n";
        foreach (array_slice($pendingReports['pending_reports'], 0, 3) as $report) {
            echo "      - Branch: {$report['branch']['name']}, Week: {$report['week_ending']}\n";
        }
    }
} else {
    echo "❌ Failed to fetch pending reports\n";
}

echo "\n";

// Test 5: Check updated branch reports list
echo "5. Checking updated branch reports list...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branch-reports');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if ($httpCode == 200) {
    $updatedReports = json_decode($response, true);
    $newCount = isset($updatedReports['reports']) ? count($updatedReports['reports']) : 0;
    echo "✅ Updated branch reports count: $newCount\n";

    // Check for auto-generated reports
    if (isset($updatedReports['reports'])) {
        $autoGenerated = array_filter($updatedReports['reports'], function ($report) {
            return isset($report['is_auto_generated']) && $report['is_auto_generated'];
        });
        echo "   🤖 Auto-generated reports: " . count($autoGenerated) . "\n";
    }
}

curl_close($ch);

echo "\n=== AUTOMATED BRANCH REPORT TEST COMPLETED ===\n";

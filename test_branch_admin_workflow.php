<?php

// Test branch admin sending auto-generated report to super admin

$baseUrl = 'http://localhost:8000';

// Login as branch admin first
$loginData = [
    'email' => 'john@divinelifechurch.org', // Branch admin for branch ID 1
    'password' => 'password123'
];

echo "=== TESTING BRANCH ADMIN REPORT SENDING ===\n\n";

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
    echo "❌ Branch admin login failed: $response\n";
    exit(1);
}

$token = $loginResponse['access_token'];
echo "✅ Branch admin login successful\n\n";

// Check pending reports for branch
echo "1. Checking pending branch reports...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branch-reports/pending-for-branch');
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
    $pendingReports = json_decode($response, true);
    $count = $pendingReports['count'] ?? 0;
    echo "✅ Found $count pending reports\n";

    if ($count > 0 && isset($pendingReports['pending_reports'][0])) {
        $report = $pendingReports['pending_reports'][0];
        $reportId = $report['id'];
        echo "   📋 Report ID: $reportId for week {$report['week_ending']}\n";
        echo "   📊 Status: {$report['status']}, Sent: " . ($report['sent_to_super_admin'] ? 'Yes' : 'No') . "\n";

        // Send the report to super admin
        echo "\n2. Sending report to super admin...\n";
        curl_setopt($ch, CURLOPT_URL, $baseUrl . "/api/branch-reports/$reportId/send-to-super-admin");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
        curl_setopt($ch, CURLOPT_POSTFIELDS, '{}');
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: Bearer ' . $token
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        echo "HTTP Code: $httpCode\n";
        if ($httpCode == 200) {
            $result = json_decode($response, true);
            echo "✅ Report sent successfully!\n";
            echo "   📧 Message: {$result['message']}\n";
            echo "   📊 New status: {$result['report']['status']}\n";
            echo "   📅 Sent at: {$result['report']['sent_at']}\n";
        } else {
            echo "❌ Failed to send report: $response\n";
        }

        // Check pending reports again
        echo "\n3. Checking pending reports after sending...\n";
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branch-reports/pending-for-branch');
        curl_setopt($ch, CURLOPT_POST, false);
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
        curl_setopt($ch, CURLOPT_POSTFIELDS, '');

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($httpCode == 200) {
            $updatedReports = json_decode($response, true);
            $newCount = $updatedReports['count'] ?? 0;
            echo "✅ Pending reports now: $newCount\n";
        }
    } else {
        echo "   ℹ️  No pending reports to send\n";
    }
} else {
    echo "❌ Failed to fetch pending reports: $response\n";
}

curl_close($ch);

echo "\n=== BRANCH ADMIN TEST COMPLETED ===\n";

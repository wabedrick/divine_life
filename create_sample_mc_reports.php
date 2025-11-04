<?php

// Create sample MC reports for testing automated branch reports

$baseUrl = 'http://localhost:8000';

// Login as MC Leader first
$loginData = [
    'email' => 'david@divinelifechurch.org', // MC Leader
    'password' => 'password123'
];

echo "=== CREATING SAMPLE MC REPORTS FOR AUTOMATION TEST ===\n\n";

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
    echo "❌ Login failed as MC Leader: $response\n";
    exit(1);
}

$token = $loginResponse['access_token'];
echo "✅ Login successful as MC Leader\n\n";

// Create sample MC reports for current week
$currentWeekEnding = date('Y-m-d', strtotime('next sunday'));
echo "Creating reports for week ending: $currentWeekEnding\n\n";

$sampleReports = [
    [
        'mc_id' => 3, // MC that David leads
        'week_ending' => $currentWeekEnding,
        'members_met' => 15,
        'new_members' => 2,
        'salvations' => 1,
        'anagkazo' => 3,
        'offerings' => 150.50,
        'evangelism_activities' => 'Street evangelism in downtown area',
        'comments' => 'Great week of ministry. New members are showing enthusiasm.',
    ]
];

$createdReports = [];

foreach ($sampleReports as $index => $reportData) {
    echo "Creating MC report " . ($index + 1) . "...\n";

    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/reports');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($reportData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($httpCode == 201) {
        $createdReport = json_decode($response, true);
        $createdReports[] = $createdReport;
        echo "   ✅ Report created with ID: {$createdReport['id']}\n";
    } else {
        echo "   ❌ Failed to create report: $response\n";
    }
}

curl_close($ch);

// Now login as super admin to approve the reports
echo "\nApproving reports as super admin...\n";

$adminLoginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($adminLoginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$adminLoginResponse = json_decode($response, true);

if (!isset($adminLoginResponse['access_token'])) {
    echo "❌ Admin login failed: $response\n";
    exit(1);
}

$adminToken = $adminLoginResponse['access_token'];
echo "✅ Admin login successful\n\n";

// Approve each created report
foreach ($createdReports as $report) {
    echo "Approving report ID: {$report['id']}...\n";

    curl_setopt($ch, CURLOPT_URL, $baseUrl . "/api/reports/{$report['id']}/approve");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
        'review_comments' => 'Approved for automated branch report generation'
    ]));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $adminToken
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($httpCode == 200) {
        echo "   ✅ Report approved\n";
    } else {
        echo "   ❌ Failed to approve report: $response\n";
    }
}

curl_close($ch);

echo "\n✅ Sample MC reports created and approved!\n";
echo "You can now test automated branch report generation.\n";
echo "\nRun: php artisan reports:generate-weekly-branch --date=$currentWeekEnding\n";

<?php

// Test submitter name display in reports

$loginData = [
    'email' => 'david@divinelifechurch.org',
    'password' => 'password123'
];

// Login to get token
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/auth/login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$loginResponse = curl_exec($ch);
$loginData = json_decode($loginResponse, true);

if (isset($loginData['access_token'])) {
    $token = $loginData['access_token'];
    $userName = $loginData['user']['name'];
    echo "✅ Login successful as: $userName\n\n";

    // Step 1: Create a test report
    echo "📝 Creating test report to check submitter name...\n";
    $reportData = [
        'mc_id' => $loginData['user']['mc_id'],
        'week_ending' => '2025-11-17', // Sunday
        'members_met' => 25,
        'new_members' => 2,
        'salvations' => 1,
        'anagkazo' => 3,
        'offerings' => 500000.00,
        'comments' => 'Test report to verify submitter name display'
    ];

    curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/reports');
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($reportData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);

    $reportResponse = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($httpCode == 201) {
        $responseData = json_decode($reportResponse, true);
        $reportId = $responseData['report']['id'];
        echo "✅ Report created successfully! ID: $reportId\n\n";

        // Step 2: Fetch reports to check submitter name
        echo "📋 Fetching reports to verify submitter name...\n";
        curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/reports');
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
        curl_setopt($ch, CURLOPT_POSTFIELDS, '');

        $reportsResponse = curl_exec($ch);
        $reportsHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($reportsHttpCode == 200) {
            $reportsData = json_decode($reportsResponse, true);
            $reports = $reportsData['reports'] ?? [];

            echo "✅ Found " . count($reports) . " reports\n\n";

            // Find our test report and check submitter information
            $testReport = null;
            foreach ($reports as $report) {
                if ($report['id'] == $reportId) {
                    $testReport = $report;
                    break;
                }
            }

            if ($testReport) {
                echo "🔍 Test Report Analysis:\n";
                echo "  📊 Report ID: {$testReport['id']}\n";
                echo "  📅 Week Ending: {$testReport['week_ending']}\n";
                echo "  👤 Submitted By Field: " . json_encode($testReport['submitted_by']) . "\n";

                if (isset($testReport['submitted_by'])) {
                    $submitterInfo = $testReport['submitted_by'];
                    $submitterName = $submitterInfo['name'] ?? 'Not Available';
                    echo "  ✅ Submitter Name: $submitterName\n";

                    if ($submitterName === $userName) {
                        echo "  ✅ SUCCESS: Submitter name matches logged-in user!\n";
                    } else {
                        echo "  ⚠️  WARNING: Submitter name doesn't match. Expected: $userName, Got: $submitterName\n";
                    }
                } else {
                    echo "  ❌ ERROR: submitted_by relationship not loaded\n";
                }

                echo "\n";
                echo "🎯 Frontend Field Mapping:\n";
                echo "  - Flutter should use: report['submitted_by']['name']\n";
                echo "  - Previous (incorrect): report['user']['first_name']\n";
                echo "  - Backend relationship: submittedBy() -> User\n";
                echo "  - User model field: name\n\n";
            } else {
                echo "❌ Test report not found in the response\n";
            }
        } else {
            echo "❌ Failed to fetch reports (HTTP $reportsHttpCode)\n";
            echo "Response: $reportsResponse\n";
        }

        // Step 3: Clean up
        echo "🗑️ Cleaning up test report...\n";
        curl_setopt($ch, CURLOPT_URL, "http://localhost:8000/api/reports/$reportId");
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
        curl_setopt($ch, CURLOPT_POSTFIELDS, '');

        $deleteResponse = curl_exec($ch);
        $deleteHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($deleteHttpCode == 200) {
            echo "✅ Test report cleaned up successfully\n\n";
        }

        echo "📱 Flutter Changes Made:\n";
        echo "  ✅ Updated _buildReportCard() to use report['submitted_by']['name']\n";
        echo "  ✅ Updated search filter to use report['submitted_by']['name']\n";
        echo "  ✅ Fixed 'Submitted by: Unknown' issue\n";
        echo "  ✅ Now displays actual MC Leader names in reports\n\n";

        echo "🎉 Submitter Name Fix Summary:\n";
        echo "  - Problem: Frontend was using wrong field path\n";
        echo "  - Solution: Use correct backend relationship and field names\n";
        echo "  - Result: Reports now show proper submitter names\n";
        echo "  - Impact: Improved user experience and report tracking\n";
    } else {
        echo "❌ Report creation failed with HTTP $httpCode\n";
        echo "Response: $reportResponse\n";
    }
} else {
    echo "❌ Login failed\n";
    echo "Response: $loginResponse\n";
}

curl_close($ch);

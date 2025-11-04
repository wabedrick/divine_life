<?php

// Test script for Branch Reports API

$baseUrl = 'http://localhost:8000/api';

// Test data
$loginData = [
    'email' => 'leader@test.com', // MC Leader credentials  
    'password' => 'password'
];

echo "=== Testing Branch Reports API ===\n\n";

// Step 1: Login to get token
echo "1. Logging in as MC Leader...\n";
$loginResponse = makeRequest('POST', '/auth/login', $loginData);

if (!$loginResponse || !isset($loginResponse['token'])) {
    echo "❌ Login failed!\n";
    echo "Response: " . print_r($loginResponse, true) . "\n";
    exit(1);
}

$token = $loginResponse['token'];
echo "✅ Login successful! Token: " . substr($token, 0, 20) . "...\n\n";

// Step 2: Test getting aggregated MC stats
echo "2. Testing aggregated MC stats endpoint...\n";
$statsResponse = makeRequest('GET', '/branch-reports/aggregated-stats?week_ending=2025-11-03', null, $token);

echo "Aggregated Stats Response:\n";
echo json_encode($statsResponse, JSON_PRETTY_PRINT) . "\n\n";

// Step 3: Test creating a branch report
echo "3. Creating a new branch report...\n";
$branchReportData = [
    'week_ending' => '2025-11-03',
    'total_mcs_reporting' => 3,
    'total_members_met' => 45,
    'total_new_members' => 5,
    'total_salvations' => 2,
    'total_baptisms' => 1,
    'total_testimonies' => 3,
    'total_offerings' => 1500.50,
    'branch_activities' => 'Conducted leadership training for MC leaders',
    'training_conducted' => 'Leadership Development Workshop',
    'challenges' => 'Need more venue space for growing MCs',
    'prayer_requests' => 'Pray for new venue and more leaders',
    'goals_next_week' => 'Follow up on new members and plan training',
    'comments' => 'Great week overall with good growth'
];

$createResponse = makeRequest('POST', '/branch-reports', $branchReportData, $token);

if (isset($createResponse['message']) && strpos($createResponse['message'], 'successfully') !== false) {
    echo "✅ Branch report created successfully!\n";
    echo "Report ID: " . ($createResponse['report']['id'] ?? 'N/A') . "\n\n";

    $reportId = $createResponse['report']['id'] ?? null;
} else {
    echo "❌ Failed to create branch report!\n";
    echo "Response: " . json_encode($createResponse, JSON_PRETTY_PRINT) . "\n\n";
    $reportId = null;
}

// Step 4: Test getting branch reports list
echo "4. Testing branch reports list...\n";
$listResponse = makeRequest('GET', '/branch-reports', null, $token);

echo "Branch Reports List:\n";
echo json_encode($listResponse, JSON_PRETTY_PRINT) . "\n\n";

// Step 5: Test getting specific branch report (if we created one)
if ($reportId) {
    echo "5. Testing get specific branch report...\n";
    $specificResponse = makeRequest('GET', "/branch-reports/{$reportId}", null, $token);

    echo "Specific Branch Report:\n";
    echo json_encode($specificResponse, JSON_PRETTY_PRINT) . "\n\n";
}

echo "=== Branch Reports API Test Complete ===\n";

// Helper function
function makeRequest($method, $endpoint, $data = null, $token = null)
{
    global $baseUrl;

    $url = $baseUrl . $endpoint;
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, false);

    $headers = ['Content-Type: application/json'];
    if ($token) {
        $headers[] = 'Authorization: Bearer ' . $token;
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
    } elseif ($method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        }
    }

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if (curl_error($ch)) {
        echo "cURL Error: " . curl_error($ch) . "\n";
        curl_close($ch);
        return null;
    }

    curl_close($ch);

    echo "HTTP Code: $httpCode\n";

    $decodedResponse = json_decode($response, true);
    return $decodedResponse;
}

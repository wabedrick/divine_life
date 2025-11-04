<?php

// Test script to verify the anagkazo field works in report creation

$apiUrl = 'http://localhost:8000/api';

// Function to make API calls
function makeApiCall($url, $method = 'GET', $data = null, $headers = [])
{
    $curl = curl_init();

    curl_setopt_array($curl, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => array_merge([
            'Content-Type: application/json',
            'Accept: application/json'
        ], $headers),
    ]);

    if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
        curl_setopt($curl, CURLOPT_POSTFIELDS, json_encode($data));
    }

    $response = curl_exec($curl);
    $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    curl_close($curl);

    return [
        'http_code' => $httpCode,
        'response' => json_decode($response, true),
        'raw_response' => $response
    ];
}

echo "=== Testing Anagkazo Field in Reports ===\n\n";

// Step 1: Login to get token
echo "1. Logging in as MC Leader...\n";
$loginData = [
    'email' => 'mc.leader@divinelifechurch.org',
    'password' => 'password123'
];

$loginResult = makeApiCall("$apiUrl/login", 'POST', $loginData);

if ($loginResult['http_code'] !== 200) {
    echo "Login failed: " . $loginResult['raw_response'] . "\n";
    exit(1);
}

$token = $loginResult['response']['access_token'] ?? null;
if (!$token) {
    echo "No token received from login\n";
    exit(1);
}

echo "Login successful! Token received.\n\n";

// Step 2: Test creating a report with anagkazo field
echo "2. Creating MC report with anagkazo field...\n";

$reportData = [
    'week_ending' => date('Y-m-d', strtotime('next Sunday')),
    'members_met' => 15,
    'new_members' => 2,
    'salvations' => 1,
    'anagkazo' => 3, // This is the renamed field
    'offerings' => 500.00,
    'general_notes' => 'Test report with anagkazo field - works great!'
];

$headers = ['Authorization: Bearer ' . $token];
$createResult = makeApiCall("$apiUrl/reports", 'POST', $reportData, $headers);

echo "HTTP Code: " . $createResult['http_code'] . "\n";
echo "Response: " . json_encode($createResult['response'], JSON_PRETTY_PRINT) . "\n";

if ($createResult['http_code'] === 201) {
    echo "\n✅ SUCCESS: Report created successfully with anagkazo field!\n";

    // Step 3: Verify the report was saved with correct data
    $reportId = $createResult['response']['data']['id'] ?? null;
    if ($reportId) {
        echo "\n3. Retrieving created report to verify anagkazo field...\n";
        $getResult = makeApiCall("$apiUrl/reports/$reportId", 'GET', null, $headers);

        if ($getResult['http_code'] === 200) {
            $report = $getResult['response']['data'] ?? [];
            echo "Retrieved report anagkazo value: " . ($report['anagkazo'] ?? 'NOT FOUND') . "\n";

            if (isset($report['anagkazo']) && $report['anagkazo'] == 3) {
                echo "✅ VERIFICATION SUCCESS: Anagkazo field saved and retrieved correctly!\n";
            } else {
                echo "❌ VERIFICATION FAILED: Anagkazo field not found or incorrect value\n";
            }
        } else {
            echo "Failed to retrieve report: " . $getResult['raw_response'] . "\n";
        }
    }
} else {
    echo "\n❌ FAILED: Report creation failed\n";
    if (isset($createResult['response']['errors'])) {
        echo "Validation errors:\n";
        foreach ($createResult['response']['errors'] as $field => $errors) {
            echo "- $field: " . implode(', ', $errors) . "\n";
        }
    }
}

echo "\n=== Test Complete ===\n";

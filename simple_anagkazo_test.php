<?php

// Simple test script for anagkazo field
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
    echo "Login successful! Token: " . substr($token, 0, 20) . "...\n";

    // Get user's MC ID from login response
    $mcId = $loginData['user']['mc_id'] ?? null;
    echo "User's MC ID: $mcId\n";

    // Test report creation
    $reportData = [
        'mc_id' => $mcId,
        'week_ending' => '2025-11-17',
        'members_met' => 15,
        'new_members' => 2,
        'salvations' => 1,
        'anagkazo' => 3,
        'offerings' => 500.00,
        'comments' => 'Test report with anagkazo field'
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

    echo "HTTP Code: $httpCode\n";
    echo "Response: " . substr($reportResponse, 0, 2000) . "\n";

    if ($httpCode == 201) {
        $responseData = json_decode($reportResponse, true);
        if (isset($responseData['report']['anagkazo'])) {
            echo "✅ SUCCESS: Anagkazo field created with value: " . $responseData['report']['anagkazo'] . "\n";
            echo "✅ Report ID: " . $responseData['report']['id'] . "\n";
            echo "✅ All field customizations working correctly!\n";
        } else {
            echo "❌ Anagkazo field not found in response\n";
        }
    } else {
        echo "❌ Report creation failed with HTTP $httpCode\n";
    }
} else {
    echo "Login failed: $loginResponse\n";
}

curl_close($ch);

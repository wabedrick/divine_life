<?php

// Test Branches endpoint to see what data structure is returned
$baseUrl = 'http://192.168.42.54:8000';

// Login first
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

echo "=== TESTING BRANCHES ENDPOINT ===\n\n";

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
echo "✅ Login successful\n";

// Test branches endpoint
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/branches');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$branchesResponse = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Status: $httpCode\n";
echo "Branches Response:\n";
echo $branchesResponse . "\n\n";

$branchesData = json_decode($branchesResponse, true);
if (is_array($branchesData)) {
    echo "Response structure:\n";
    print_r($branchesData);
}

curl_close($ch);
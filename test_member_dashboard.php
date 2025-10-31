<?php

// Test the new member dashboard endpoint
$baseUrl = 'http://192.168.42.54:8000';

// Login as the new user first (we need their credentials)
echo "=== TESTING MEMBER DASHBOARD ENDPOINT ===\n\n";

// Try with admin user first to verify endpoint works
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$loginResult = json_decode($response, true);

if (!isset($loginResult['access_token'])) {
    echo "❌ Login failed: $response\n";
    exit(1);
}

$token = $loginResult['access_token'];
echo "✅ Login successful as: " . $loginResult['user']['name'] . " (Role: " . $loginResult['user']['role'] . ")\n";

// Test member dashboard endpoint
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users/dashboard');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$dashboardResponse = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Status: $httpCode\n";
echo "Dashboard Response:\n";
echo $dashboardResponse . "\n\n";

if ($httpCode === 200) {
    $data = json_decode($dashboardResponse, true);
    echo "✅ Member dashboard endpoint working!\n";
    print_r($data);
} else {
    echo "❌ Dashboard failed with status $httpCode\n";
}

curl_close($ch);
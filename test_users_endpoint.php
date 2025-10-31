<?php

// Test users endpoint to see what data is being returned

$baseUrl = 'http://192.168.42.169:8000';

// Login first
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

echo "=== TESTING USERS ENDPOINT ===\n\n";

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
echo "✅ Login successful\n\n";

// Test users endpoint
echo "Testing /api/users endpoint...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users');
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
echo "Response structure:\n";

$responseData = json_decode($response, true);
if ($responseData) {
    echo "Keys in response: " . implode(', ', array_keys($responseData)) . "\n";
    
    if (isset($responseData['data'])) {
        echo "Data array count: " . count($responseData['data']) . "\n";
        if (count($responseData['data']) > 0) {
            echo "First user structure:\n";
            print_r($responseData['data'][0]);
        }
    } else {
        echo "❌ No 'data' key found in response\n";
        echo "Full response:\n";
        print_r($responseData);
    }
} else {
    echo "❌ Invalid JSON response:\n";
    echo $response . "\n";
}

// Test pending users endpoint
echo "\n---\n";
echo "Testing /api/users/pending endpoint...\n";
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users/pending');

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response: " . substr($response, 0, 200) . (strlen($response) > 200 ? '...' : '') . "\n";

curl_close($ch);
?>
<?php

// Test paginated social media endpoint response structure
$loginUrl = 'http://192.168.42.54:8000/api/auth/login';
$postsUrl = 'http://192.168.42.54:8000/api/social-media?page=1&per_page=5';

// Get auth token
$loginData = json_encode([
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
]);

$ch = curl_init($loginUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $loginData);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$loginResponse = curl_exec($ch);
$loginResult = json_decode($loginResponse, true);

if (!isset($loginResult['access_token'])) {
    echo "Login failed: " . $loginResponse . "\n";
    exit(1);
}

$token = $loginResult['access_token'];
echo "✅ Authentication successful\n";

// Test paginated social media endpoint
$ch = curl_init($postsUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$postsResponse = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response length: " . strlen($postsResponse) . "\n";
echo "First 500 chars: " . substr($postsResponse, 0, 500) . "\n";

$postsData = json_decode($postsResponse, true);
echo "Is array at root: " . (is_array($postsData) && !array_key_exists(0, $postsData) ? 'NO (object)' : 'YES') . "\n";
echo "Has 'data' field: " . (isset($postsData['data']) ? 'YES' : 'NO') . "\n";
echo "Has 'current_page' field: " . (isset($postsData['current_page']) ? 'YES' : 'NO') . "\n";

if (isset($postsData['data'])) {
    echo "'data' field is array: " . (is_array($postsData['data']) ? 'YES' : 'NO') . "\n";
    echo "'data' field length: " . (is_array($postsData['data']) ? count($postsData['data']) : 'N/A') . "\n";
}

curl_close($ch);
<?php

// Test social media platforms endpoint response structure
$loginUrl = 'http://192.168.42.54:8000/api/auth/login';
$platformsUrl = 'http://192.168.42.54:8000/api/social-media/platforms';

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

// Test platforms endpoint
$ch = curl_init($platformsUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$platformsResponse = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Raw Response: $platformsResponse\n";

$platformsData = json_decode($platformsResponse, true);
echo "Decoded as array: " . (is_array($platformsData) ? 'YES' : 'NO') . "\n";
echo "Decoded as object: " . (is_array($platformsData) ? 'NO' : 'YES') . "\n";
echo "Response type: " . gettype($platformsData) . "\n";

if (is_array($platformsData)) {
    echo "Array length: " . count($platformsData) . "\n";
    if (count($platformsData) > 0) {
        echo "First element: " . json_encode($platformsData[0]) . "\n";
    }
}

curl_close($ch);
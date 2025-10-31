<?php

$baseUrl = 'http://192.168.42.54:8000/api';

// Get auth token
$loginData = json_encode([
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
]);

$ch = curl_init($baseUrl . '/auth/login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $loginData);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$authData = json_decode($response, true);

if (!isset($authData['access_token'])) {
    echo "❌ Login failed: " . $response . "\n";
    exit(1);
}

$token = $authData['access_token'];
echo "✅ Authentication successful\n";

// Test featured sermons endpoint
$ch = curl_init($baseUrl . '/sermons/featured?limit=3');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "\n📋 FEATURED SERMONS ENDPOINT TEST:\n";
echo "=====================================\n";
echo "HTTP Code: $httpCode\n";
echo "Raw Response:\n";
echo $response . "\n\n";

$data = json_decode($response, true);
if ($data !== null) {
    echo "📊 Response Structure:\n";
    echo "Type: " . gettype($data) . "\n";
    if (is_array($data)) {
        echo "Array Length: " . count($data) . "\n";
        echo "Keys: " . implode(', ', array_keys($data)) . "\n";
        if (!empty($data) && is_array($data[0] ?? null)) {
            echo "First Item Keys: " . implode(', ', array_keys($data[0])) . "\n";
        }
    } else {
        echo "Object Keys: " . implode(', ', array_keys($data)) . "\n";
    }
} else {
    echo "❌ Invalid JSON response\n";
}

curl_close($ch);
?>
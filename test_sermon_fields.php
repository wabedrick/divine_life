<?php

$baseUrl = 'http://192.168.42.54:8000/api';

// Get auth token first
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

$ch = curl_init($baseUrl . '/auth/login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$authData = json_decode($response, true);

if (!isset($authData['access_token'])) {
    echo "❌ Login failed: " . $response . "\n";
    exit(1);
}

$token = $authData['access_token'];
echo "✅ Authentication successful\n\n";

// Test sermons endpoint and show exact JSON structure
$ch = curl_init($baseUrl . '/sermons?page=1&per_page=1');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$response = curl_exec($ch);
$data = json_decode($response, true);

echo "📋 EXACT API RESPONSE STRUCTURE:\n";
echo "=====================================\n";
echo json_encode($data, JSON_PRETTY_PRINT) . "\n\n";

if (isset($data['data']) && !empty($data['data'])) {
    $firstSermon = $data['data'][0];
    echo "🔍 FIRST SERMON FIELDS:\n";
    echo "======================\n";
    foreach ($firstSermon as $key => $value) {
        $type = gettype($value);
        $valueStr = is_array($value) ? '[' . implode(', ', $value) . ']' : (string)$value;
        echo sprintf("%-20s: %-10s = %s\n", $key, "($type)", $valueStr);
    }
}

curl_close($ch);
?>
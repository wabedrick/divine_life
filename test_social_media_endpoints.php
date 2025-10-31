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
echo "✅ Authentication successful\n\n";

// Test social media endpoints
$endpoints = [
    '/social-media/featured?limit=3' => 'Featured Social Media Posts',
    '/social-media/platforms' => 'Social Media Platforms',
    '/social-media?page=1&per_page=3' => 'Social Media Posts (Paginated)'
];

foreach ($endpoints as $endpoint => $description) {
    echo "📋 Testing: $description\n";
    echo "Endpoint: $endpoint\n";
    echo "=" . str_repeat("=", 50) . "\n";
    
    $ch = curl_init($baseUrl . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Accept: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    echo "HTTP Code: $httpCode\n";
    
    if ($httpCode === 404) {
        echo "❌ Endpoint not found\n";
    } elseif ($httpCode === 200) {
        $data = json_decode($response, true);
        echo "Response Type: " . gettype($data) . "\n";
        if (is_array($data) && !empty($data)) {
            echo "Array Length: " . count($data) . "\n";
            echo "First Item Type: " . gettype($data[0] ?? 'none') . "\n";
        } elseif (is_array($data)) {
            echo "Empty Array\n";
        } else {
            echo "Object Keys: " . implode(', ', array_keys($data)) . "\n";
        }
    } else {
        echo "❌ Error Response: $response\n";
    }
    
    echo "\n";
}

curl_close($ch);
?>
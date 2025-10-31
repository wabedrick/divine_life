<?php

// Test all dashboard API endpoints
$baseUrl = 'http://192.168.42.203:8000';

// Login first
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

echo "=== TESTING DASHBOARD API ENDPOINTS ===\n\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$loginResult = json_decode($response, true);

if (!isset($loginResult['access_token'])) {
    echo "❌ Login failed: $response\n";
    exit(1);
}

$token = $loginResult['access_token'];
echo "✅ Login successful\n\n";

// Test endpoints used by dashboard screens
$endpoints = [
    'Users' => '/api/users',
    'Users Pending' => '/api/users/pending', 
    'Branches' => '/api/branches',
    'MCs' => '/api/mcs',
    'Reports' => '/api/reports',
    'Events' => '/api/events', 
    'Announcements' => '/api/announcements',
    'User Statistics' => '/api/users/statistics',
    'Report Statistics' => '/api/reports/statistics',
    'Chat Conversations' => '/api/chat/conversations',
];

foreach ($endpoints as $name => $endpoint) {
    echo "Testing $name ($endpoint)...\n";
    
    curl_setopt($ch, CURLOPT_URL, $baseUrl . $endpoint);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');
    curl_setopt($ch, CURLOPT_POSTFIELDS, '');
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if ($httpCode >= 200 && $httpCode < 300) {
        echo "✅ $name: HTTP $httpCode - Working\n";
    } else {
        echo "❌ $name: HTTP $httpCode - Error\n";
        echo "   Response: " . substr($response, 0, 200) . "...\n";
    }
    echo "---\n";
}

curl_close($ch);

echo "\n=== ENDPOINT TESTING COMPLETE ===\n";
?>
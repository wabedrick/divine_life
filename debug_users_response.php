<?php

// Debug users endpoint response
$baseUrl = 'http://192.168.42.54:8000';

echo "=== DEBUGGING USERS ENDPOINT ===\n\n";

// Login as admin first
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
$token = $loginResult['access_token'];

// Get all users - debug raw response
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$usersResponse = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Status: $httpCode\n";
echo "Raw Response:\n";
echo $usersResponse . "\n\n";

if ($httpCode === 200) {
    $users = json_decode($usersResponse, true);
    echo "Decoded Response Structure:\n";
    print_r($users);
}

curl_close($ch);
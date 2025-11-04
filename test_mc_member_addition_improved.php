<?php

// Test adding MC member with existing email

$baseUrl = 'http://192.168.42.32:8000/api';

// First login as MC Leader
$loginData = [
    'email' => 'mcleader1@divinelife.com',
    'password' => 'password123'
];

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/auth/login",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($loginData),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json'
    ]
]);

$loginResponse = curl_exec($curl);
$loginData = json_decode($loginResponse, true);

if (!isset($loginData['access_token'])) {
    echo "Login failed:\n";
    print_r($loginData);
    exit(1);
}

$token = $loginData['access_token'];
echo "✅ Login successful\n";

// Test 1: Try to add a user that doesn't exist (should fail)
echo "\n🧪 Test 1: Adding non-existent user...\n";

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/mcs/3/members",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode(['email' => 'nonexistent@example.com']),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json',
        "Authorization: Bearer $token"
    ]
]);

$response = curl_exec($curl);
$responseData = json_decode($response, true);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
print_r($responseData);

// Test 2: Try to add an existing user (should work if not already in MC)
echo "\n🧪 Test 2: Adding existing user...\n";

// Let's try to add member2@divinelife.com to MC 3 (they're currently in MC 4)
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/mcs/3/members",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode(['email' => 'member2@divinelife.com']),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json',
        "Authorization: Bearer $token"
    ]
]);

$response = curl_exec($curl);
$responseData = json_decode($response, true);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
print_r($responseData);

// Test 3: Try to add newmember@divinelife.com (they exist but not in any MC)
echo "\n🧪 Test 3: Adding user without MC...\n";

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/mcs/3/members",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode(['email' => 'newmember@divinelife.com']),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json',
        "Authorization: Bearer $token"
    ]
]);

$response = curl_exec($curl);
$responseData = json_decode($response, true);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
print_r($responseData);

curl_close($curl);

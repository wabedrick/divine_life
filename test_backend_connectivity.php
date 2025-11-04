<?php

// Test if Laravel backend is accessible

$baseUrl = 'http://192.168.42.32:8000/api';

echo "🔍 Testing Laravel backend connectivity...\n\n";

// Test the basic test endpoint first
$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/test",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Accept: application/json']
]);

$response = curl_exec($curl);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "Test endpoint response:\n";
echo "HTTP Code: $httpCode\n";
echo "Response: $response\n\n";

curl_close($curl);

if ($httpCode !== 200) {
    echo "❌ Backend is not accessible or not running\n";
    exit(1);
}

// Try to create a new user and login
echo "👤 Creating test user for birthday testing...\n";

$testUser = [
    'name' => 'Birthday Test User',
    'email' => 'birthday.test@example.com',
    'password' => 'testpassword123',
    'password_confirmation' => 'testpassword123',
    'phone_number' => '+256700000099',
    'birth_date' => date('Y-m-d'), // Today's date for testing
    'gender' => 'male',
    'branch_id' => 1
];

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/auth/register",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($testUser),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json'
    ]
]);

$response = curl_exec($curl);
$registerData = json_decode($response, true);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "Registration response:\n";
echo "HTTP Code: $httpCode\n";
print_r($registerData);

curl_close($curl);

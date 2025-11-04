<?php

// Test birthday notifications API

$baseUrl = 'http://192.168.42.32:8000/api';

// Try to login with different credentials to test the API
$loginCredentials = [
    ['email' => 'mcleader1@divinelife.com', 'password' => 'password'],
    ['email' => 'admin@divinelifechurch.org', 'password' => 'password'],
    ['email' => 'john@divinelifechurch.org', 'password' => 'password'], // branch admin
];

$token = null;
$userInfo = null;

foreach ($loginCredentials as $credentials) {
    echo "🔑 Trying login: {$credentials['email']}\n";

    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL => "$baseUrl/auth/login",
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($credentials),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json'
        ]
    ]);

    $response = curl_exec($curl);
    $data = json_decode($response, true);

    if (isset($data['access_token'])) {
        echo "✅ Login successful!\n";
        $token = $data['access_token'];
        $userInfo = $data['user'];
        echo "User: {$userInfo['name']} ({$userInfo['role']})\n\n";
        break;
    } else {
        echo "❌ Login failed\n";
    }

    curl_close($curl);
}

if (!$token) {
    echo "❌ All login attempts failed\n";
    exit(1);
}

// Test birthday notifications endpoint
echo "🎂 Testing birthday notifications API...\n";

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/birthdays/notifications",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Accept: application/json',
        "Authorization: Bearer $token"
    ]
]);

$response = curl_exec($curl);
$birthdayData = json_decode($response, true);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
print_r($birthdayData);

// Test upcoming birthdays endpoint
echo "\n📅 Testing upcoming birthdays API...\n";

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/birthdays/upcoming",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Accept: application/json',
        "Authorization: Bearer $token"
    ]
]);

$response = curl_exec($curl);
$upcomingData = json_decode($response, true);
$httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
print_r($upcomingData);

curl_close($curl);

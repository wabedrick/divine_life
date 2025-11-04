<?php

// Test with Super Admin credentials

$baseUrl = 'http://192.168.42.32:8000/api';

// Try different login credentials
$loginCredentials = [
    ['email' => 'admin@divinelife.com', 'password' => 'password'],
    ['email' => 'admin@divinelife.com', 'password' => 'password123'],
    ['email' => 'admin@divinelife.com', 'password' => 'admin123'],
    ['email' => 'mcleader1@divinelife.com', 'password' => 'password'],
];

$token = null;

foreach ($loginCredentials as $credentials) {
    echo "🔑 Trying login: {$credentials['email']} / {$credentials['password']}\n";

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
        echo "User: {$data['user']['name']} ({$data['user']['role']})\n\n";
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

// Test the improved error message for non-existent email
echo "🧪 Testing improved error message for non-existent email...\n";

$curl = curl_init();
curl_setopt_array($curl, [
    CURLOPT_URL => "$baseUrl/mcs/3/members",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode(['email' => 'wabwiireedrick@gmail.com']),
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

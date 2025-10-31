<?php

// Quick test to find working login credentials
$baseUrl = 'http://127.0.0.1:8000';

// List of potential login credentials to test
$credentials = [
    ['email' => 'admin@test.com', 'password' => 'password'],
    ['email' => 'admin@divinelifechurch.org', 'password' => 'password'],
    ['email' => 'admin@divinelifechurch.com', 'password' => 'password123'],
    ['email' => 'branch@test.com', 'password' => 'password'],
    ['email' => 'leader@test.com', 'password' => 'password'],
];

foreach ($credentials as $loginData) {
    echo "Testing login: " . $loginData['email'] . " / " . $loginData['password'] . "\n";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $responseData = json_decode($response, true);

    echo "HTTP Code: $httpCode\n";
    
    if ($httpCode === 200 && isset($responseData['token'])) {
        echo "✅ SUCCESS! Login credentials work.\n";
        echo "Token: " . substr($responseData['token'], 0, 20) . "...\n";
        $workingCredentials = $loginData;
        break;
    } else {
        echo "❌ Failed: " . $response . "\n";
    }
    
    echo "---\n";
    curl_close($ch);
}

if (!isset($workingCredentials)) {
    echo "No working credentials found!\n";
    exit(1);
}

// Now test conversation creation with the working credentials
echo "\n=== Testing Conversation Creation ===\n";

$token = $responseData['token'];

// Test creating a simple group conversation
$conversationData = [
    'name' => 'Test Group Chat',
    'description' => 'Testing group conversation creation',
    'type' => 'group',
    'participant_ids' => [1, 2]  // Using basic user IDs
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/chat/conversations');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($conversationData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
    'Authorization: Bearer ' . $token
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Code: $httpCode\n";
echo "Response: $response\n";

curl_close($ch);
?>
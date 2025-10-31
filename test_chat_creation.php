<?php

// Test chat creation with different conversation types

$baseUrl = 'http://127.0.0.1:8000';

// First, login to get a token
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$loginResponse = curl_exec($ch);
$loginData = json_decode($loginResponse, true);

if (!isset($loginData['access_token'])) {
    echo "Login failed:\n";
    echo $loginResponse . "\n";
    exit(1);
}

$token = $loginData['access_token'];
echo "Login successful. Token: " . substr($token, 0, 20) . "...\n\n";

// Test creating conversations of different types
$conversationTypes = [
    [
        'name' => 'Test Individual Chat',
        'description' => 'Testing individual conversation creation',
        'type' => 'individual',
        'participant_ids' => [1, 2]
    ],
    [
        'name' => 'Test Group Chat',
        'description' => 'Testing group conversation creation',
        'type' => 'group',
        'participant_ids' => [1, 2, 3]
    ],
    [
        'name' => 'Test MC Chat',
        'description' => 'Testing MC conversation creation',
        'type' => 'mc',
        'participant_ids' => [1, 2],
        'mc_id' => 1
    ],
    [
        'name' => 'Test Branch Chat',
        'description' => 'Testing branch conversation creation',
        'type' => 'branch',
        'participant_ids' => [1, 2],
        'branch_id' => 1
    ],
    [
        'name' => 'Test Announcement Chat',
        'description' => 'Testing announcement conversation creation',
        'type' => 'announcement',
        'participant_ids' => [1, 2]
    ]
];

foreach ($conversationTypes as $index => $conversationData) {
    echo "Testing conversation type: " . $conversationData['type'] . "\n";
    
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/chat/conversations');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($conversationData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $responseData = json_decode($response, true);
    
    echo "HTTP Code: $httpCode\n";
    
    if ($httpCode === 200 || $httpCode === 201) {
        echo "✅ SUCCESS: Conversation created successfully\n";
        echo "Conversation ID: " . ($responseData['data']['id'] ?? 'N/A') . "\n";
    } else {
        echo "❌ FAILED: Conversation creation failed\n";
        echo "Response: $response\n";
    }
    
    echo "---\n\n";
}

curl_close($ch);
?>
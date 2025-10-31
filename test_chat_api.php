<?php

// Test chat API endpoints
$baseUrl = 'http://localhost:8000/api';

// Test 1: Check if server is accessible
echo "Testing server accessibility...\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
echo "Server response code: $httpCode\n";
echo "Response: $response\n\n";

// Test 2: Try to login with sample user
echo "Testing login...\n";
$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "$baseUrl/auth/login");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Login response code: $httpCode\n";
echo "Login response: $response\n";

$loginResponse = json_decode($response, true);
if (isset($loginResponse['access_token'])) {
    $token = $loginResponse['access_token'];
    echo "\nLogin successful! Token: " . substr($token, 0, 20) . "...\n\n";
    
    // Test 3: Get conversations
    echo "Testing get conversations...\n";
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "$baseUrl/chat/conversations");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $token",
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "Conversations response code: $httpCode\n";
    echo "Conversations response: $response\n\n";
    
    // Test 4: Get or create Branch category conversation
    echo "Testing get/create Branch category conversation...\n";
    $categoryData = [
        'type' => 'branch',
        'category_id' => 1  // Using branch_id from logged in user
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "$baseUrl/chat/conversations/category");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($categoryData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $token",
        'Content-Type: application/json',
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "Category conversation response code: $httpCode\n";
    echo "Category conversation response: $response\n\n";
    
    $categoryResponse = json_decode($response, true);
    if (isset($categoryResponse['data']['id'])) {
        $conversationId = $categoryResponse['data']['id'];
        echo "Branch conversation ID: $conversationId\n\n";
        
        // Test 5: Send a message to the Branch conversation
        echo "Testing send message to Branch conversation...\n";
        $messageData = [
            'conversation_id' => $conversationId,
            'content' => 'Hello from API test! This is a test message for the Branch category.'
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "$baseUrl/chat/messages");
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($messageData));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Authorization: Bearer $token",
            'Content-Type: application/json',
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Send message response code: $httpCode\n";
        echo "Send message response: $response\n\n";
        
        // Test 6: Get messages from the conversation
        echo "Testing get messages from Branch conversation...\n";
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, "$baseUrl/chat/conversations/$conversationId/messages");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "Authorization: Bearer $token",
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 10);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Get messages response code: $httpCode\n";
        echo "Get messages response: $response\n";
        
    } else {
        echo "Failed to create/get Branch conversation.\n";
    }
    
} else {
    echo "Login failed. Cannot test authenticated endpoints.\n";
}

echo "\nAPI test completed.\n";
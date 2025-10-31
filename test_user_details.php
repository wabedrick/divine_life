<?php

// Test script to check user details API
$baseUrl = 'http://192.168.42.102:8000/api';

// First, login to get a token
$loginData = [
    'email' => 'admin@test.com',
    'password' => 'password'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/auth/login');
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$loginResult = json_decode($response, true);

if (isset($loginResult['access_token'])) {
    $token = $loginResult['access_token'];
    echo "Login successful. Token: " . substr($token, 0, 20) . "...\n\n";
    
    // Get users list
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/users');
    curl_setopt($ch, CURLOPT_POST, 0);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);
    
    $response = curl_exec($ch);
    $usersResult = json_decode($response, true);
    
    echo "Users API Response:\n";
    echo json_encode($usersResult, JSON_PRETTY_PRINT) . "\n\n";
    
    // Get first user details if available
    if (isset($usersResult['users']) && count($usersResult['users']) > 0) {
        $firstUserId = $usersResult['users'][0]['id'];
        
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/users/' . $firstUserId);
        
        $response = curl_exec($ch);
        $userDetailsResult = json_decode($response, true);
        
        echo "Single User Details API Response (ID: $firstUserId):\n";
        echo json_encode($userDetailsResult, JSON_PRETTY_PRINT) . "\n";
    }
    
} else {
    echo "Login failed:\n";
    echo json_encode($loginResult, JSON_PRETTY_PRINT) . "\n";
}

curl_close($ch);
?>
<?php

// Check users with MC assignments to test MC chat access
$baseUrl = 'http://192.168.42.54:8000';

echo "=== FINDING USERS WITH MC ASSIGNMENTS ===\n\n";

// Login as admin to get user list
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

// Get all users
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$usersResponse = curl_exec($ch);
$users = json_decode($usersResponse, true);

echo "Users with MC assignments:\n";
$mcUsers = [];
foreach ($users['users'] as $user) {
    if ($user['mc_id'] && $user['role'] === 'member') {
        echo "- {$user['name']} ({$user['email']}) - MC ID: {$user['mc_id']}, Branch ID: {$user['branch_id']}\n";
        $mcUsers[] = $user;
    }
}

if (empty($mcUsers)) {
    echo "No member users with MC assignments found.\n";
    echo "Let's test MC leaders instead:\n";
    
    foreach ($users['users'] as $user) {
        if ($user['mc_id'] && $user['role'] === 'mc_leader') {
            echo "- {$user['name']} ({$user['email']}) - MC ID: {$user['mc_id']}, Role: {$user['role']}\n";
            $mcUsers[] = $user;
        }
    }
}

// Test MC access with one of these users
if (!empty($mcUsers)) {
    $testUser = $mcUsers[0];
    echo "\nTesting MC access with: {$testUser['name']}\n";
    
    // Try to login (we'll need to know their password)
    echo "Note: You may need to test this manually in the app since we don't know their password.\n";
    echo "User details for manual testing:\n";
    echo "Email: {$testUser['email']}\n";
    echo "MC ID: {$testUser['mc_id']}\n";
    echo "Branch ID: {$testUser['branch_id']}\n";
}

curl_close($ch);
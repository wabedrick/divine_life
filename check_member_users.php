<?php

// Check what users we have and their roles
$baseUrl = 'http://192.168.42.54:8000';

echo "=== CHECKING AVAILABLE USERS ===\n\n";

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

if (!isset($loginResult['access_token'])) {
    echo "❌ Admin login failed: $response\n";
    exit(1);
}

$token = $loginResult['access_token'];
echo "✅ Admin login successful\n";

// Get all users
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users');
curl_setopt($ch, CURLOPT_POST, false);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$usersResponse = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if ($httpCode === 200) {
    $users = json_decode($usersResponse, true);
    echo "Current users:\n";
    foreach ($users['data'] as $user) {
        echo "- {$user['name']} ({$user['email']}) - Role: {$user['role']}, Approved: " . 
             ($user['is_approved'] ? 'Yes' : 'No') . "\n";
    }
    
    // Find a member user to test with
    $memberUser = null;
    foreach ($users['data'] as $user) {
        if ($user['role'] === 'member' && $user['is_approved']) {
            $memberUser = $user;
            break;
        }
    }
    
    if ($memberUser) {
        echo "\n✅ Found approved member user: {$memberUser['name']} ({$memberUser['email']})\n";
        echo "You can test the login with this user.\n";
        echo "Note: The password might be 'password123' or what was set during registration.\n";
    } else {
        echo "\n⚠️ No approved member users found. You may need to:\n";
        echo "1. Register a new user through the app\n";
        echo "2. Approve them through the admin panel\n";
        echo "3. Then test the login\n";
    }
} else {
    echo "❌ Failed to fetch users: HTTP $httpCode\n";
    echo $usersResponse . "\n";
}

curl_close($ch);
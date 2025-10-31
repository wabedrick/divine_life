<?php

// Test member login and dashboard access
$baseUrl = 'http://192.168.42.54:8000';

echo "=== TESTING MEMBER LOGIN AND DASHBOARD ACCESS ===\n\n";

// Try to login as the member user
$loginData = [
    'email' => 'musa@gmail.com',
    'password' => 'password123'  // Let's try the default password
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
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "Login attempt - HTTP Status: $httpCode\n";
echo "Response: $response\n\n";

if ($httpCode === 200) {
    $loginResult = json_decode($response, true);
    
    if (isset($loginResult['access_token'])) {
        $token = $loginResult['access_token'];
        echo "✅ Member login successful!\n";
        echo "User: " . $loginResult['user']['name'] . " (Role: " . $loginResult['user']['role'] . ")\n\n";
        
        // Now test the member dashboard endpoint
        echo "Testing member dashboard access...\n";
        
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users/dashboard');
        curl_setopt($ch, CURLOPT_POST, false);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $token,
            'Accept: application/json'
        ]);

        $dashboardResponse = curl_exec($ch);
        $dashboardHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        echo "Dashboard access - HTTP Status: $dashboardHttpCode\n";
        echo "Dashboard Response: $dashboardResponse\n\n";

        if ($dashboardHttpCode === 200) {
            echo "✅ SUCCESS! Member can access their dashboard!\n";
            $dashboardData = json_decode($dashboardResponse, true);
            echo "Dashboard data:\n";
            print_r($dashboardData);
        } else {
            echo "❌ Dashboard access failed with status $dashboardHttpCode\n";
        }
        
        // Also test if they can access the old statistics endpoint (should fail)
        echo "\nTesting access to admin statistics endpoint (should fail)...\n";
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/users/statistics');
        $statsResponse = curl_exec($ch);
        $statsHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        
        echo "Statistics endpoint - HTTP Status: $statsHttpCode\n";
        if ($statsHttpCode !== 200) {
            echo "✅ Good! Member correctly denied access to admin statistics\n";
        } else {
            echo "⚠️ Member has access to admin statistics (unexpected)\n";
        }
        
    } else {
        echo "❌ Login response missing access token\n";
    }
} else {
    echo "❌ Member login failed with status $httpCode\n";
    if ($httpCode === 401) {
        echo "This likely means the password is incorrect. You may need to:\n";
        echo "1. Check what password was used during registration\n";
        echo "2. Or reset the user's password in the database\n";
    }
}

curl_close($ch);
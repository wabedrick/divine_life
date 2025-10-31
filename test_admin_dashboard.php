<?php
// Admin Dashboard API Test with Authentication
$baseUrl = 'http://127.0.0.1:8000/api';

echo "=== DIVINE LIFE ADMIN DASHBOARD API TESTING ===\n\n";

// Step 1: Login and get authentication token
echo "1. Testing Authentication:\n";
$loginData = [
    'email' => 'admin@divinelifechurch.org', // Using the super admin from seeder
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$loginResponse = curl_exec($ch);
$loginHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($loginHttpCode != 200) {
    echo "   ❌ FAILED - Login failed with HTTP code: $loginHttpCode\n";
    echo "   Response: " . substr($loginResponse, 0, 500) . "\n";
    exit(1);
}

$loginData = json_decode($loginResponse, true);
if (!$loginData || !isset($loginData['access_token'])) {
    echo "   ❌ FAILED - No access token in login response\n";
    echo "   Response: " . substr($loginResponse, 0, 500) . "\n";
    exit(1);
}

$token = $loginData['access_token'];
echo "   ✅ SUCCESS - Authentication token obtained\n";
echo "   User: " . ($loginData['user']['name'] ?? 'Unknown') . "\n";
echo "   Role: " . ($loginData['user']['role'] ?? 'Unknown') . "\n\n";

// Step 2: Test all admin dashboard endpoints with authentication
$endpoints = [
    '/users' => 'Users Management',
    '/branches' => 'Branch Management', 
    '/mcs' => 'MC Management',
    '/events' => 'Events Management',
    '/announcements' => 'Announcements Management',
    '/reports' => 'Reports Management',
    '/chat/conversations' => 'Chat System'
];

echo "2. Testing Admin Dashboard Endpoints:\n";
foreach ($endpoints as $endpoint => $name) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $baseUrl . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode == 200) {
        $data = json_decode($response, true);
        if ($data) {
            echo "   ✅ $name - SUCCESS\n";
            
            // Show data count if available
            if (strpos($endpoint, '/users') !== false && isset($data['users'])) {
                echo "      └─ " . count($data['users']) . " users found\n";
            }
            if (strpos($endpoint, '/branches') !== false && isset($data['branches'])) {
                echo "      └─ " . count($data['branches']) . " branches found\n";
            }
            if (strpos($endpoint, '/mcs') !== false && isset($data['mcs'])) {
                echo "      └─ " . count($data['mcs']) . " MCs found\n";
            }
            if (strpos($endpoint, '/events') !== false && isset($data['events'])) {
                echo "      └─ " . count($data['events']) . " events found\n";
            }
            if (strpos($endpoint, '/announcements') !== false && isset($data['announcements'])) {
                echo "      └─ " . count($data['announcements']) . " announcements found\n";
            }
            if (strpos($endpoint, '/reports') !== false && isset($data['reports'])) {
                echo "      └─ " . count($data['reports']) . " reports found\n";
            }
            if (strpos($endpoint, '/conversations') !== false && isset($data['conversations'])) {
                echo "      └─ " . count($data['conversations']) . " conversations found\n";
            }
        } else {
            echo "   ⚠️ $name - Connected but invalid JSON response\n";
        }
    } elseif ($httpCode == 401) {
        echo "   ❌ $name - UNAUTHORIZED (HTTP 401)\n";
    } elseif ($httpCode == 403) {
        echo "   ❌ $name - FORBIDDEN (HTTP 403)\n";
    } elseif ($httpCode == 404) {
        echo "   ❌ $name - NOT FOUND (HTTP 404)\n";
    } else {
        echo "   ❌ $name - HTTP ERROR $httpCode\n";
    }
}

// Step 3: Test specific admin operations
echo "\n3. Testing Admin Operations:\n";

// Test user creation
echo "   Testing user creation...\n";
$newUser = [
    'name' => 'Test User',
    'email' => 'test' . time() . '@example.com',
    'password' => 'password123',
    'password_confirmation' => 'password123',
    'role' => 'member',
    'phone' => '+256700000999',
    'birth_date' => '1990-01-01',
    'branch_id' => 1
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/users');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($newUser));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode == 201) {
    echo "   ✅ User creation - SUCCESS\n";
} else {
    echo "   ❌ User creation - FAILED (HTTP $httpCode)\n";
}

echo "\n=== ADMIN DASHBOARD TESTING COMPLETE ===\n";
echo "🎯 If all endpoints show ✅ SUCCESS, your admin dashboard is ready!\n";
?>
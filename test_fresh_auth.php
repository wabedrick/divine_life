<?php
// Test fresh authentication and sermons loading
$baseUrl = 'http://192.168.42.54:8000/api';

// First, let's get a fresh token
function getAuthToken($baseUrl) {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $baseUrl . '/auth/login',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode([
            'email' => 'admin@divinelifechurch.org',
            'password' => 'password123'
        ]),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json'
        ]
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        $data = json_decode($response, true);
        return $data['token'] ?? null;
    } else {
        echo "Login failed with HTTP code: $httpCode\n";
        echo "Response: $response\n";
    }
    
    return null;
}

function testEndpoint($url, $token) {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json',
            'Authorization: Bearer ' . $token
        ]
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return ['code' => $httpCode, 'response' => $response];
}

echo "Getting fresh authentication token...\n";
$token = getAuthToken($baseUrl);

if (!$token) {
    echo "❌ Failed to get authentication token\n";
    exit(1);
}

echo "✅ Got fresh token: " . substr($token, 0, 20) . "...\n\n";

echo "Testing sermons with fresh token...\n";

// Test the exact endpoints Flutter is calling
$endpoints = [
    '/sermons?page=1&per_page=10' => 'Main sermons',
    '/sermons/featured?limit=5' => 'Featured sermons',
    '/sermons/categories' => 'Categories'
];

foreach ($endpoints as $endpoint => $name) {
    echo "Testing $name: $endpoint\n";
    $result = testEndpoint($baseUrl . $endpoint, $token);
    
    if ($result['code'] === 200) {
        echo "✅ SUCCESS\n";
        $data = json_decode($result['response'], true);
        
        if ($endpoint === '/sermons?page=1&per_page=10') {
            echo "  - Sermons count: " . count($data['data']) . "\n";
            echo "  - Current page: " . $data['current_page'] . "\n";
            echo "  - Last page: " . $data['last_page'] . "\n";
        } elseif ($endpoint === '/sermons/featured?limit=5') {
            echo "  - Featured count: " . (is_array($data) ? count($data) : 'invalid response') . "\n";
        } elseif ($endpoint === '/sermons/categories') {
            echo "  - Categories count: " . (is_array($data) ? count($data) : 'invalid response') . "\n";
        }
    } else {
        echo "❌ ERROR (HTTP " . $result['code'] . ")\n";
        echo "  Response: " . $result['response'] . "\n";
    }
    echo "\n";
}
?>
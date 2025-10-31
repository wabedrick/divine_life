<?php
// Test sermons API with authentication
$baseUrl = 'http://192.168.42.54:8000/api';

// First get auth token
echo "Getting authentication token...\n";

$loginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $baseUrl . '/auth/login',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($loginData),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json'
    ]
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode !== 200) {
    echo "❌ Authentication failed: HTTP $httpCode\n";
    echo "Response: $response\n";
    exit(1);
}

$authData = json_decode($response, true);
$token = $authData['access_token'];

echo "✅ Authentication successful\n";
echo "User: " . $authData['user']['name'] . " (" . $authData['user']['role'] . ")\n\n";

// Now test sermons endpoints
$endpoints = [
    '/sermons' => 'All sermons',
    '/sermons?page=1&per_page=10' => 'Paginated sermons (page 1)',
    '/sermons/featured' => 'Featured sermons',
    '/sermons/categories' => 'Categories'
];

foreach ($endpoints as $endpoint => $description) {
    echo "Testing: $description ($endpoint)\n";
    
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $baseUrl . $endpoint,
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

    echo "  HTTP Code: $httpCode\n";
    
    if ($httpCode === 200) {
        $data = json_decode($response, true);
        
        if ($endpoint === '/sermons' || strpos($endpoint, 'page=1') !== false) {
            if (isset($data['data'])) {
                echo "  ✅ SUCCESS - Found " . count($data['data']) . " sermons\n";
                
                if (count($data['data']) > 0) {
                    $firstSermon = $data['data'][0];
                    echo "  First sermon:\n";
                    echo "    - ID: " . $firstSermon['id'] . "\n";
                    echo "    - Title: " . $firstSermon['title'] . "\n";
                    echo "    - YouTube URL: " . $firstSermon['youtube_url'] . "\n";
                    echo "    - Speaker: " . $firstSermon['speaker'] . "\n";
                    echo "    - Category: " . $firstSermon['category'] . "\n";
                    echo "    - Is Active: " . ($firstSermon['is_active'] ? 'Yes' : 'No') . "\n";
                }
                
                echo "  Pagination:\n";
                echo "    - Current page: " . $data['current_page'] . "\n";
                echo "    - Total pages: " . $data['last_page'] . "\n";
                echo "    - Total sermons: " . $data['total'] . "\n";
            } else {
                echo "  ❌ No 'data' key in response\n";
                echo "  Response keys: " . implode(', ', array_keys($data)) . "\n";
            }
        } elseif ($endpoint === '/sermons/featured') {
            if (is_array($data)) {
                echo "  ✅ SUCCESS - Found " . count($data) . " featured sermons\n";
            } else {
                echo "  ❌ Invalid response format\n";
            }
        } elseif ($endpoint === '/sermons/categories') {
            echo "  ✅ SUCCESS - Found " . count($data) . " categories\n";
            echo "  Categories: " . implode(', ', array_keys($data)) . "\n";
        }
    } else {
        echo "  ❌ FAILED\n";
        echo "  Response: " . substr($response, 0, 200) . "...\n";
    }
    
    echo "\n" . str_repeat("-", 60) . "\n\n";
}
?>
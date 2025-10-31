<?php
// Test sermons loading endpoints
$baseUrl = 'http://192.168.42.54:8000/api';

// Test token (replace with valid token)
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi41NDo4MDAwL2FwaS9hdXRoL2xvZ2luIiwiaWF0IjoxNzYxNjk2MTA4LCJleHAiOjE3NjE2OTk3MDgsIm5iZiI6MTc2MTY5NjEwOCwianRpIjoibVprZU1Gc1RSeU5RV0xDciIsInN1YiI6IjEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3Iiwicm9sZSI6InN1cGVyX2FkbWluIiwiYnJhbmNoX2lkIjoxLCJtY19pZCI6bnVsbH0.8xmRnr7foS_yET92efdoizk-KjKlgnNXB6lrs5CCbM4';

// Test endpoints that Flutter app is calling
$endpoints = [
    '/sermons?page=1&per_page=10',
    '/sermons/featured?limit=5',
    '/sermons/categories'
];

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

echo "Testing sermons loading endpoints...\n\n";

foreach ($endpoints as $endpoint) {
    echo "Testing: $endpoint\n";
    $result = testEndpoint($baseUrl . $endpoint, $token);
    
    echo "HTTP Code: " . $result['code'] . "\n";
    
    if ($result['code'] === 200) {
        echo "✅ SUCCESS\n";
        $data = json_decode($result['response'], true);
        if (isset($data['data'])) {
            echo "Data count: " . count($data['data']) . " items\n";
        } elseif (is_array($data)) {
            echo "Response count: " . count($data) . " items\n";
        }
    } else {
        echo "❌ ERROR\n";
        echo "Response: " . $result['response'] . "\n";
    }
    echo "\n" . str_repeat("-", 50) . "\n\n";
}
?>
<?php
// Test detailed sermons API response structure
$baseUrl = 'http://192.168.42.54:8000/api';

// Test token (replace with valid token)
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi41NDo4MDAwL2FwaS9hdXRoL2xvZ2luIiwiaWF0IjoxNzYxNjk2MTA4LCJleHAiOjE3NjE2OTk3MDgsIm5iZiI6MTc2MTY5NjEwOCwianRpIjoibVprZU1Gc1RSeU5RV0xDciIsInN1YiI6IjEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3Iiwicm9sZSI6InN1cGVyX2FkbWluIiwiYnJhbmNoX2lkIjoxLCJtY19pZCI6bnVsbH0.8xmRnr7foS_yET92efdoizk-KjKlgnNXB6lrs5CCbM4';

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

echo "Testing sermons API structure...\n\n";

// Test main sermons endpoint
$result = testEndpoint($baseUrl . '/sermons?page=1&per_page=10', $token);

echo "HTTP Code: " . $result['code'] . "\n";

if ($result['code'] === 200) {
    $data = json_decode($result['response'], true);
    echo "✅ SUCCESS\n\n";
    
    echo "Response structure:\n";
    echo "Keys: " . implode(', ', array_keys($data)) . "\n\n";
    
    if (isset($data['data'])) {
        echo "Data section exists with " . count($data['data']) . " sermons\n";
        if (count($data['data']) > 0) {
            echo "First sermon keys: " . implode(', ', array_keys($data['data'][0])) . "\n";
        }
    }
    
    if (isset($data['current_page'])) {
        echo "\nPagination info:\n";
        echo "- Current page: " . $data['current_page'] . "\n";
        echo "- Last page: " . (isset($data['last_page']) ? $data['last_page'] : 'not found') . "\n";
        echo "- Total: " . (isset($data['total']) ? $data['total'] : 'not found') . "\n";
    }
    
    echo "\nFull response (first 500 chars):\n";
    echo substr($result['response'], 0, 500) . "...\n";
} else {
    echo "❌ ERROR\n";
    echo "Response: " . $result['response'] . "\n";
}
?>
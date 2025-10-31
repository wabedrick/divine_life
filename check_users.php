<?php
// Check users in database
$baseUrl = 'http://192.168.42.54:8000/api';

// Test a simple endpoint first
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $baseUrl . '/test',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json'
    ]
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "API Test endpoint:\n";
echo "HTTP Code: $httpCode\n";
echo "Response: $response\n\n";

if ($httpCode !== 200) {
    echo "❌ Backend is not responding properly\n";
    exit(1);
}

// Now test login with different credentials
$credentials = [
    ['email' => 'admin@divinelifechurch.org', 'password' => 'password123'],
    ['email' => 'admin@test.com', 'password' => 'password'],
    ['email' => 'admin@divinelifechurch.org', 'password' => 'admin123']
];

foreach ($credentials as $i => $creds) {
    echo "Testing login " . ($i + 1) . ": {$creds['email']} / {$creds['password']}\n";
    
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $baseUrl . '/auth/login',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($creds),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json'
        ]
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    echo "  HTTP Code: $httpCode\n";
    
    if ($httpCode === 200) {
        echo "  ✅ SUCCESS!\n";
        $data = json_decode($response, true);
        if (isset($data['token'])) {
            echo "  Token: " . substr($data['token'], 0, 20) . "...\n";
        }
    } else {
        echo "  ❌ FAILED\n";
        echo "  Response: $response\n";
    }
    echo "\n";
}
?>
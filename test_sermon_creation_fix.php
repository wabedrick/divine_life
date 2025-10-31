<?php
// Test sermon creation API endpoint after fixes

$baseUrl = 'http://192.168.42.54:8000/api';

// Test token (replace with valid token)
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi41NDo4MDAwL2FwaS9hdXRoL2xvZ2luIiwiaWF0IjoxNzYxNjk2MTA4LCJleHAiOjE3NjE2OTk3MDgsIm5iZiI6MTc2MTY5NjEwOCwianRpIjoibVprZU1Gc1RSeU5RV0xDciIsInN1YiI6IjEiLCJwcnYiOiIyM2JkNWM4OTQ5ZjYwMGFkYjM5ZTcwMWM0MDA4NzJkYjdhNTk3NmY3Iiwicm9sZSI6InN1cGVyX2FkbWluIiwiYnJhbmNoX2lkIjoxLCJtY19pZCI6bnVsbH0.8xmRnr7foS_yET92efdoizk-KjKlgnNXB6lrs5CCbM4';

// Test sermon data
$sermonData = [
    'title' => 'Test Sermon - Admin Creation',
    'description' => 'Testing sermon creation after fixing regex validation and adding created_by column',
    'youtube_url' => 'https://youtu.be/t13lEQ78eYs?si=71QNAlh4w7NK8ALn',
    'speaker' => 'Pr. Test Speaker',
    'duration' => 0,
    'category' => 'sunday_service',
    'is_featured' => false
];

// Initialize cURL
$ch = curl_init();

curl_setopt_array($ch, [
    CURLOPT_URL => $baseUrl . '/sermons',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($sermonData),
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]
]);

echo "Testing sermon creation...\n";
echo "Data: " . json_encode($sermonData, JSON_PRETTY_PRINT) . "\n\n";

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response: " . $response . "\n";

if ($httpCode === 201) {
    echo "\n✅ SUCCESS: Sermon created successfully!\n";
} else {
    echo "\n❌ ERROR: Failed to create sermon\n";
}
?>
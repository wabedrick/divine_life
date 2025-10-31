<?php
// Test user registration with detailed error reporting
$baseUrl = 'http://192.168.42.54:8000/api';

echo "=== TESTING USER REGISTRATION ===\n\n";

// Test registration data (no login needed for registration)
$userData = [
    'name' => 'Test User Registration',
    'email' => 'testuser' . time() . '@example.com', // Unique email
    'password' => 'password123',
    'password_confirmation' => 'password123',
    'phone_number' => '+256700000999',
    'birth_date' => '1990-01-15',
    'gender' => 'male',
    'branch_id' => 1, // Using HQ branch
];

echo "Registration Data:\n";
print_r($userData);
echo "\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/auth/register');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($userData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);

echo "HTTP Status: $httpCode\n";
if ($curlError) {
    echo "CURL Error: $curlError\n";
}
echo "Response: $response\n\n";

if ($httpCode === 201 || $httpCode === 200) {
    echo "✅ Registration successful!\n";
    $data = json_decode($response, true);
    if (isset($data['message'])) {
        echo "Message: " . $data['message'] . "\n";
    }
} else {
    echo "❌ Registration failed with status $httpCode\n";
    if ($response) {
        $data = json_decode($response, true);
        if (isset($data['error'])) {
            echo "Error: " . json_encode($data['error']) . "\n";
        }
    }
}

curl_close($ch);
?>
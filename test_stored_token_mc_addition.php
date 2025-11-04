<?php

// Test current API to understand user credentials

$baseUrl = 'http://192.168.42.32:8000/api';

// Check if we have any valid tokens stored
$storedTokenFile = 'login_data.json';
if (file_exists($storedTokenFile)) {
    $stored = json_decode(file_get_contents($storedTokenFile), true);
    if ($stored && isset($stored['access_token'])) {
        echo "📱 Found stored token, testing it...\n";

        // Test the stored token
        $curl = curl_init();
        curl_setopt_array($curl, [
            CURLOPT_URL => "$baseUrl/auth/me",
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Accept: application/json',
                "Authorization: Bearer {$stored['access_token']}"
            ]
        ]);

        $response = curl_exec($curl);
        $userData = json_decode($response, true);
        $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

        if ($httpCode === 200 && isset($userData['user'])) {
            echo "✅ Stored token is valid!\n";
            echo "User: {$userData['user']['name']} ({$userData['user']['email']}) - {$userData['user']['role']}\n\n";

            // Test the MC member addition with the improved error message
            echo "🧪 Testing improved error message for non-existent email...\n";

            $curl = curl_init();
            curl_setopt_array($curl, [
                CURLOPT_URL => "$baseUrl/mcs/{$userData['user']['mc_id']}/members",
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode(['email' => 'wabwiireedrick@gmail.com']),
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'Accept: application/json',
                    "Authorization: Bearer {$stored['access_token']}"
                ]
            ]);

            $response = curl_exec($curl);
            $responseData = json_decode($response, true);
            $httpCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);

            echo "HTTP Code: $httpCode\n";
            echo "Response:\n";
            print_r($responseData);

            exit(0);
        }

        curl_close($curl);
    }
}

echo "❌ No valid stored token found or token expired\n";
echo "Please login first using the Flutter app or run a fresh authentication test\n";

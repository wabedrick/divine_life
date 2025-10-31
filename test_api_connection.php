<?php
// Simple script to test API connection and basic functionality
$baseUrl = 'http://127.0.0.1:8000/api';

echo "Testing Laravel API Connection...\n";
echo "Base URL: $baseUrl\n\n";

// Test 1: Health check
echo "1. Testing API Health Check:\n";
$response = @file_get_contents($baseUrl . '/branches');
if ($response === false) {
    echo "   ❌ FAILED - Could not connect to API\n";
    echo "   Make sure Laravel server is running on http://127.0.0.1:8000\n\n";
    exit(1);
} else {
    echo "   ✅ SUCCESS - API is responding\n\n";
}

// Test 2: Parse JSON response
echo "2. Testing JSON Response:\n";
$data = json_decode($response, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    echo "   ❌ FAILED - Invalid JSON response\n";
    echo "   Response: " . substr($response, 0, 200) . "...\n\n";
} else {
    echo "   ✅ SUCCESS - Valid JSON response\n";
    if (isset($data['success']) && $data['success'] === true) {
        echo "   ✅ SUCCESS - API returned success response\n";
        if (isset($data['branches'])) {
            echo "   ✅ SUCCESS - Branches data found (" . count($data['branches']) . " branches)\n";
        }
    }
    echo "\n";
}

// Test 3: Check key API endpoints
$endpoints = [
    '/branches' => 'Branches',
    '/users' => 'Users', 
    '/mcs' => 'Missional Communities',
    '/events' => 'Events',
    '/announcements' => 'Announcements',
    '/reports' => 'Reports'
];

echo "3. Testing Key API Endpoints:\n";
foreach ($endpoints as $endpoint => $name) {
    $response = @file_get_contents($baseUrl . $endpoint);
    if ($response === false) {
        echo "   ❌ $name ($endpoint) - FAILED\n";
    } else {
        $data = json_decode($response, true);
        if (json_last_error() === JSON_ERROR_NONE && isset($data['success'])) {
            echo "   ✅ $name ($endpoint) - SUCCESS\n";
        } else {
            echo "   ⚠️ $name ($endpoint) - Connected but unexpected response\n";
        }
    }
}

echo "\n4. Admin Dashboard Testing Complete!\n";
echo "If all endpoints show ✅ SUCCESS, your admin dashboard should work properly.\n";
?>
<?php

function getFreshToken()
{
    $loginData = [
        'email' => 'admin@divinelifechurch.org',
        'password' => 'password123'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/auth/login');
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode == 200) {
        $data = json_decode($response, true);
        if (isset($data['access_token'])) {
            return $data['access_token'];
        }
    }

    echo "Login failed (HTTP $httpCode): $response\n";
    return null;
}

$token = getFreshToken();
if (!$token) {
    die("Failed to get authentication token\n");
}

$baseUrl = 'http://localhost:8000/api';

echo "Testing Social Media API Endpoints\n";
echo "==================================\n\n";

// Test 1: Get platforms
echo "1. Testing /social-media/platforms\n";
$platformsUrl = $baseUrl . '/social-media/platforms';
$platformsResponse = makeApiRequest($platformsUrl, $token);
echo "Response: " . json_encode($platformsResponse, JSON_PRETTY_PRINT) . "\n\n";

// Test 2: Get all posts
echo "2. Testing /social-media (all posts)\n";
$postsUrl = $baseUrl . '/social-media?page=1&per_page=5';
$postsResponse = makeApiRequest($postsUrl, $token);
echo "Response: " . json_encode($postsResponse, JSON_PRETTY_PRINT) . "\n\n";

// Test 3: Get featured posts
echo "3. Testing /social-media/featured\n";
$featuredUrl = $baseUrl . '/social-media/featured?limit=3';
$featuredResponse = makeApiRequest($featuredUrl, $token);
echo "Response: " . json_encode($featuredResponse, JSON_PRETTY_PRINT) . "\n\n";

// Test 4: Create a new social media post (if user has permissions)
echo "4. Testing POST /social-media (create new post)\n";
$createUrl = $baseUrl . '/social-media';
$newPostData = [
    'title' => 'Test Social Media Post',
    'description' => 'This is a test post from the API',
    'post_url' => 'https://www.instagram.com/p/test123/',
    'platform' => 'instagram',
    'media_type' => 'image',
    'hashtags' => 'test,church,divinelife'
];

$createResponse = makeApiRequest($createUrl, $token, 'POST', $newPostData);
echo "Response: " . json_encode($createResponse, JSON_PRETTY_PRINT) . "\n\n";

function makeApiRequest($url, $token, $method = 'GET', $data = null)
{
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token,
        'Content-Type: application/json',
        'Accept: application/json'
    ]);

    if ($method === 'POST' && $data) {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $decodedResponse = json_decode($response, true);

    return [
        'http_code' => $httpCode,
        'data' => $decodedResponse,
        'raw_response' => $response
    ];
}

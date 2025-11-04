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

echo "Testing Edit/Delete Functionality\n";
echo "=================================\n\n";

// Test 1: Get first sermon to edit
echo "1. Getting first sermon for testing...\n";
$sermonsUrl = $baseUrl . '/sermons?page=1&per_page=1';
$sermonsResponse = makeApiRequest($sermonsUrl, $token);
if ($sermonsResponse['http_code'] == 200 && !empty($sermonsResponse['data']['data'])) {
    $sermon = $sermonsResponse['data']['data'][0];
    echo "Found sermon: " . $sermon['title'] . " (ID: " . $sermon['id'] . ")\n\n";

    // Test 2: Update sermon
    echo "2. Testing sermon update...\n";
    $updateUrl = $baseUrl . '/sermons/' . $sermon['id'];
    $updateData = [
        'title' => $sermon['title'] . ' [UPDATED]',
        'description' => 'Updated description via API test',
        'youtube_url' => $sermon['youtube_url'],
        'speaker' => $sermon['speaker'],
        'category' => $sermon['category'],
        'is_featured' => false
    ];

    $updateResponse = makeApiRequest($updateUrl, $token, 'PUT', $updateData);
    echo "Update Response: " . json_encode($updateResponse, JSON_PRETTY_PRINT) . "\n\n";
} else {
    echo "No sermons found for testing\n\n";
}

// Test 3: Get first social media post to edit
echo "3. Getting first social media post for testing...\n";
$postsUrl = $baseUrl . '/social-media?page=1&per_page=1';
$postsResponse = makeApiRequest($postsUrl, $token);
if ($postsResponse['http_code'] == 200 && !empty($postsResponse['data']['data'])) {
    $post = $postsResponse['data']['data'][0];
    echo "Found post: " . $post['title'] . " (ID: " . $post['id'] . ")\n\n";

    // Test 4: Update social media post
    echo "4. Testing social media post update...\n";
    $updateUrl = $baseUrl . '/social-media/' . $post['id'];
    $updateData = [
        'title' => $post['title'] . ' [UPDATED]',
        'description' => 'Updated description via API test',
        'post_url' => $post['post_url'],
        'platform' => $post['platform'],
        'media_type' => $post['media_type'],
        'hashtags' => is_array($post['hashtags'])
            ? array_merge($post['hashtags'], ['updated'])
            : explode(',', $post['hashtags'] . ',updated'),
        'is_featured' => !$post['is_featured']
    ];

    $updateResponse = makeApiRequest($updateUrl, $token, 'PUT', $updateData);
    echo "Update Response: " . json_encode($updateResponse, JSON_PRETTY_PRINT) . "\n\n";
} else {
    echo "No social media posts found for testing\n\n";
}

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

    if ($method === 'PUT' && $data) {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    } elseif ($method === 'DELETE') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
    } elseif ($method === 'POST' && $data) {
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

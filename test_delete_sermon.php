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

echo "Testing Delete Functionality\n";
echo "============================\n\n";

// Test 1: Get a sermon to delete (we'll use the one we updated earlier)
echo "1. Getting sermons to find one to delete...\n";
$sermonsUrl = $baseUrl . '/sermons?per_page=5';
$sermonsResponse = makeApiRequest($sermonsUrl, $token);

if ($sermonsResponse['http_code'] == 200 && !empty($sermonsResponse['data']['data'])) {
    // Look for a sermon with [UPDATED] in the title (from our previous tests)
    $sermonToDelete = null;
    foreach ($sermonsResponse['data']['data'] as $sermon) {
        if (strpos($sermon['title'], '[UPDATED]') !== false) {
            $sermonToDelete = $sermon;
            break;
        }
    }

    if ($sermonToDelete) {
        echo "Found sermon to delete: " . $sermonToDelete['title'] . " (ID: " . $sermonToDelete['id'] . ")\n\n";

        // Test 2: Delete sermon
        echo "2. Testing sermon deletion...\n";
        $deleteUrl = $baseUrl . '/sermons/' . $sermonToDelete['id'];
        $deleteResponse = makeApiRequest($deleteUrl, $token, 'DELETE');
        echo "Delete Response: " . json_encode($deleteResponse, JSON_PRETTY_PRINT) . "\n\n";

        // Test 3: Verify sermon is soft deleted
        echo "3. Verifying sermon is soft deleted...\n";
        $checkUrl = $baseUrl . '/sermons/' . $sermonToDelete['id'];
        $checkResponse = makeApiRequest($checkUrl, $token);
        echo "Check Response: " . json_encode($checkResponse, JSON_PRETTY_PRINT) . "\n\n";
    } else {
        echo "No updated sermon found to delete. Creating a test sermon first...\n";

        $createUrl = $baseUrl . '/sermons';
        $testSermon = [
            'title' => 'Test Sermon for Deletion',
            'description' => 'This sermon will be deleted',
            'youtube_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'speaker' => 'Test Speaker',
            'category' => 'sunday_service',
            'is_featured' => false
        ];

        $createResponse = makeApiRequest($createUrl, $token, 'POST', $testSermon);
        echo "Create Response: " . json_encode($createResponse, JSON_PRETTY_PRINT) . "\n\n";

        if ($createResponse['http_code'] == 201) {
            $newSermonId = $createResponse['data']['id'];
            echo "Created test sermon with ID: $newSermonId\n";

            // Now delete it
            echo "Deleting the test sermon...\n";
            $deleteUrl = $baseUrl . '/sermons/' . $newSermonId;
            $deleteResponse = makeApiRequest($deleteUrl, $token, 'DELETE');
            echo "Delete Response: " . json_encode($deleteResponse, JSON_PRETTY_PRINT) . "\n\n";
        }
    }
} else {
    echo "Failed to get sermons: " . json_encode($sermonsResponse, JSON_PRETTY_PRINT) . "\n";
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

    if ($method === 'DELETE') {
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

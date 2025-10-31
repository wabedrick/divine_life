<?php

// Test the new public branches endpoint
$baseUrl = 'http://192.168.42.54:8000';
$publicBranchesUrl = $baseUrl . '/api/branches/public';

echo "=== TESTING PUBLIC BRANCHES ENDPOINT ===\n\n";

$ch = curl_init($publicBranchesUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

echo "HTTP Status: $httpCode\n";
echo "Response: $response\n\n";

if ($httpCode === 200) {
    $data = json_decode($response, true);
    echo "✅ Success! Got " . count($data['branches']) . " branches\n";
    foreach ($data['branches'] as $branch) {
        echo "- ID: {$branch['id']}, Name: {$branch['name']}, Location: {$branch['location']}\n";
    }
} else {
    echo "❌ Failed with status $httpCode\n";
}

curl_close($ch);
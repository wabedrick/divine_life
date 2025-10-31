<?php
// Simple cURL test for API
$url = 'http://127.0.0.1:8000/api/branches';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

echo "Testing: $url\n";

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
if ($error) {
    echo "cURL Error: $error\n";
} else {
    echo "Response length: " . strlen($response) . " bytes\n";
    if ($httpCode == 200) {
        echo "✅ SUCCESS - API is responding\n";
        $data = json_decode($response, true);
        if ($data && isset($data['success'])) {
            echo "✅ SUCCESS - Valid API response\n";
            if (isset($data['branches'])) {
                echo "✅ SUCCESS - Found " . count($data['branches']) . " branches\n";
            }
        }
    } else {
        echo "❌ FAILED - HTTP Error $httpCode\n";
        echo "Response: " . substr($response, 0, 500) . "\n";
    }
}
?>
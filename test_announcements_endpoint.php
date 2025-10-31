<?php

// Test Announcements endpoint structure
$baseUrl = 'http://192.168.42.203:8000/api';
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi4yMDM6ODAwMC9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTc2MTY1MTQ1OCwiZXhwIjoxNzYxNjU1MDU4LCJuYmYiOjE3NjE2NTE0NTgsImp0aSI6IndDSTFkQldqbzdrMnNwWFEiLCJzdWIiOiIxIiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyIsInJvbGUiOiJzdXBlcl9hZG1pbiIsImJyYW5jaF9pZCI6MSwibWNfaWQiOm51bGx9._qC-gSn-NciqhdGFqMfpC9g2Fp-WVLjrKFhY2oobTNM';

// Test Announcements endpoint
echo "Testing Announcements endpoint...\n";

$announcementsUrl = $baseUrl . '/announcements';

$context = stream_context_create([
    'http' => [
        'header' => [
            "Authorization: Bearer $token",
            "Content-Type: application/json",
            "Accept: application/json"
        ]
    ]
]);

$response = file_get_contents($announcementsUrl, false, $context);
if ($response === FALSE) {
    echo "Failed to fetch announcements\n";
    exit;
}

echo "Announcements Response Structure:\n";
$data = json_decode($response, true);
print_r($data);

// Check specific keys
echo "\nChecking keys:\n";
echo "Has 'data' key: " . (isset($data['data']) ? 'YES' : 'NO') . "\n";
echo "Has 'announcements' key: " . (isset($data['announcements']) ? 'YES' : 'NO') . "\n";
echo "Has 'news' key: " . (isset($data['news']) ? 'YES' : 'NO') . "\n";

if (isset($data['announcements'])) {
    echo "Announcements count: " . count($data['announcements']) . "\n";
} else if (isset($data['data'])) {
    echo "Data count: " . count($data['data']) . "\n";
}

?>
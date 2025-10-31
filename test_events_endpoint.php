<?php

// Test Events endpoint structure
$baseUrl = 'http://192.168.42.203:8000/api';
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi4yMDM6ODAwMC9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTc2MTY1MTQ1OCwiZXhwIjoxNzYxNjU1MDU4LCJuYmYiOjE3NjE2NTE0NTgsImp0aSI6IndDSTFkQldqbzdrMnNwWFEiLCJzdWIiOiIxIiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyIsInJvbGUiOiJzdXBlcl9hZG1pbiIsImJyYW5jaF9pZCI6MSwibWNfaWQiOm51bGx9._qC-gSn-NciqhdGFqMfpC9g2Fp-WVLjrKFhY2oobTNM';

// Test Events endpoint
echo "Testing Events endpoint...\n";

$eventsUrl = $baseUrl . '/events';

$context = stream_context_create([
    'http' => [
        'header' => [
            "Authorization: Bearer $token",
            "Content-Type: application/json",
            "Accept: application/json"
        ]
    ]
]);

$response = file_get_contents($eventsUrl, false, $context);
if ($response === FALSE) {
    echo "Failed to fetch events\n";
    exit;
}

echo "Events Response Structure:\n";
$data = json_decode($response, true);
print_r($data);

// Check specific keys
echo "\nChecking keys:\n";
echo "Has 'data' key: " . (isset($data['data']) ? 'YES' : 'NO') . "\n";
echo "Has 'events' key: " . (isset($data['events']) ? 'YES' : 'NO') . "\n";
echo "Has 'upcoming_events' key: " . (isset($data['upcoming_events']) ? 'YES' : 'NO') . "\n";

if (isset($data['events'])) {
    echo "Events count: " . count($data['events']) . "\n";
} else if (isset($data['data'])) {
    echo "Data count: " . count($data['data']) . "\n";
}

?>
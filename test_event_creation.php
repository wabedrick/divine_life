<?php

// Test Events CRUD endpoints
$baseUrl = 'http://192.168.42.203:8000/api';
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi4yMDM6ODAwMC9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTc2MTY1NTczMSwiZXhwIjoxNzYxNjU5MzMxLCJuYmYiOjE3NjE2NTU3MzEsImp0aSI6InNodWRMRnRlc0pRcEVPdUsiLCJzdWIiOiIxIiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyIsInJvbGUiOiJzdXBlcl9hZG1pbiIsImJyYW5jaF9pZCI6MSwibWNfaWQiOm51bGx9.YlFI8NTRYcHiOqlZDXlGeL0sAOaffFct2SEk6PKz9dw';

// Test event creation
echo "Testing Event Creation...\n";

$eventData = [
    'title' => 'Test Event Creation',
    'description' => 'This is a test event to verify creation works',
    'location' => 'Test Location',
    'event_date' => '2025-11-01T10:00:00.000Z',
    'end_date' => '2025-11-01T12:00:00.000Z',
    'visibility' => 'all',
    'branch_id' => null,
    'mc_id' => null,
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/events');
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($eventData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer $token",
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response: $response\n";

if ($httpCode == 201 || $httpCode == 200) {
    echo "✅ Event creation successful!\n";
    $data = json_decode($response, true);
    if (isset($data['event']['id'])) {
        echo "Created event ID: " . $data['event']['id'] . "\n";
    }
} else {
    echo "❌ Event creation failed!\n";
    $errorData = json_decode($response, true);
    if (isset($errorData['errors'])) {
        echo "Validation errors:\n";
        foreach ($errorData['errors'] as $field => $errors) {
            echo "  $field: " . implode(', ', $errors) . "\n";
        }
    }
}

?>
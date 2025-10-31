<?php

// Test Events CRUD operations
$baseUrl = 'http://192.168.42.203:8000/api';
$token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTkyLjE2OC40Mi4yMDM6ODAwMC9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTc2MTY1MTQ1OCwiZXhwIjoxNzYxNjU1MDU4LCJuYmYiOjE3NjE2NTE0NTgsImp0aSI6IndDSTFkQldqbzdrMnNwWFEiLCJzdWIiOiIxIiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyIsInJvbGUiOiJzdXBlcl9hZG1pbiIsImJyYW5jaF9pZCI6MSwibWNfaWQiOm51bGx9._qC-gSn-NciqhdGFqMfpC9g2Fp-WVLjrKFhY2oobTNM';

function makeRequest($url, $method = 'GET', $data = null, $token = null) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    
    $headers = [
        'Content-Type: application/json',
        'Accept: application/json'
    ];
    
    if ($token) {
        $headers[] = "Authorization: Bearer $token";
    }
    
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    if ($data && in_array($method, ['POST', 'PUT', 'PATCH'])) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return ['response' => $response, 'code' => $httpCode];
}

echo "Testing Events CRUD operations...\n\n";

// 1. Test getting existing events
echo "1. Getting existing events:\n";
$result = makeRequest($baseUrl . '/events', 'GET', null, $token);
echo "HTTP Code: " . $result['code'] . "\n";
$events = json_decode($result['response'], true);
if (isset($events['events']) && count($events['events']) > 0) {
    $existingEvent = $events['events'][0];
    echo "Found event: " . $existingEvent['title'] . " (ID: " . $existingEvent['id'] . ")\n\n";
} else {
    echo "No events found\n\n";
    $existingEvent = null;
}

// 2. Test creating a new event
echo "2. Creating a new event:\n";
$newEventData = [
    'title' => 'Test Event - Created by Script',
    'description' => 'This is a test event to verify CRUD operations',
    'location' => 'Test Location',
    'event_date' => '2025-11-01T10:00:00.000Z',
    'end_date' => '2025-11-01T12:00:00.000Z',
    'visibility' => 'all'
];

$result = makeRequest($baseUrl . '/events', 'POST', $newEventData, $token);
echo "HTTP Code: " . $result['code'] . "\n";
echo "Response: " . $result['response'] . "\n\n";

$createResponse = json_decode($result['response'], true);
$createdEventId = null;

if ($result['code'] == 201 || $result['code'] == 200) {
    if (isset($createResponse['event']['id'])) {
        $createdEventId = $createResponse['event']['id'];
        echo "✅ Event created with ID: $createdEventId\n\n";
    } else if (isset($createResponse['id'])) {
        $createdEventId = $createResponse['id'];
        echo "✅ Event created with ID: $createdEventId\n\n";
    }
} else {
    echo "❌ Failed to create event\n\n";
}

// 3. Test updating the created event (if it was created)
if ($createdEventId) {
    echo "3. Updating the created event (ID: $createdEventId):\n";
    $updateData = [
        'title' => 'Test Event - UPDATED by Script',
        'description' => 'This event has been updated via CRUD test',
        'location' => 'Updated Test Location',
        'event_date' => '2025-11-01T11:00:00.000Z',
        'end_date' => '2025-11-01T13:00:00.000Z',
        'visibility' => 'all'
    ];
    
    $result = makeRequest($baseUrl . '/events/' . $createdEventId, 'PUT', $updateData, $token);
    echo "HTTP Code: " . $result['code'] . "\n";
    echo "Response: " . $result['response'] . "\n\n";
    
    if ($result['code'] == 200) {
        echo "✅ Event updated successfully\n\n";
    } else {
        echo "❌ Failed to update event\n\n";
    }
}

// 4. Test deleting the created event
if ($createdEventId) {
    echo "4. Deleting the created event (ID: $createdEventId):\n";
    $result = makeRequest($baseUrl . '/events/' . $createdEventId, 'DELETE', null, $token);
    echo "HTTP Code: " . $result['code'] . "\n";
    echo "Response: " . $result['response'] . "\n\n";
    
    if ($result['code'] == 200 || $result['code'] == 204) {
        echo "✅ Event deleted successfully\n\n";
    } else {
        echo "❌ Failed to delete event\n\n";
    }
}

echo "CRUD testing completed!\n";

?>
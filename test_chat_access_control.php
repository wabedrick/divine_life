<?php

// Test role-based chat access control
$baseUrl = 'http://192.168.42.54:8000';

echo "=== TESTING ROLE-BASED CHAT ACCESS CONTROL ===\n\n";

// Test with member user (Musa Emma)
echo "1. Testing MEMBER USER access (Musa Emma)...\n";

$loginData = [
    'email' => 'musa@gmail.com',
    'password' => 'password123'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$loginResult = json_decode($response, true);

if (!isset($loginResult['access_token'])) {
    echo "❌ Member login failed: $response\n";
    exit(1);
}

$memberToken = $loginResult['access_token'];
$memberUser = $loginResult['user'];
echo "✅ Member login successful: {$memberUser['name']} (Branch ID: {$memberUser['branch_id']}, MC ID: " . ($memberUser['mc_id'] ?? 'None') . ")\n\n";

// Test member's conversation access by type
$conversationTypes = ['all', 'branch', 'mc', 'group'];

foreach ($conversationTypes as $type) {
    echo "Testing member access to '$type' conversations...\n";
    
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/chat/conversations?type=' . $type);
    curl_setopt($ch, CURLOPT_POST, false);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $memberToken,
        'Accept: application/json'
    ]);

    $convResponse = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if ($httpCode === 200) {
        $conversations = json_decode($convResponse, true);
        $count = count($conversations['data']);
        echo "✅ $type conversations: $count found\n";
        
        // Show conversation details for verification
        foreach ($conversations['data'] as $conv) {
            echo "  - {$conv['name']} (Type: {$conv['type']}, ID: {$conv['id']})\n";
        }
    } else {
        echo "❌ $type conversations failed: HTTP $httpCode\n";
    }
    echo "\n";
}

// Test accessing different branch (should fail)
echo "2. Testing member access to DIFFERENT BRANCH (should fail)...\n";
$otherBranchId = $memberUser['branch_id'] === 1 ? 2 : 1; // Pick different branch

curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/chat/conversations/category');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'type' => 'branch',
    'category_id' => $otherBranchId
]));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $memberToken,
    'Accept: application/json'
]);

$accessResponse = curl_exec($ch);
$accessHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if ($accessHttpCode === 403) {
    echo "✅ Good! Member correctly denied access to different branch (HTTP $accessHttpCode)\n";
} else {
    echo "❌ Security issue: Member can access different branch (HTTP $accessHttpCode)\n";
    echo "Response: $accessResponse\n";
}

// Test accessing own branch (should work)
echo "\n3. Testing member access to OWN BRANCH (should work)...\n";

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'type' => 'branch',
    'category_id' => $memberUser['branch_id']
]));

$ownBranchResponse = curl_exec($ch);
$ownBranchHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if ($ownBranchHttpCode === 200) {
    echo "✅ Good! Member can access own branch conversation\n";
    $branchConv = json_decode($ownBranchResponse, true);
    echo "Branch conversation: {$branchConv['data']['name']}\n";
} else {
    echo "❌ Issue: Member cannot access own branch (HTTP $ownBranchHttpCode)\n";
    echo "Response: $ownBranchResponse\n";
}

echo "\n=== TESTING ADMIN USER ACCESS ===\n\n";

// Test with admin user
$adminLoginData = [
    'email' => 'admin@divinelifechurch.org',
    'password' => 'password123'
];

curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/auth/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($adminLoginData));

$adminResponse = curl_exec($ch);
$adminLoginResult = json_decode($adminResponse, true);

if (isset($adminLoginResult['access_token'])) {
    $adminToken = $adminLoginResult['access_token'];
    $adminUser = $adminLoginResult['user'];
    echo "✅ Admin login successful: {$adminUser['name']} (Role: {$adminUser['role']})\n";
    
    // Test admin's broader access
    curl_setopt($ch, CURLOPT_URL, $baseUrl . '/api/chat/conversations?type=all');
    curl_setopt($ch, CURLOPT_POST, false);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $adminToken,
        'Accept: application/json'
    ]);

    $adminConvResponse = curl_exec($ch);
    $adminConvHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if ($adminConvHttpCode === 200) {
        $adminConversations = json_decode($adminConvResponse, true);
        $adminCount = count($adminConversations['data']);
        echo "✅ Admin can see $adminCount conversations (broader access than member)\n";
    }
} else {
    echo "❌ Admin login failed\n";
}

curl_close($ch);

echo "\n=== CHAT ACCESS CONTROL TEST COMPLETE ===\n";
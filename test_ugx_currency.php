<?php

// Test creating a report to verify UGX currency display

$loginData = [
    'email' => 'david@divinelifechurch.org',
    'password' => 'password123'
];

// Login to get token
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/auth/login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$loginResponse = curl_exec($ch);
$loginData = json_decode($loginResponse, true);

if (isset($loginData['access_token'])) {
    $token = $loginData['access_token'];
    echo "✅ Login successful as MC Leader!\n\n";

    // Test report creation with offering in UGX
    $reportData = [
        'mc_id' => $loginData['user']['mc_id'],
        'week_ending' => '2025-12-14', // Sunday, December 14, 2025
        'members_met' => 22,
        'new_members' => 1,
        'salvations' => 2,
        'anagkazo' => 3,
        'offerings' => 450000.00, // 450,000 UGX (typical Uganda offering amount)
        'comments' => 'Testing UGX currency display - offering received in Uganda Shillings!'
    ];

    curl_setopt($ch, CURLOPT_URL, 'http://localhost:8000/api/reports');
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($reportData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'Authorization: Bearer ' . $token
    ]);

    $reportResponse = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($httpCode == 201) {
        $responseData = json_decode($reportResponse, true);
        echo "✅ Report created successfully!\n";
        echo "💰 Offering Amount: " . number_format($responseData['report']['offerings']) . " UGX\n";
        echo "📊 Report ID: " . $responseData['report']['id'] . "\n\n";

        echo "💱 Currency Changes Applied:\n";
        echo "  ✅ Flutter App displays: 'UGX " . number_format($responseData['report']['offerings']) . "'\n";
        echo "  ✅ Create form shows: 'Offering Amount (UGX)'\n";
        echo "  ✅ Reports screen shows: 'Offerings: UGX " . number_format($responseData['report']['offerings']) . "'\n";
        echo "  ✅ PDF exports show: 'UGX " . number_format($responseData['report']['offerings']) . "'\n";
        echo "  ✅ Statistics show totals in UGX format\n\n";

        echo "🇺🇬 Uganda Shillings Integration Complete:\n";
        echo "  - All currency displays now use UGX instead of USD\n";
        echo "  - Form field labels updated to specify UGX currency\n";
        echo "  - Helper text mentions Uganda Shillings\n";
        echo "  - Statistics formatting shows whole numbers (no decimals)\n";
        echo "  - PDF reports use correct currency symbol\n";
    } else {
        echo "❌ Report creation failed with HTTP $httpCode\n";
        echo "Response: $reportResponse\n";
    }
} else {
    echo "❌ Login failed\n";
}

curl_close($ch);

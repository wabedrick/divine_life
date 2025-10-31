<?php
// Direct test of regex patterns

echo "Testing YouTube URL regex patterns...\n\n";

$testUrl = "https://youtu.be/t13lEQ78eYs?si=71QNAlh4w7NK8ALn";

// Test the main validation regex
$validationPattern = '/^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/.+/';
echo "Validation Pattern: $validationPattern\n";
echo "Test URL: $testUrl\n";

if (preg_match($validationPattern, $testUrl)) {
    echo "✅ Validation pattern matches\n";
} else {
    echo "❌ Validation pattern does NOT match\n";
}

// Test the video ID extraction pattern
$extractionPattern = '/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/';
echo "\nExtraction Pattern: $extractionPattern\n";

if (preg_match($extractionPattern, $testUrl, $matches)) {
    echo "✅ Extraction pattern matches\n";
    echo "Video ID: " . (isset($matches[1]) ? $matches[1] : 'Not found') . "\n";
} else {
    echo "❌ Extraction pattern does NOT match\n";
}

// Test for any regex issues
echo "\nTesting for regex delimiter issues...\n";

$patterns = [
    '/^https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/.+/',
    '/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/',
];

foreach ($patterns as $i => $pattern) {
    try {
        $result = preg_match($pattern, $testUrl);
        echo "Pattern " . ($i + 1) . ": ✅ OK\n";
    } catch (Exception $e) {
        echo "Pattern " . ($i + 1) . ": ❌ ERROR - " . $e->getMessage() . "\n";
    }
}

echo "\nDone.\n";
?>
<?php

// Quick test to check users in database using direct database connection

$host = 'localhost';
$dbname = 'divine_life';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Connected to database successfully!\n\n";

    // Get all users with their emails
    $stmt = $pdo->query("SELECT id, name, email, role, branch_id, mc_id, status FROM users ORDER BY id");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Total users in database: " . count($users) . "\n\n";

    echo "Users list:\n";
    echo "ID | Name | Email | Role | Branch | MC | Status\n";
    echo "---|------|-------|------|--------|----|---------\n";

    foreach ($users as $user) {
        printf(
            "%d | %s | %s | %s | %s | %s | %s\n",
            $user['id'],
            $user['name'],
            $user['email'],
            $user['role'],
            $user['branch_id'] ?? 'NULL',
            $user['mc_id'] ?? 'NULL',
            $user['status']
        );
    }

    echo "\n";

    // Check specifically for the email that's failing
    $email = 'wabwiireedrick@gmail.com';
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        echo "✅ User with email '$email' exists:\n";
        print_r($user);
    } else {
        echo "❌ User with email '$email' does NOT exist in database\n";

        // Check for similar emails
        $stmt = $pdo->prepare("SELECT email FROM users WHERE email LIKE ?");
        $stmt->execute(['%' . explode('@', $email)[0] . '%']);
        $similar = $stmt->fetchAll(PDO::FETCH_COLUMN);

        if ($similar) {
            echo "Similar emails found:\n";
            foreach ($similar as $similarEmail) {
                echo "- $similarEmail\n";
            }
        }
    }
} catch (PDOException $e) {
    echo "Database connection failed: " . $e->getMessage() . "\n";
}

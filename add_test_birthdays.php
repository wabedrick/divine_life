<?php

// Add birthday data to existing users for testing

$dbPath = __DIR__ . '/backend/database/database.sqlite';

try {
    $pdo = new PDO("sqlite:$dbPath");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Connected to SQLite database successfully!\n\n";

    // Update some users with birthdays including today's date
    $today = date('Y-m-d');
    $yesterday = date('Y-m-d', strtotime('-1 day'));
    $tomorrow = date('Y-m-d', strtotime('+1 day'));
    $nextWeek = date('Y-m-d', strtotime('+7 days'));

    // Set today as birthday for member1 (MC member)
    $todayBirthDate = date('1990-m-d'); // Set birth year as 1990 but keep today's month and day
    $stmt = $pdo->prepare("UPDATE users SET birth_date = ? WHERE email = ?");
    $stmt->execute([$todayBirthDate, 'member1@divinelife.com']);
    echo "✅ Set member1@divinelife.com birthday to today ($todayBirthDate)\n";

    // Set tomorrow as birthday for member2 (MC member in different MC)
    $tomorrowBirthDate = date('1992-m-d', strtotime('+1 day'));
    $stmt->execute([$tomorrowBirthDate, 'member2@divinelife.com']);
    echo "✅ Set member2@divinelife.com birthday to tomorrow ($tomorrowBirthDate)\n";

    // Set next week as birthday for MC leader
    $nextWeekBirthDate = date('1985-m-d', strtotime('+7 days'));
    $stmt->execute([$nextWeekBirthDate, 'mcleader2@divinelife.com']);
    echo "✅ Set mcleader2@divinelife.com birthday to next week ($nextWeekBirthDate)\n";

    // Set a random date for branch admin
    $randomBirthDate = '1980-06-15';
    $stmt->execute([$randomBirthDate, 'branch1@divinelife.com']);
    echo "✅ Set branch1@divinelife.com birthday to $randomBirthDate\n";

    echo "\n📊 Current users with birthdays:\n";
    $stmt = $pdo->query("SELECT name, email, birth_date, role, mc_id FROM users WHERE birth_date IS NOT NULL ORDER BY birth_date");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($users as $user) {
        $birthDate = new DateTime($user['birth_date']);
        $today = new DateTime();
        $isTodayBirthday = $birthDate->format('m-d') === $today->format('m-d') ? ' 🎂 TODAY!' : '';

        echo "- {$user['name']} ({$user['email']}) - {$user['birth_date']} ({$user['role']}){$isTodayBirthday}\n";
    }
} catch (PDOException $e) {
    echo "Database operation failed: " . $e->getMessage() . "\n";
}

<?php

// Simple test to verify birthday functionality directly in Laravel

require_once __DIR__ . '/backend/vendor/autoload.php';

// Bootstrap Laravel
$app = require_once __DIR__ . '/backend/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\User;
use Carbon\Carbon;

echo "🎂 Testing Birthday Functionality\n\n";

// Test the isBirthdayToday method
echo "📅 Testing isBirthdayToday method:\n";

// Get a user with today's birthday
$userWithTodayBirthday = User::whereNotNull('birth_date')->get()->filter(function ($user) {
    return $user->isBirthdayToday();
});

echo "Users with birthday today: " . $userWithTodayBirthday->count() . "\n";
foreach ($userWithTodayBirthday as $user) {
    echo "- {$user->name} ({$user->email}) - {$user->birth_date}\n";
}

echo "\n📊 Testing static methods:\n";

// Test getBirthdaysForMCLeader for MC 3
echo "\nBirthdays for MC 3:\n";
$mc3Birthdays = User::getBirthdaysForMCLeader(3);
echo "Count: " . $mc3Birthdays->count() . "\n";
foreach ($mc3Birthdays as $user) {
    echo "- {$user->name} ({$user->role}) - {$user->birth_date}\n";
}

// Test getBirthdaysForBranchAdmin for Branch 1
echo "\nBirthdays for Branch 1:\n";
$branch1Birthdays = User::getBirthdaysForBranchAdmin(1);
echo "Count: " . $branch1Birthdays->count() . "\n";
foreach ($branch1Birthdays as $user) {
    echo "- {$user->name} ({$user->role}) - {$user->birth_date}\n";
}

echo "\n✅ Birthday functionality test completed!\n";

<?php

require_once 'vendor/autoload.php';

// Load Laravel app
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "Available users:\n";
$users = App\Models\User::select('email', 'role')->get();

foreach ($users as $user) {
    echo "- {$user->email} (Role: {$user->role})\n";
}

echo "\nTotal users: " . $users->count() . "\n";

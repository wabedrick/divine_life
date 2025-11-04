<?php

require 'backend/vendor/autoload.php';

// Load Laravel app
$app = require 'backend/bootstrap/app.php';

// Get users  
$users = $app->make('App\Models\User')::select('email', 'role')->get();

echo "=== Current Users in Database ===\n";
foreach ($users as $user) {
    echo $user->email . " - " . $user->role . "\n";
}
echo "\nTotal users: " . count($users) . "\n";

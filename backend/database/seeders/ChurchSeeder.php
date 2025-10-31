<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ChurchSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create branches
        $mainBranch = \App\Models\Branch::create([
            'name' => 'Divine Life- HQ',
            'description' => 'Main church headquarters',
            'location' => 'Kampala, Uganda',
            'address' => '123 Church Street, Kampala',
            'phone_number' => '+256700123456',
            'email' => 'hq@divinelifechurch.org',
            'is_active' => true,
        ]);

        $eastBranch = \App\Models\Branch::create([
            'name' => 'Divine Life Church - East Campus',
            'description' => 'Eastern branch',
            'location' => 'Jinja, Uganda',
            'address' => '456 Eastern Avenue, Jinja',
            'phone_number' => '+256700123457',
            'email' => 'east@divinelifechurch.org',
            'is_active' => true,
        ]);

        // Create super admin user
        $superAdmin = \App\Models\User::create([
            'name' => 'Super Administrator',
            'email' => 'admin@divinelifechurch.org',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'phone_number' => '+256700000001',
            'birth_date' => '1980-01-01',
            'gender' => 'male',
            'role' => 'super_admin',
            'branch_id' => $mainBranch->id,
            'is_approved' => true,
            'approved_at' => now(),
        ]);

        // Create branch admin
        $branchAdmin = \App\Models\User::create([
            'name' => 'John Branch Admin',
            'email' => 'john@divinelifechurch.org',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'phone_number' => '+256700000002',
            'birth_date' => '1985-05-15',
            'gender' => 'male',
            'role' => 'branch_admin',
            'branch_id' => $mainBranch->id,
            'is_approved' => true,
            'approved_at' => now(),
            'approved_by' => $superAdmin->id,
        ]);

        // Update branch admin
        $mainBranch->update(['admin_id' => $branchAdmin->id]);

        // Create MC leaders first
        $mcLeaderAlpha = \App\Models\User::create([
            'name' => 'Sarah MC Leader',
            'email' => 'sarah@divinelifechurch.org',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'phone_number' => '+256700000003',
            'birth_date' => '1990-03-20',
            'gender' => 'female',
            'role' => 'mc_leader',
            'branch_id' => $mainBranch->id,
            'is_approved' => true,
            'approved_at' => now(),
            'approved_by' => $branchAdmin->id,
        ]);

        $mcLeaderBeta = \App\Models\User::create([
            'name' => 'David MC Leader',
            'email' => 'david@divinelifechurch.org',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'phone_number' => '+256700000004',
            'birth_date' => '1988-07-10',
            'gender' => 'male',
            'role' => 'mc_leader',
            'branch_id' => $mainBranch->id,
            'is_approved' => true,
            'approved_at' => now(),
            'approved_by' => $branchAdmin->id,
        ]);

        // Create MCs with leaders
        $mcAlpha = \App\Models\MC::create([
            'name' => 'Alpha Community',
            'vision' => 'To reach the lost in Kampala Central',
            'goals' => 'Plant 5 new churches by 2025',
            'purpose' => 'Evangelism and discipleship in urban areas',
            'location' => 'Kampala Central',
            'leader_id' => $mcLeaderAlpha->id,
            'leader_phone' => '+256700000003',
            'branch_id' => $mainBranch->id,
            'is_active' => true,
        ]);

        $mcBeta = \App\Models\MC::create([
            'name' => 'Beta Community',
            'vision' => 'Transform families in Nakawa',
            'goals' => 'Establish 10 home groups',
            'purpose' => 'Family ministry and youth development',
            'location' => 'Nakawa Division',
            'leader_id' => $mcLeaderBeta->id,
            'leader_phone' => '+256700000004',
            'branch_id' => $mainBranch->id,
            'is_active' => true,
        ]);

        // Update MC leaders with their MC assignments
        $mcLeaderAlpha->update(['mc_id' => $mcAlpha->id]);
        $mcLeaderBeta->update(['mc_id' => $mcBeta->id]);

        // Create sample members
        \App\Models\User::create([
            'name' => 'Grace Member',
            'email' => 'grace@example.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'phone_number' => '+256700000005',
            'birth_date' => '1995-12-25',
            'gender' => 'female',
            'role' => 'member',
            'branch_id' => $mainBranch->id,
            'mc_id' => $mcAlpha->id,
            'is_approved' => true,
            'approved_at' => now(),
            'approved_by' => $mcLeaderAlpha->id,
        ]);

        \App\Models\User::create([
            'name' => 'Peter Member',
            'email' => 'peter@example.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'phone_number' => '+256700000006',
            'birth_date' => '1992-08-14',
            'gender' => 'male',
            'role' => 'member',
            'branch_id' => $mainBranch->id,
            'mc_id' => $mcBeta->id,
            'is_approved' => true,
            'approved_at' => now(),
            'approved_by' => $mcLeaderBeta->id,
        ]);

        // Create sample events
        \App\Models\Event::create([
            'title' => 'Sunday Service',
            'description' => 'Weekly Sunday worship service',
            'event_date' => now()->next('Sunday')->setTime(9, 0),
            'end_date' => now()->next('Sunday')->setTime(12, 0),
            'location' => 'Main Sanctuary',
            'visibility' => 'all',
            'created_by' => $branchAdmin->id,
            'is_active' => true,
        ]);

        \App\Models\Event::create([
            'title' => 'MC Alpha Fellowship',
            'description' => 'Monthly community fellowship',
            'event_date' => now()->addWeek()->setTime(19, 0),
            'location' => 'Community Hall',
            'visibility' => 'mc',
            'mc_id' => $mcAlpha->id,
            'created_by' => $mcLeaderAlpha->id,
            'is_active' => true,
        ]);

        // Create sample announcements
        \App\Models\Announcement::create([
            'title' => 'Welcome to Divine Life Church App',
            'content' => 'We are excited to launch our new church management app. Please explore the features and stay connected with your church family.',
            'priority' => 'high',
            'visibility' => 'all',
            'created_by' => $superAdmin->id,
            'is_active' => true,
        ]);

        \App\Models\Announcement::create([
            'title' => 'MC Leaders Meeting',
            'content' => 'All MC leaders are invited to attend the monthly planning meeting this Friday at 7 PM.',
            'priority' => 'normal',
            'visibility' => 'branch',
            'branch_id' => $mainBranch->id,
            'created_by' => $branchAdmin->id,
            'expires_at' => now()->addWeeks(2),
            'is_active' => true,
        ]);
    }
}

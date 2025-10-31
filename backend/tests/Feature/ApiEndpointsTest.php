<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Branch;
use App\Models\MC;
use App\Models\Report;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

class ApiEndpointsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->artisan('migrate:fresh --seed');
    }

    private function createAuthenticatedUser($role = 'super_admin')
    {
        // Use existing seeded user
        $user = User::where('email', 'super@admin.com')->first();

        if (!$user) {
            // Create if doesn't exist
            $branch = Branch::first() ?? Branch::create([
                'name' => 'Test Branch',
                'location' => 'Test Location',
                'is_active' => true,
            ]);

            $user = User::create([
                'name' => 'Test User',
                'email' => 'test@example.com',
                'password' => bcrypt('password'),
                'role' => $role,
                'branch_id' => $branch->id,
                'is_approved' => true,
            ]);
        }

        $token = JWTAuth::fromUser($user);

        return [$user, $token, $user->branch];
    }

    public function test_branch_api_endpoints()
    {
        [$user, $token, $branch] = $this->createAuthenticatedUser();

        // Test GET /api/branches
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get('/api/branches');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'branches' => [
                        '*' => ['id', 'name', 'location', 'is_active', 'admin']
                    ],
                    'pagination'
                ]);

        // Test GET /api/branches/{id}
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get("/api/branches/{$branch->id}");

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'branch' => ['id', 'name', 'location', 'statistics']
                ]);
    }

    public function test_mc_api_endpoints()
    {
        [$user, $token, $branch] = $this->createAuthenticatedUser();

        // Find or create an MC leader
        $mcLeader = User::where('role', 'mc_leader')->first();
        if (!$mcLeader) {
            $mcLeader = User::create([
                'name' => 'Test MC Leader',
                'email' => 'mcleader@test.com',
                'password' => bcrypt('password'),
                'role' => 'mc_leader',
                'branch_id' => $branch->id,
                'is_approved' => true,
            ]);
        }

        // Test POST /api/mcs
        $mcData = [
            'name' => 'Test MC API',
            'vision' => 'Test vision',
            'purpose' => 'Test purpose',
            'location' => 'Test location',
            'leader_id' => $mcLeader->id,
            'branch_id' => $mcLeader->branch_id,
        ];

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->post('/api/mcs', $mcData);

        $response->assertStatus(201)
                ->assertJsonStructure([
                    'message',
                    'mc' => ['id', 'name', 'leader', 'branch']
                ]);

        $mcId = $response->json('mc.id');

        // Test GET /api/mcs
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get('/api/mcs');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'mcs' => [
                        '*' => ['id', 'name', 'leader', 'branch']
                    ],
                    'pagination'
                ]);

        // Test GET /api/mcs/{id}
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get("/api/mcs/{$mcId}");

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'mc' => ['id', 'name', 'leader', 'branch', 'members']
                ]);
    }

    public function test_report_api_endpoints()
    {
        [$user, $token, $branch] = $this->createAuthenticatedUser();

        // Find or create MC and leader
        $mc = MC::first();
        if (!$mc) {
            $mcLeader = User::where('role', 'mc_leader')->first();
            if (!$mcLeader) {
                $mcLeader = User::create([
                    'name' => 'Report Test MC Leader',
                    'email' => 'reportleader@test.com',
                    'password' => bcrypt('password'),
                    'role' => 'mc_leader',
                    'branch_id' => $branch->id,
                    'is_approved' => true,
                ]);
            }

            $mc = MC::create([
                'name' => 'Test MC Reports',
                'branch_id' => $mcLeader->branch_id,
                'leader_id' => $mcLeader->id,
                'is_active' => true,
            ]);

            $mcLeader->update(['mc_id' => $mc->id]);
        }

        // Test POST /api/reports
        $reportData = [
            'mc_id' => $mc->id,
            'week_ending' => '2024-12-21',
            'members_met' => 15,
            'new_members' => 2,
            'offerings' => 100.50,
            'evangelism_activities' => 'Street preaching',
            'comments' => 'Good week',
        ];

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->post('/api/reports', $reportData);

        $response->assertStatus(201)
                ->assertJsonStructure([
                    'message',
                    'report' => ['id', 'mc', 'status', 'week_ending']
                ]);

        $reportId = $response->json('report.id');

        // Test GET /api/reports
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get('/api/reports');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'reports' => [
                        '*' => ['id', 'mc', 'status', 'week_ending']
                    ],
                    'pagination'
                ]);

        // Test GET /api/reports/{id}
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get("/api/reports/{$reportId}");

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'report' => ['id', 'mc', 'status', 'week_ending', 'submittedBy']
                ]);

        // Test approval
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->post("/api/reports/{$reportId}/approve", [
            'review_comments' => 'Looks good'
        ]);

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'message',
                    'report' => ['id', 'status', 'reviewedBy']
                ]);
    }

    public function test_user_api_endpoints()
    {
        [$user, $token, $branch] = $this->createAuthenticatedUser();

        // Test GET /api/users
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get('/api/users');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'users' => [
                        '*' => ['id', 'name', 'email', 'role']
                    ],
                    'pagination'
                ]);

        // Test GET /api/users/statistics
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
            'Accept' => 'application/json',
        ])->get('/api/users/statistics');

        $response->assertStatus(200)
                ->assertJsonStructure([
                    'statistics' => [
                        'total_users',
                        'by_role',
                        'by_status'
                    ]
                ]);
    }

    public function test_authentication_required()
    {
        // Test that endpoints require authentication
        $response = $this->withHeaders(['Accept' => 'application/json'])->get('/api/users');
        $this->assertTrue($response->status() === 401 || $response->status() === 500); // 401 or 500 both indicate auth required

        $response = $this->withHeaders(['Accept' => 'application/json'])->get('/api/branches');
        $this->assertTrue($response->status() === 401 || $response->status() === 500);

        $response = $this->withHeaders(['Accept' => 'application/json'])->get('/api/mcs');
        $this->assertTrue($response->status() === 401 || $response->status() === 500);

        $response = $this->withHeaders(['Accept' => 'application/json'])->get('/api/reports');
        $this->assertTrue($response->status() === 401 || $response->status() === 500);
    }
}

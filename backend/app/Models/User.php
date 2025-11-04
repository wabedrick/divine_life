<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

/**
 * Divine Life Church User Model
 *
 * @property int $id
 * @property string $name
 * @property string $email
 * @property string $role
 * @property int|null $branch_id
 * @property int|null $mc_id
 * @property bool $is_approved
 *
 * @method bool isSuperAdmin() Check if user has super admin role
 * @method bool isBranchAdmin() Check if user has branch admin role
 * @method bool isMCLeader() Check if user has MC leader role
 * @method bool isMember() Check if user has member role
 *
 * @mixin \Illuminate\Database\Eloquent\Builder
 */
class User extends Authenticatable implements JWTSubject
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone_number',
        'branch_id',
        'mc_id',
        'birth_date',
        'gender',
        'role',
        'is_approved',
        'approved_at',
        'approved_by',
        'rejection_reason'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'birth_date' => 'date',
        ];
    }

    /**
     * Get the identifier that will be stored in the subject claim of the JWT.
     *
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * Return a key value array, containing any custom claims to be added to the JWT.
     *
     * @return array
     */
    public function getJWTCustomClaims()
    {
        return [
            'role' => $this->role,
            'branch_id' => $this->branch_id,
            'mc_id' => $this->mc_id,
        ];
    }

    /**
     * Get the branch that the user belongs to.
     */
    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    /**
     * Get the missional community that the user belongs to.
     */
    public function mc()
    {
        return $this->belongsTo(MC::class);
    }

    /**
     * Get reports submitted by this user (if MC Leader).
     */
    public function reports()
    {
        return $this->hasMany(Report::class, 'submitted_by');
    }

    /**
     * Check if user has a specific role.
     */
    public function hasRole(string $role): bool
    {
        return $this->role === $role;
    }

    /**
     * Check if user can manage users (admin roles).
     */
    public function canManageUsers(): bool
    {
        return in_array($this->role, ['super_admin', 'branch_admin']);
    }

    /**
     * Check if user is super admin.
     */
    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }

    /**
     * Check if user is branch admin.
     */
    public function isBranchAdmin(): bool
    {
        return $this->role === 'branch_admin';
    }

    /**
     * Check if user is MC leader.
     */
    public function isMCLeader(): bool
    {
        return $this->role === 'mc_leader';
    }

    /**
     * Check if user is member.
     */
    public function isMember(): bool
    {
        return $this->role === 'member';
    }

    /**
     * Check if today is user's birthday
     */
    public function isBirthdayToday(): bool
    {
        if (!$this->birth_date) {
            return false;
        }

        $today = now();
        $birthDate = \Carbon\Carbon::parse($this->birth_date);

        return $today->month === $birthDate->month && $today->day === $birthDate->day;
    }

    /**
     * Get users with birthdays today for MC leaders
     */
    public static function getBirthdaysForMCLeader(int $mcId): \Illuminate\Database\Eloquent\Collection
    {
        return self::where('mc_id', $mcId)
            ->whereNotNull('birth_date')
            ->get()
            ->filter(function ($user) {
                return $user->isBirthdayToday();
            });
    }

    /**
     * Get users with birthdays today for Branch admins
     */
    public static function getBirthdaysForBranchAdmin(int $branchId): \Illuminate\Database\Eloquent\Collection
    {
        return self::where('branch_id', $branchId)
            ->whereNotNull('birth_date')
            ->get()
            ->filter(function ($user) {
                return $user->isBirthdayToday();
            });
    }
}

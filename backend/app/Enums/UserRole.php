<?php

namespace App\Enums;

enum UserRole: string
{
    case SUPER_ADMIN = 'super_admin';
    case BRANCH_ADMIN = 'branch_admin';
    case MC_LEADER = 'mc_leader';
    case MEMBER = 'member';

    public function label(): string
    {
        return match($this) {
            UserRole::SUPER_ADMIN => 'Super Admin',
            UserRole::BRANCH_ADMIN => 'Branch Admin',
            UserRole::MC_LEADER => 'MC Leader',
            UserRole::MEMBER => 'Member',
        };
    }

    public function permissions(): array
    {
        return match($this) {
            UserRole::SUPER_ADMIN => [
                'manage_all',
                'approve_branch_admins',
                'view_all_reports',
                'manage_branches',
                'system_settings'
            ],
            UserRole::BRANCH_ADMIN => [
                'manage_branch',
                'approve_reports',
                'manage_mcs',
                'create_events',
                'create_announcements'
            ],
            UserRole::MC_LEADER => [
                'manage_mc',
                'submit_reports',
                'manage_mc_members',
                'view_mc_statistics'
            ],
            UserRole::MEMBER => [
                'view_events',
                'view_announcements',
                'chat',
                'view_profile'
            ]
        };
    }

    public function canManage(UserRole $role): bool
    {
        $hierarchy = [
            UserRole::SUPER_ADMIN->value => 4,
            UserRole::BRANCH_ADMIN->value => 3,
            UserRole::MC_LEADER->value => 2,
            UserRole::MEMBER->value => 1,
        ];

        return $hierarchy[$this->value] > $hierarchy[$role->value];
    }
}

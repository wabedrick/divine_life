# Current Login Credentials

The app is now using **REAL DATABASE** with Laravel backend! Use these actual database accounts:

## Available Test Users

### Super Admin
- **Email:** `admin@test.com`
- **Password:** `password`
- **Role:** Super Admin (full access)

### Branch Admin  
- **Email:** `branch@test.com`
- **Password:** `password`
- **Role:** Branch Admin (manage branch users and MCs)

### MC Leader
- **Email:** `leader@test.com` 
- **Password:** `password`
- **Role:** MC Leader (manage MC members and reports)

### Church Member
- **Email:** `member@test.com`
- **Password:** `password` 
- **Role:** Member (basic access, submit reports)

## Features Available
- ✅ Login/Logout functionality
- ✅ Role-based dashboard navigation
- ✅ Mock user management
- ✅ Mock reports and events
- ✅ All UI screens functional

## Connection Status
- ✅ **Mock Mode Active** - No connection timeouts, instant login
- ⚡ **Fast & Reliable** - All features work without server dependency
- 🔄 **Easy Switching** - Can enable real backend anytime

## Switch to Real Backend (When Server Issues Resolved)
1. Start Laravel server: `php artisan serve --host=0.0.0.0 --port=8000`
2. In `lib/core/services/api_service.dart`, change:
   ```dart
   static const bool _useMockData = false;
   ```
3. Use real credentials from `REAL_DATABASE_CREDENTIALS.md`

## Note
Mock data provides consistent test data for UI development without requiring a backend server.
# Real Database Login Credentials

When the Laravel backend is successfully connected, use these **REAL** database user accounts:

## Available Real Database Users

### Super Administrator
- **Email:** `admin@divinelifechurch.org`
- **Password:** `password123`
- **Role:** Super Admin (full system access)
- **Branch:** Main Campus

### Branch Administrator  
- **Email:** `john@divinelifechurch.org`
- **Password:** `password123`
- **Role:** Branch Admin (manage branch users and MCs)
- **Branch:** Main Campus

### MC Leader 1
- **Email:** `sarah@divinelifechurch.org` 
- **Password:** `password123`
- **Role:** MC Leader (manage MC members and reports)
- **Branch:** Main Campus

### MC Leader 2
- **Email:** `david@divinelifechurch.org`
- **Password:** `password123` 
- **Role:** MC Leader (manage MC members and reports)
- **Branch:** East Campus

## Connection Status

### If Backend Connected (Real Authentication):
- Uses actual database users above
- All data is persistent in SQLite database
- Full API functionality with Laravel backend

### If Backend Not Available (Auto-Fallback):
- Automatically switches to mock data
- Uses test credentials: `admin@test.com` / `password`
- No data persistence, but full UI functionality

## Network Configuration

### For Android Emulator:
- API URL: `http://10.0.2.2:8000/api`
- Laravel Server: `php artisan serve --host=0.0.0.0 --port=8000`

### For iOS Simulator:
- API URL: `http://localhost:8000/api` 
- Laravel Server: `php artisan serve --port=8000`

### For Physical Device:
- API URL: `http://[YOUR_IP_ADDRESS]:8000/api`
- Laravel Server: `php artisan serve --host=0.0.0.0 --port=8000`

## Troubleshooting

1. **Start Laravel Server:**
   ```bash
   cd backend
   php artisan serve --host=0.0.0.0 --port=8000
   ```

2. **Check Server Status:**
   ```bash
   curl http://localhost:8000/api/test
   ```

3. **If Connection Fails:**
   - App automatically falls back to mock data
   - Check firewall settings
   - Verify Laravel server is running
   - Try different network configuration

## Database Access

**SQLite Database Location:** `backend/database/database.sqlite`

**View Database Contents:**
```bash
php artisan tinker
> App\Models\User::all(['name', 'email', 'role']);
```
# Laravel Development Server Alternatives

## Option 1: Mock Data (Currently Active)
The app is now configured to use mock data when the backend is not available.
- Set `_useMockData = false` in `ApiService` when backend is working
- Use credentials: `admin@test.com` / `password` for testing

## Option 2: PHP Built-in Server 
Try these commands in the backend directory:

### Method A: Standard Artisan
```powershell
cd C:\Users\EDRICK\Desktop\divine_life\backend
php artisan serve --host=127.0.0.1 --port=8000
```

### Method B: Direct PHP Server
```powershell
cd C:\Users\EDRICK\Desktop\divine_life\backend\public
php -S 127.0.0.1:8000 -t . ../server.php
```

### Method C: Different Port
```powershell
cd C:\Users\EDRICK\Desktop\divine_life\backend
php artisan serve --host=0.0.0.0 --port=3000
```

## Option 3: XAMPP/WAMP
1. Install XAMPP
2. Copy project to `htdocs/divine_life`
3. Access via `http://localhost/divine_life/backend/public`

## Option 4: Docker (Advanced)
```dockerfile
# Create Dockerfile in backend directory
FROM php:8.2-apache
COPY . /var/www/html
RUN docker-php-ext-install pdo pdo_mysql
EXPOSE 80
```

## Testing Backend Connection
After starting any server, test with:
```powershell
curl http://127.0.0.1:8000
# or
curl http://localhost:8000
```

## Troubleshooting Windows Issues
1. **Check Windows Firewall**: Add exception for PHP
2. **Antivirus Software**: Temporarily disable to test
3. **Host File**: Ensure `127.0.0.1 localhost` exists in `C:\Windows\System32\drivers\etc\hosts`
4. **Port Conflicts**: Use `netstat -ano | findstr :8000` to check port usage

## Switch Back to Real API
When backend is working, change in `ApiService.dart`:
```dart
static const bool _useMockData = false; // Enable real API
```
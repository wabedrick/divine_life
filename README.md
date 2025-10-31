# Divine Life Church App

A comprehensive church management system with Flutter mobile frontend and Laravel backend API.

## 🏗️ Project Overview

The Divine Life Church App is designed to streamline ministry operations, improve communication, and enhance spiritual community engagement across multiple church branches and missional communities.

### Key Features

- **Multi-Role System**: Super Admin, Branch Admin, MC Leader, and Member roles
- **Missional Communities Management**: Complete MC lifecycle management
- **Weekly Reports**: Automated reporting and approval workflow
- **Real-time Chat**: Member-to-member and group communication
- **Events & Announcements**: Church-wide communication system
- **Analytics & Statistics**: Growth trends and comparative reports
- **Offline Capability**: Reports can be filled offline and synced later
- **Push Notifications**: Automated alerts for birthdays, reports, and updates

## 🏛️ Architecture

```
Divine Life Church App
├── Flutter Mobile App (Frontend)
│   ├── Authentication & User Management
│   ├── Dashboard & Navigation
│   ├── MC Management Interface
│   ├── Reports & Statistics
│   ├── Chat System
│   └── Events & Announcements
├── Laravel API Backend
│   ├── JWT Authentication
│   ├── Role-based Access Control
│   ├── REST API Endpoints
│   ├── Real-time Chat (Pusher)
│   └── Report Analytics
└── MySQL Database
    ├── Users & Roles
    ├── Branches & MCs
    ├── Reports & Statistics
    └── Messages & Events
```

## 📋 Prerequisites

### For Backend Development
- PHP 8.2 or higher
- Composer
- MySQL 8.0 or higher
- Node.js & npm (for asset compilation)

### For Mobile Development  
- Flutter SDK 3.35.6 or higher
- Dart SDK
- Android Studio (for Android development)
- Xcode (for iOS development - macOS only)

### Development Tools
- Visual Studio Code with extensions:
  - Flutter
  - Laravel Extension Pack
  - PHP Tools

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/your-repo/divine-life-church-app.git
cd divine-life-church-app
```

### 2. Backend Setup (Laravel)

```bash
# Navigate to backend directory
cd backend

# Install PHP dependencies
composer install

# Copy environment file
copy .env.example .env  # Windows
cp .env.example .env    # macOS/Linux

# Generate application key
php artisan key:generate

# Configure database in .env file
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=divine_life_church
DB_USERNAME=your_username
DB_PASSWORD=your_password

# Run migrations and seeders
php artisan migrate:fresh --seed

# Start Laravel development server
php artisan serve
```

### 3. Mobile App Setup (Flutter)

```bash
# Navigate to Flutter app directory
cd flutter_app

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

## 🎯 Running the Application

### Using VS Code Tasks

The project includes pre-configured VS Code tasks for easy development:

1. **Run Both Apps**: `Ctrl+Shift+P` → `Tasks: Run Task` → `Run Both Apps`
2. **Run Flutter App Only**: `Tasks: Run Task` → `Run Flutter App`
3. **Run Laravel Backend Only**: `Tasks: Run Task` → `Run Laravel Backend`

### Manual Commands

**Backend (Terminal 1):**
```bash
cd backend
php artisan serve
# Server will start at http://localhost:8000
```

**Frontend (Terminal 2):**
```bash
cd flutter_app
flutter run
# Choose target device (Chrome, Android emulator, etc.)
```

## 📱 User Roles & Permissions

### Super Admin
- Approve Branch Admins
- Manage entire system data
- Generate system-wide reports
- Oversee all activities

### Branch Admin  
- Review MC reports
- Generate branch statistics
- Post events and announcements
- Manage branch MCs

### MC Leader
- Submit weekly reports
- Manage MC members
- Celebrate member birthdays
- Handle evangelism activities

### Member
- View announcements and events
- Participate in chat
- Interact with MC
- Submit personal details

## 🗄️ Database Schema

### Key Tables
- `users` - User authentication and profile data
- `branches` - Church branch information  
- `missional_communities` - MC details and leadership
- `weekly_reports` - MC weekly report submissions
- `events` - Church events and activities
- `announcements` - Church-wide announcements
- `messages` - Chat system messages
- `conversations` - Chat conversation management

## 🔧 Development Workflow

### Backend Development
```bash
# Create new migration
php artisan make:migration create_table_name

# Create new model with migration
php artisan make:model ModelName -m

# Create new controller
php artisan make:controller ControllerName

# Run tests
php artisan test
```

### Frontend Development
```bash
# Add new dependency
flutter pub add package_name

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test
```

## 📊 API Documentation

The API documentation is available at:
- **Development**: `http://localhost:8000/api/documentation`
- **Swagger Docs**: [API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md)

### Authentication
All API endpoints require JWT authentication:
```
Authorization: Bearer {jwt_token}
```

## 🧪 Testing

### Backend Testing
```bash
cd backend
php artisan test
```

### Frontend Testing
```bash
cd flutter_app
flutter test
```

## 🚢 Deployment

### Backend Deployment
1. Configure production environment (.env)
2. Set up MySQL database
3. Run migrations: `php artisan migrate --force`
4. Configure web server (Apache/Nginx)
5. Set up SSL certificates
6. Configure push notifications (Firebase)

### Mobile App Deployment
1. **Android**: Build APK/Bundle and upload to Google Play Store
2. **iOS**: Build archive and upload to Apple App Store

## 🔒 Security Features

- JWT-based authentication
- Role-based access control  
- Input validation and sanitization
- SQL injection protection
- File upload security
- API rate limiting
- Secure password hashing

## 📈 Performance Targets

- Support 10,000+ concurrent users
- API response time < 500ms
- Mobile app startup < 3 seconds
- Offline capability for reports
- Real-time chat latency < 100ms

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📋 Development Checklist

### Phase 1: Foundation ✅
- [x] Project setup and scaffolding
- [x] Basic Laravel API structure  
- [x] Flutter app initialization
- [x] Database schema design
- [x] Authentication system

### Phase 2: Core Features
- [ ] User management system
- [ ] MC management interface
- [ ] Weekly reports module
- [ ] Events and announcements
- [ ] Basic chat functionality

### Phase 3: Advanced Features  
- [ ] Real-time notifications
- [ ] Analytics dashboard
- [ ] Export functionality
- [ ] Offline synchronization
- [ ] File sharing

### Phase 4: Polish & Deploy
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] Testing & QA
- [ ] App store deployment
- [ ] Production server setup

## 📞 Support

For development questions and support:
- **Documentation**: Check [docs/](docs/) directory
- **Issues**: Create GitHub issues for bugs
- **Development Plan**: See [DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for Divine Life Church Community**
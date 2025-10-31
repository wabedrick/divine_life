# Divine Life Church App Development Instructions

## Project Overview
This workspace contains the Divine Life Church App - a comprehensive church management system with Flutter mobile frontend and Laravel backend API.

## Project Structure
- `/flutter_app` - Flutter mobile application
- `/backend` - Laravel API backend
- `/docs` - Project documentation including SRS and API specs

## Key Requirements
- **User Roles**: Super Admin, Branch Admin, MC Leader, Member
- **Core Features**: Branch management, Missional Communities, Reports, Chat, Events, Announcements
- **Technology Stack**: Flutter (mobile), Laravel (backend), MySQL (database)
- **Authentication**: JWT-based with role-based access control

## Development Guidelines
- Follow Flutter best practices for mobile development
- Use Laravel conventions for API development
- Implement proper role-based permissions
- Ensure offline capability for reports
- Include comprehensive error handling
- Follow the SRS document specifications

## Architecture Notes
- RESTful API design between Flutter and Laravel
- Real-time chat using WebSocket/Pusher
- Push notifications for announcements and birthdays
- Weekly automated reports and statistics
- Export capabilities (PDF/Excel)

## Code Standards
- Use proper MVC patterns in Laravel
- Follow Flutter widget composition patterns
- Implement proper state management (Provider/Bloc)
- Include comprehensive unit and integration tests
- Document all API endpoints

## Security Requirements
- JWT authentication tokens
- Role-based access control
- Input validation and sanitization
- Secure file upload handling
- Database query protection
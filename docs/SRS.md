# Divine Life Church App – Software Requirements Specification (SRS)

## 1. Project Overview

**Project Name:** Divine Life Church App  
**Platforms:** Flutter (Mobile App), Laravel (Backend & API)  
**Purpose:** To create a centralized mobile platform that manages the church's branches, missional communities (MCs), reports, announcements, events, and communication among members. The app should streamline ministry operations, improve communication, and enhance spiritual community engagement.

## 2. Stakeholders

| Role | Description | Key Responsibilities |
|------|-------------|---------------------|
| Super Admin | Overall system controller | Approves branch admins, manages entire data, generates reports, oversees activities |
| Branch Admin | Manages a specific church branch | Reviews MC reports, generates weekly/monthly statistics, posts events/announcements |
| MC Leader | Leads a missional community | Submits weekly reports, manages MC members, celebrates birthdays, handles evangelism reports |
| Member/User | Regular church member | Views announcements/events, chats, interacts with MC, submits personal details |

## 3. Functional Requirements

### 3.1 User Management
- Users register with Name, Email, Phone Number, Branch, Birth Date, Gender, and MC.
- Super Admin registers Branch Admins.
- Branch Admin registers MC Leaders.
- MC Leaders register MC Members.
- Users can securely log in and log out.
- Role changes done by higher-level admins.
- Super Admin must approve deletions.

### 3.2 Missional Communities (MCs)
- Each MC has a name, leader, location, leader's phone number, members, vision, goals, and purpose.
- MC Leaders can add/edit members, submit weekly reports, and celebrate member birthdays.
- **Weekly Report Fields:** members met, new members, comments, offerings, evangelism activities.
- Reports flow from MC Leader → Branch Admin → Super Admin.

### 3.3 Statistics & Analytics
- Weekly and monthly reports with comparison charts.
- View trends for attendance, offerings, evangelism.
- Export options (PDF/Excel).

### 3.4 Announcements & Events
- Admins can post church-wide announcements and events.
- New announcements show with a "New" label.
- Events have title, description, date, and visibility scope.

### 3.5 Chat and Communication
- Member-to-member and group chat.
- Support for text, voice notes, and file sharing.
- Group chats for each MC.

### 3.6 Notifications
- Push notifications for new announcements, birthdays, report confirmations, and system updates.

## 4. Non-Functional Requirements
- **Security:** JWT Authentication and role-based access control.
- **Performance:** Supports 10,000+ users.
- **Scalability:** Add more branches and MCs easily.
- **Usability:** Simple and intuitive UI.
- **Offline Capability:** Reports can be filled offline.
- **Data Backup:** Weekly automatic backup.
- **Localization:** English, expandable to more languages.

## 5. System Architecture
- **Frontend (Flutter):** Manages UI, data submission, chat, and notifications.
- **Backend (Laravel):** Provides APIs, manages roles, and analytics.
- **Database (MySQL):** Stores all church-related data.

## 6. Key Modules Summary
- **Authentication Module** – Login, Registration, Forgot Password
- **MC Management Module** – Create, update, delete, and view MCs
- **Reports Module** – Submit and view weekly reports
- **Statistics Module** – Visualize growth trends
- **Announcements Module** – Manage and display updates
- **Events Module** – Schedule and show events
- **Chat Module** – Enable communication
- **Notifications Module** – Send reminders and alerts
- **Birthday Reminder Module** – Automatic birthday alerts

## 7. Future Enhancements
- Integration with church giving platforms.
- Attendance tracking via QR codes.
- Live sermon streaming.
- Bible reading plans.
- Role-based analytics dashboards.

## 8. Deliverables
- Flutter mobile app (Android + iOS)
- Laravel backend with REST API
- MySQL database schema
- API documentation (Swagger/Postman)
- Admin dashboard (optional web interface)

## 9. Conclusion
The Divine Life Church App will streamline ministry operations, improve accountability, and foster community engagement. This document serves as a guide for developers (human or AI) to understand the app's scope and functionality.
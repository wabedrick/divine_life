# Divine Life Church App - API Documentation

## Base URL
```
Production: https://api.divinelifechurch.com
Development: http://localhost:8000/api
```

## Authentication
All API endpoints require JWT authentication except for login and registration.

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
Accept: application/json
```

## User Roles
- `super_admin` - Full system access
- `branch_admin` - Branch management access  
- `mc_leader` - MC and reports management
- `member` - Basic member access

## Endpoints Overview

### Authentication
```
POST /auth/register
POST /auth/login  
POST /auth/logout
POST /auth/refresh
POST /auth/forgot-password
POST /auth/reset-password
```

### User Management
```
GET /users
GET /users/{id}
PUT /users/{id}
DELETE /users/{id}
POST /users/{id}/change-role
```

### Branches
```
GET /branches
GET /branches/{id}
POST /branches (super_admin only)
PUT /branches/{id}
DELETE /branches/{id}
```

### Missional Communities
```
GET /mcs
GET /mcs/{id}
POST /mcs
PUT /mcs/{id}
DELETE /mcs/{id}
GET /mcs/{id}/members
POST /mcs/{id}/members
DELETE /mcs/{id}/members/{userId}
```

### Reports
```
GET /reports
GET /reports/{id}
POST /reports
PUT /reports/{id}
GET /reports/stats/weekly
GET /reports/stats/monthly
GET /reports/export/pdf
GET /reports/export/excel
```

### Events & Announcements
```
GET /events
GET /events/{id}
POST /events
PUT /events/{id}
DELETE /events/{id}
GET /announcements
POST /announcements
```

### Chat
```
GET /chats/conversations
GET /chats/conversations/{id}/messages
POST /chats/conversations/{id}/messages
POST /chats/conversations
```

### Statistics
```
GET /statistics/dashboard
GET /statistics/mc/{id}
GET /statistics/branch/{id}
GET /statistics/trends
```

## Detailed Endpoint Documentation

### POST /auth/login
Login user and receive JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password"
}
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "mc_leader",
    "branch_id": 1,
    "mc_id": 2
  }
}
```

### POST /reports
Submit weekly MC report.

**Request:**
```json
{
  "mc_id": 1,
  "week_ending": "2024-01-07",
  "members_met": 15,
  "new_members": 2,
  "offerings": 250.50,
  "evangelism_activities": "Street evangelism",
  "comments": "Great week of ministry"
}
```

**Response:**
```json
{
  "id": 123,
  "mc_id": 1,
  "week_ending": "2024-01-07",
  "members_met": 15,
  "new_members": 2,
  "offerings": 250.50,
  "evangelism_activities": "Street evangelism", 
  "comments": "Great week of ministry",
  "status": "pending",
  "submitted_at": "2024-01-08T10:30:00Z"
}
```

### GET /statistics/dashboard
Get dashboard statistics for authenticated user.

**Response:**
```json
{
  "user_role": "mc_leader",
  "mc_stats": {
    "total_members": 25,
    "average_attendance": 18,
    "weekly_growth": 8.5,
    "total_offerings_month": 1250.00
  },
  "recent_reports": [
    {
      "id": 123,
      "week_ending": "2024-01-07", 
      "members_met": 15,
      "status": "approved"
    }
  ],
  "upcoming_events": [
    {
      "id": 45,
      "title": "Branch Meeting",
      "date": "2024-01-15",
      "time": "10:00"
    }
  ]
}
```

## Error Responses
All errors follow this format:

```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE",
    "details": {}
  }
}
```

**HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request  
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Server Error

## WebSocket Events (Chat)
```
join_conversation: {conversation_id}
leave_conversation: {conversation_id}  
new_message: {message_data}
user_typing: {user_id, conversation_id}
message_delivered: {message_id}
message_read: {message_id}
```

## Push Notification Events
```
new_announcement
birthday_reminder
report_approved
report_rejected
new_message
event_reminder
```
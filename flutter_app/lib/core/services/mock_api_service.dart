class MockApiService {
  // Mock data for testing without backend
  static Future<Map<String, dynamic>> testConnection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'message': 'Mock API connection successful!'};
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Mock successful login - return format expected by AuthService
    final validUsers = {
      'admin@test.com': {
        'password': 'password',
        'user': {
          'id': 1,
          'name': 'Super Admin',
          'email': 'admin@test.com',
          'role': 'super_admin',
          'first_name': 'Super',
          'last_name': 'Admin',
          'branch_id': 1,
          'status': 'active',
          'is_approved': true,
        },
      },
      'branch@test.com': {
        'password': 'password',
        'user': {
          'id': 2,
          'name': 'Branch Admin',
          'email': 'branch@test.com',
          'role': 'branch_admin',
          'first_name': 'Branch',
          'last_name': 'Admin',
          'branch_id': 1,
          'status': 'active',
          'is_approved': true,
        },
      },
      'leader@test.com': {
        'password': 'password',
        'user': {
          'id': 3,
          'name': 'MC Leader',
          'email': 'leader@test.com',
          'role': 'mc_leader',
          'first_name': 'MC',
          'last_name': 'Leader',
          'branch_id': 1,
          'mc_id': 1,
          'status': 'active',
          'is_approved': true,
        },
      },
      'member@test.com': {
        'password': 'password',
        'user': {
          'id': 4,
          'name': 'Church Member',
          'email': 'member@test.com',
          'role': 'member',
          'first_name': 'Church',
          'last_name': 'Member',
          'branch_id': 1,
          'mc_id': 1,
          'status': 'active',
          'is_approved': true,
        },
      },
    };

    if (validUsers.containsKey(email) &&
        validUsers[email]!['password'] == password) {
      final userData = validUsers[email]!['user'] as Map<String, dynamic>;
      return {
        'access_token': 'mock_jwt_token_${userData['id']}',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': userData,
      };
    }

    // Return error format expected by AuthService
    return {
      'error': {
        'message': 'Invalid credentials',
        'code': 'INVALID_CREDENTIALS',
      },
    };
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock responses for different endpoints
    switch (endpoint) {
      case '/users':
        return {
          'success': true,
          'data': [
            {
              'id': 1,
              'name': 'John Doe',
              'email': 'john@example.com',
              'role': 'member',
            },
            {
              'id': 2,
              'name': 'Jane Smith',
              'email': 'jane@example.com',
              'role': 'mc_leader',
            },
            {
              'id': 3,
              'name': 'Mike Johnson',
              'email': 'mike@example.com',
              'role': 'branch_admin',
            },
            {
              'id': 4,
              'name': 'Sarah Wilson',
              'email': 'sarah@example.com',
              'role': 'member',
            },
          ],
        };
      case '/branches':
        return {
          'success': true,
          'data': [
            {
              'id': 1,
              'name': 'Main Branch',
              'location': 'City Center',
              'members_count': 125,
            },
            {
              'id': 2,
              'name': 'North Branch',
              'location': 'North District',
              'members_count': 89,
            },
          ],
        };
      case '/reports':
        return {
          'success': true,
          'data': [
            {
              'id': 1,
              'title': 'Weekly Report - Week 42',
              'status': 'approved',
              'mc_name': 'Grace MC',
            },
            {
              'id': 2,
              'title': 'Weekly Report - Week 41',
              'status': 'pending',
              'mc_name': 'Hope MC',
            },
            {
              'id': 3,
              'title': 'Weekly Report - Week 40',
              'status': 'approved',
              'mc_name': 'Faith MC',
            },
          ],
        };
      case '/events':
        return {
          'success': true,
          'data': [
            {
              'id': 1,
              'title': 'Sunday Service',
              'date': '2025-10-27',
              'type': 'service',
            },
            {
              'id': 2,
              'title': 'Youth Conference',
              'date': '2025-11-15',
              'type': 'conference',
            },
            {
              'id': 3,
              'title': 'Prayer Meeting',
              'date': '2025-10-24',
              'type': 'prayer',
            },
          ],
        };
      case '/announcements':
        return {
          'success': true,
          'data': [
            {
              'id': 1,
              'title': 'Welcome New Members',
              'content': 'Please welcome our new members...',
              'priority': 'high',
            },
            {
              'id': 2,
              'title': 'Upcoming Events',
              'content': 'Don\'t miss these upcoming events...',
              'priority': 'medium',
            },
          ],
        };
      case '/mcs':
        return {
          'success': true,
          'data': [
            {
              'id': 1,
              'name': 'Grace MC',
              'leader': 'John Doe',
              'members_count': 15,
            },
            {
              'id': 2,
              'name': 'Hope MC',
              'leader': 'Jane Smith',
              'members_count': 12,
            },
            {
              'id': 3,
              'name': 'Faith MC',
              'leader': 'Mike Johnson',
              'members_count': 18,
            },
          ],
        };
      case '/users/statistics':
        return {
          'success': true,
          'statistics': {
            'total_users': 245,
            'approved_users': 220,
            'pending_users': 15,
            'recent_registrations': 12,
            'by_role': {
              'super_admin': 2,
              'branch_admin': 8,
              'mc_leader': 25,
              'member': 210,
            },
            'by_branch': {
              'Main Branch': 145,
              'North Branch': 75,
              'South Branch': 25,
            },
          },
        };
      case '/reports/statistics':
        return {
          'success': true,
          'statistics': {
            'total_reports': 156,
            'by_status': {'approved': 142, 'pending': 12, 'rejected': 2},
            'this_week': 28,
            'last_week': 31,
            'completion_rate': 87.5,
            'avg_attendance': 245,
            'total_new_converts': 15,
            'total_visitors': 89,
          },
        };
      default:
        return {'success': true, 'data': []};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {'success': true, 'message': 'Operation completed successfully'};
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {'success': true, 'message': 'Updated successfully'};
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {'success': true, 'message': 'Deleted successfully'};
  }
}

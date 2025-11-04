import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:logger/logger.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static final Logger _logger = Logger();

  // User roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleBranchAdmin = 'branch_admin';
  static const String roleMCLeader = 'mc_leader';
  static const String roleMember = 'member';

  // Login user
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.login(email, password);

      // Check if the response contains access_token (successful login)
      if (response['access_token'] != null) {
        final token = response['access_token'];
        final user = response['user'];

        // Save tokens
        await StorageService.saveAuthToken(token);
        // If backend provided a refresh token on login, persist it too
        if (response['refresh_token'] != null) {
          await StorageService.saveRefreshToken(response['refresh_token']);
        } else if (response['data'] is Map &&
            response['data']['refresh_token'] != null) {
          await StorageService.saveRefreshToken(
            response['data']['refresh_token'],
          );
        }

        // Save user data
        await StorageService.saveUserData(user);

        _logger.i('User logged in successfully: ${user['email']}');

        // Return standardized response
        return {
          'success': true,
          'message': 'Login successful',
          'data': {'token': token, 'user': user},
        };
      } else if (response['error'] != null) {
        throw response['error']['message'] ?? 'Login failed';
      } else {
        throw 'Login failed';
      }
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  // Register user
  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await ApiService.register(userData);

      // Check if the response contains a success message
      if (response['message'] != null && response['user'] != null) {
        _logger.i('User registered successfully: ${userData['email']}');
        return {
          'success': true,
          'message': response['message'],
          'data': {'user': response['user']},
        };
      } else if (response['error'] != null) {
        throw response['error']['message'] ?? 'Registration failed';
      } else {
        throw 'Registration failed';
      }
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      // Call API logout
      await ApiService.logout();

      // Clear local data
      await StorageService.clearAuthTokens();
      await StorageService.clearUserData();

      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Logout error: $e');
      // Still clear local data even if API call fails
      await StorageService.clearAuthTokens();
      await StorageService.clearUserData();
    }
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    final token = StorageService.getAuthToken();
    if (token == null) return false;

    try {
      // Check if token is expired
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      _logger.w('Error checking token: $e');
      return false;
    }
  }

  // Get current user data
  static Map<String, dynamic>? getCurrentUser() {
    return StorageService.getUserData();
  }

  // Get current user role
  static String? getCurrentUserRole() {
    final user = getCurrentUser();
    return user?['role'];
  }

  // Get current user ID
  static int? getCurrentUserId() {
    final user = getCurrentUser();
    return user?['id'];
  }

  // Role checking methods
  static bool isSuperAdmin() {
    return getCurrentUserRole() == roleSuperAdmin;
  }

  static bool isBranchAdmin() {
    return getCurrentUserRole() == roleBranchAdmin;
  }

  static bool isMCLeader() {
    return getCurrentUserRole() == roleMCLeader;
  }

  static bool isMember() {
    return getCurrentUserRole() == roleMember;
  }

  // Check if user has permission for specific actions
  static bool canManageUsers() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  static bool canManageBranches() {
    return getCurrentUserRole() == roleSuperAdmin;
  }

  static bool canManageMCs() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  static bool canCreateReports() {
    // Only MC Leaders, Branch Admins, and Super Admins can create reports
    final role = getCurrentUserRole();
    return role == roleSuperAdmin ||
        role == roleBranchAdmin ||
        role == roleMCLeader;
  }

  static bool canApproveReports() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
    // MC Leaders can only submit reports, not approve them
  }

  static bool canManageEvents() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  static bool canManageAnnouncements() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  static bool canManageSermons() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  static bool canManageOnlineServices() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  static bool canManageGiving() {
    final role = getCurrentUserRole();
    return role == roleSuperAdmin || role == roleBranchAdmin;
  }

  // Refresh token
  static Future<bool> refreshAuthToken() async {
    try {
      final response = await ApiService.refreshToken();

      if (response['success'] == true) {
        final newToken = response['data']['token'];
        final newRefreshToken = response['data']['refresh_token'];

        await StorageService.saveAuthToken(newToken);
        if (newRefreshToken != null) {
          await StorageService.saveRefreshToken(newRefreshToken);
        }

        _logger.i('Token refreshed successfully');
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
    }

    return false;
  }

  // Auto-refresh token if needed
  static Future<bool> ensureValidToken() async {
    final token = StorageService.getAuthToken();
    if (token == null) return false;

    try {
      // Check if token will expire in the next 5 minutes
      final timeToExpiry = JwtDecoder.getRemainingTime(token);
      if (timeToExpiry.inMinutes <= 5) {
        return await refreshAuthToken();
      }
      return true;
    } catch (e) {
      _logger.w('Error checking token expiry: $e');
      return await refreshAuthToken();
    }
  }

  // Get user's branch ID
  static int? getCurrentUserBranchId() {
    final user = getCurrentUser();
    return user?['branch_id'];
  }

  // Get user's MC ID (if they're a member)
  static int? getCurrentUserMCId() {
    final user = getCurrentUser();
    return user?['mc_id'];
  }

  // Get user's full name
  static String getCurrentUserName() {
    final user = getCurrentUser();
    if (user == null) return 'Unknown User';

    // Preferred: first_name + last_name
    final firstName = user['first_name'] ?? user['firstName'] ?? '';
    final lastName = user['last_name'] ?? user['lastName'] ?? '';
    final combined = ('$firstName $lastName').trim();
    if (combined.isNotEmpty) return combined;

    // Fallbacks: single 'name' or 'full_name' or 'display_name'
    final nameFallback =
        user['name'] ?? user['full_name'] ?? user['display_name'];
    if (nameFallback is String && nameFallback.isNotEmpty) return nameFallback;

    // Last resort: email username or Unknown
    final email = user['email'] as String?;
    if (email != null && email.contains('@')) return email.split('@').first;

    return 'Unknown User';
  }

  // Get user's gender (flexible to multiple possible backend keys)
  static String? getCurrentUserGender() {
    final user = getCurrentUser();
    if (user == null) return null;

    final gender =
        user['gender'] ?? user['sex'] ?? user['genders'] ?? user['gender_id'];
    if (gender == null) return null;
    if (gender is String) return gender;
    // If backend returns numeric codes, convert to string
    return gender.toString();
  }

  // Get user's email
  static String? getCurrentUserEmail() {
    final user = getCurrentUser();
    return user?['email'];
  }

  // Update current user data
  static Future<void> updateCurrentUser(Map<String, dynamic> userData) async {
    await StorageService.saveUserData(userData);
  }

  // Check if user needs approval
  static bool isUserPendingApproval() {
    final user = getCurrentUser();
    return user?['status'] == 'pending';
  }

  // Check if user is active
  static bool isUserActive() {
    final user = getCurrentUser();
    return user?['status'] == 'active';
  }
}

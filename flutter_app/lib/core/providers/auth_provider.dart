import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  // Authentication state
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // User properties
  String get userName => AuthService.getCurrentUserName();
  String? get userEmail => AuthService.getCurrentUserEmail();
  String? get userGender => AuthService.getCurrentUserGender();
  String? get userRole => AuthService.getCurrentUserRole();
  int? get userId => AuthService.getCurrentUserId();
  int? get userBranchId => AuthService.getCurrentUserBranchId();
  int? get userMCId => AuthService.getCurrentUserMCId();

  // User data getter for profile screen compatibility
  Map<String, dynamic>? get userData => _currentUser;

  // Role checking
  bool get isSuperAdmin => AuthService.isSuperAdmin();
  bool get isBranchAdmin => AuthService.isBranchAdmin();
  bool get isMCLeader => AuthService.isMCLeader();
  bool get isMember => AuthService.isMember();

  // Permission checking
  bool get canManageUsers => AuthService.canManageUsers();
  bool get canManageBranches => AuthService.canManageBranches();
  bool get canManageMCs => AuthService.canManageMCs();
  bool get canCreateReports => AuthService.canCreateReports();
  bool get canApproveReports => AuthService.canApproveReports();
  bool get canManageEvents => AuthService.canManageEvents();
  bool get canManageAnnouncements => AuthService.canManageAnnouncements();
  bool get canManageSermons => AuthService.canManageSermons();
  bool get canManageOnlineServices => AuthService.canManageOnlineServices();
  bool get canManageGiving => AuthService.canManageGiving();

  // User status
  bool get isUserPendingApproval => AuthService.isUserPendingApproval();
  bool get isUserActive => AuthService.isUserActive();

  // Initialize authentication state
  Future<void> initialize() async {
    try {
      setLoading(true);

      // Check if user is already authenticated
      if (AuthService.isAuthenticated()) {
        _currentUser = AuthService.getCurrentUser();
        _isAuthenticated = true;

        // Ensure token is valid and refresh if needed
        final isValid = await AuthService.ensureValidToken();
        if (!isValid) {
          await logout();
        }

        _logger.i('User authentication restored');
      } else {
        _logger.i('No authenticated user found');
      }
    } catch (e) {
      _logger.e('Error initializing authentication: $e');
      await logout(); // Clear invalid state
    } finally {
      setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    try {
      setLoading(true);
      clearError();

      final response = await AuthService.login(email, password);

      if (response['success'] == true) {
        _currentUser = response['data']['user'];
        _isAuthenticated = true;

        _logger.i('User logged in: ${_currentUser!['email']}');
        notifyListeners();
        return true;
      } else {
        setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _logger.e('Login error: $e');
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Register
  Future<bool> register(Map<String, dynamic> userData) async {
    try {
      setLoading(true);
      clearError();

      final response = await AuthService.register(userData);

      if (response['success'] == true) {
        _logger.i('User registered: ${userData['email']}');
        // Don't auto-login after registration, user needs approval
        return true;
      } else {
        setError(response['message'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _logger.e('Registration error: $e');
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      setLoading(true);

      await AuthService.logout();

      _currentUser = null;
      _isAuthenticated = false;
      clearError();

      _logger.i('User logged out');
      notifyListeners();
    } catch (e) {
      _logger.e('Logout error: $e');
      // Still clear local state even if API call fails
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  // Update current user data
  Future<void> updateUser(Map<String, dynamic> userData) async {
    try {
      _currentUser = userData;
      await AuthService.updateCurrentUser(userData);
      notifyListeners();
      _logger.i('User data updated');
    } catch (e) {
      _logger.e('Error updating user data: $e');
    }
  }

  // Refresh authentication
  Future<bool> refreshAuth() async {
    try {
      final success = await AuthService.refreshAuthToken();
      if (success) {
        _logger.i('Authentication refreshed');
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      _logger.e('Error refreshing authentication: $e');
      await logout();
      return false;
    }
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    switch (permission) {
      case 'manage_users':
        return canManageUsers;
      case 'manage_branches':
        return canManageBranches;
      case 'manage_mcs':
        return canManageMCs;
      case 'create_reports':
        return canCreateReports;
      case 'approve_reports':
        return canApproveReports;
      case 'manage_events':
        return canManageEvents;
      case 'manage_announcements':
        return canManageAnnouncements;
      default:
        return false;
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Get role display name
  String getRoleDisplayName() {
    switch (userRole) {
      case 'super_admin':
        return 'Super Admin';
      case 'branch_admin':
        return 'Branch Admin';
      case 'mc_leader':
        return 'MC Leader';
      case 'member':
        return 'Member';
      default:
        return 'Unknown';
    }
  }

  // Get user status display
  String getUserStatusDisplay() {
    if (isUserPendingApproval) {
      return 'Pending Approval';
    } else if (isUserActive) {
      return 'Active';
    } else {
      return 'Inactive';
    }
  }
}

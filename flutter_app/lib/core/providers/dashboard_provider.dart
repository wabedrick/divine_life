import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../services/api_service.dart';
import '../services/sermon_service.dart';
import '../models/announcement_model.dart';
import '../models/sermon.dart';
import '../models/social_media_post.dart';
import 'auth_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AuthProvider _authProvider;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _errorMessage;

  // Dashboard statistics
  Map<String, dynamic>? _userStatistics;
  Map<String, dynamic>? _reportStatistics;
  int _totalBranches = 0;
  int _totalMCs = 0;
  int _totalMCMembers = 0;
  int _totalEvents = 0;
  int _totalAnnouncements = 0;
  List<AnnouncementModel> _recentAnnouncements = [];
  List<Sermon> _featuredSermons = [];
  List<SocialMediaPost> _latestTikTokPosts = [];

  DashboardProvider(this._authProvider);

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingStats => _isLoadingStats;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get userStatistics => _userStatistics;
  Map<String, dynamic>? get reportStatistics => _reportStatistics;
  int get totalBranches => _totalBranches;
  int get totalMCs => _totalMCs;
  int get totalMCMembers => _totalMCMembers;
  int get totalEvents => _totalEvents;
  int get totalAnnouncements => _totalAnnouncements;
  List<AnnouncementModel> get recentAnnouncements => _recentAnnouncements;
  List<Sermon> get featuredSermons => _featuredSermons;
  List<SocialMediaPost> get latestTikTokPosts => _latestTikTokPosts;

  // Computed getters for user stats
  int get totalUsers => _userStatistics?['statistics']?['total_users'] ?? 0;
  int get approvedUsers =>
      _userStatistics?['statistics']?['approved_users'] ?? 0;
  int get pendingUsers => _userStatistics?['statistics']?['pending_users'] ?? 0;
  int get recentRegistrations =>
      _userStatistics?['statistics']?['recent_registrations'] ?? 0;

  // Computed getters for report stats
  int get totalReports =>
      _reportStatistics?['statistics']?['total_reports'] ?? 0;
  int get approvedReports =>
      _reportStatistics?['statistics']?['by_status']?['approved'] ?? 0;
  int get pendingReports =>
      _reportStatistics?['statistics']?['by_status']?['pending'] ?? 0;
  int get rejectedReports =>
      _reportStatistics?['statistics']?['by_status']?['rejected'] ?? 0;

  // Week period information getters
  String get reportsPeriodText =>
      _reportStatistics?['statistics']?['period']?['display_text'] ??
      'Current Week';
  bool get reportsIsSingleWeek =>
      _reportStatistics?['statistics']?['period']?['is_single_week'] ?? true;
  String get reportsPeriodType =>
      _reportStatistics?['statistics']?['period']?['type'] ?? 'current_week';
  String get reportsPeriodStartDate =>
      _reportStatistics?['statistics']?['period']?['start_date'] ?? '';
  String get reportsPeriodEndDate =>
      _reportStatistics?['statistics']?['period']?['end_date'] ?? '';

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load all data in parallel for better performance
      await Future.wait([
        _loadUserStatistics(),
        _loadReportStatistics(),
        _loadBranchCount(),
        _loadMCCount(),
        _loadMCMembersCount(),
        _loadEventCount(),
        _loadAnnouncementCount(),
        _loadRecentAnnouncements(),
        _loadFeaturedSermons(),
        _loadLatestTikTokPost(),
      ]);

      _logger.i('Dashboard data loaded successfully');
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Failed to load dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load only statistics (lighter refresh)
  Future<void> refreshStatistics() async {
    if (_isLoadingStats) return;

    _isLoadingStats = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([_loadUserStatistics(), _loadReportStatistics()]);

      _logger.i('Dashboard statistics refreshed');
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Failed to refresh statistics: $e');
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Load user statistics (role-based)
  Future<void> _loadUserStatistics() async {
    try {
      final currentUser = _authProvider.currentUser;
      final userRole = currentUser?['role'] as String?;

      // Admin roles get full statistics, members get basic dashboard
      if (userRole == 'super_admin' || userRole == 'branch_admin') {
        _userStatistics = await ApiService.getUserStatistics();
      } else {
        // For members, load member dashboard data
        final memberData = await ApiService.getMemberDashboard();
        _userStatistics = {'dashboard': memberData['dashboard']};
      }
    } catch (e) {
      _logger.e('Failed to load user statistics: $e');
      rethrow;
    }
  }

  /// Load report statistics
  Future<void> _loadReportStatistics() async {
    try {
      _reportStatistics = await ApiService.getReportStatistics();
    } catch (e) {
      _logger.e('Failed to load report statistics: $e');
      rethrow;
    }
  }

  /// Load branch count
  Future<void> _loadBranchCount() async {
    try {
      final response = await ApiService.getBranches();
      final branches =
          response['branches'] as List? ?? response['data'] as List? ?? [];
      _totalBranches = branches.length;
    } catch (e) {
      _logger.e('Failed to load branch count: $e');
      rethrow;
    }
  }

  /// Load MC count
  Future<void> _loadMCCount() async {
    try {
      final response = await ApiService.getMCs();
      final mcs = response['mcs'] as List? ?? response['data'] as List? ?? [];
      _totalMCs = mcs.length;
    } catch (e) {
      _logger.e('Failed to load MC count: $e');
      rethrow;
    }
  }

  /// Load MC members count for current user's MC
  Future<void> _loadMCMembersCount() async {
    try {
      final mcId = _authProvider.userMCId;
      if (mcId != null) {
        final response = await ApiService.getMC(mcId);
        final mcData = response['mc'];
        final members = mcData['members'] as List? ?? [];
        _totalMCMembers = members.length;
      } else {
        _totalMCMembers = 0;
      }
    } catch (e) {
      _logger.e('Failed to load MC members count: $e');
      _totalMCMembers = 0; // Don't rethrow for non-critical data
    }
  }

  /// Load event count
  Future<void> _loadEventCount() async {
    try {
      final response = await ApiService.getEvents();
      final events =
          response['events'] as List? ?? response['data'] as List? ?? [];
      _totalEvents = events.length;
    } catch (e) {
      _logger.e('Failed to load event count: $e');
      rethrow;
    }
  }

  /// Load announcement count
  Future<void> _loadAnnouncementCount() async {
    try {
      final response = await ApiService.getAnnouncements();
      final announcements =
          response['announcements'] as List? ?? response['data'] as List? ?? [];
      _totalAnnouncements = announcements.length;
    } catch (e) {
      _logger.e('Failed to load announcement count: $e');
      rethrow;
    }
  }

  /// Load the latest announcements (for dashboard preview)
  Future<void> _loadRecentAnnouncements({int limit = 2}) async {
    try {
      // Use the announcements index endpoint to always get the latest added
      // regardless of the 'recent' time-window filter used by /announcements/recent
      final response = await ApiService.get(
        '/announcements',
        queryParameters: {
          'per_page': limit,
          'sort_by': 'created_at',
          'sort_order': 'desc',
        },
      );

      // Normalize response shape: ApiService.get() returns a Map. The
      // controller typically returns { 'announcements': [..], 'pagination': {...} }
      // but guard for alternative shapes.
      List<dynamic> items = [];
      final resp = response;
      final a = resp['announcements'];
      final d = resp['data'];

      if (a is List) {
        items = a;
      } else if (d is List) {
        items = d;
      } else if (response is List) {
        // defensive fallback in case the underlying API helper returns a list
        items = response as List<dynamic>;
      } else {
        items = [];
      }

      _recentAnnouncements = items
          .where((e) => e is Map || e is Map<String, dynamic>)
          .take(limit)
          .map(
            (e) =>
                AnnouncementModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e) {
      _logger.e('Failed to load recent announcements: $e');
      // don't rethrow - dashboard should still load other data
      _recentAnnouncements = [];
    }
  }

  /// Load featured/latest sermons for dashboard preview
  Future<void> _loadFeaturedSermons({int limit = 2}) async {
    try {
      final sermons = await SermonService.getFeaturedSermons(limit: limit);
      _featuredSermons = sermons;
    } catch (e) {
      _logger.e('Failed to load featured sermons: $e');
      _featuredSermons = [];
    }
  }

  /// Load latest TikTok posts
  Future<void> _loadLatestTikTokPost() async {
    try {
      final response = await SermonService.getSocialMediaPosts(
        platform: 'tiktok',
        perPage: 2,
      );
      final posts = response['posts'] as List<SocialMediaPost>? ?? [];
      _latestTikTokPosts = posts.take(2).toList();
      _logger.d('Loaded TikTok posts: ${_latestTikTokPosts.length}');
    } catch (e) {
      _logger.e('Failed to load latest TikTok posts: $e');
      _latestTikTokPosts = [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset all data
  void reset() {
    _isLoading = false;
    _isLoadingStats = false;
    _errorMessage = null;
    _userStatistics = null;
    _reportStatistics = null;
    _totalBranches = 0;
    _totalMCs = 0;
    _totalEvents = 0;
    _totalAnnouncements = 0;
    _latestTikTokPosts = [];
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/connectivity_service.dart';

class AppStateProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  // Loading states
  bool _isLoading = false;
  bool _isInitialized = false;

  // Connectivity
  bool _isOnline = true;

  // Theme
  ThemeMode _themeMode = ThemeMode.system;

  // Language
  String _language = 'en';

  // Navigation
  int _currentPageIndex = 0;

  // Error handling
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  int get currentPageIndex => _currentPageIndex;
  String? get errorMessage => _errorMessage;

  // Initialize app state
  Future<void> initialize() async {
    try {
      _isLoading = true;

      // Initialize connectivity service
      await ConnectivityService.init();

      // Listen to connectivity changes
      ConnectivityService.connectivityStream.listen((isConnected) {
        setOnlineStatus(isConnected);
      });

      // Set initial connectivity status
      setOnlineStatus(ConnectivityService.isOnline);

      // Load saved preferences
      await _loadPreferences();

      _isInitialized = true;
      _logger.i('App state initialized successfully');
    } catch (e) {
      _logger.e('Error initializing app state: $e');
      setError('Failed to initialize app');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    // TODO: Load theme, language, and other preferences from storage
    // For now, using defaults
  }

  // Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Set online status
  void setOnlineStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _logger.i(
        'Connectivity status changed: ${online ? "Online" : "Offline"}',
      );
      notifyListeners();
    }
  }

  // Set theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      // TODO: Save to storage
      notifyListeners();
    }
  }

  // Set language
  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      // TODO: Save to storage
      notifyListeners();
    }
  }

  // Set current page index
  void setCurrentPageIndex(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
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

  // Show error temporarily
  void showTempError(
    String error, {
    Duration duration = const Duration(seconds: 5),
  }) {
    setError(error);
    Future.delayed(duration, () {
      if (_errorMessage == error) {
        clearError();
      }
    });
  }

  @override
  void dispose() {
    ConnectivityService.dispose();
    super.dispose();
  }
}

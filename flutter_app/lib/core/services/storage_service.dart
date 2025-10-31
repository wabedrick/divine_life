import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late Box _userBox;
  static late Box _settingsBox;
  static late SharedPreferences _prefs;

  // Box names
  static const String userBoxName = 'user_box';
  static const String settingsBoxName = 'settings_box';

  // Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_completed';

  static Future<void> init() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Open Hive boxes
    _userBox = await Hive.openBox(userBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);
  }

  // Auth token methods
  static Future<void> saveAuthToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  static String? getAuthToken() {
    return _prefs.getString(tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(refreshTokenKey, token);
  }

  static String? getRefreshToken() {
    return _prefs.getString(refreshTokenKey);
  }

  static Future<void> clearAuthTokens() async {
    await _prefs.remove(tokenKey);
    await _prefs.remove(refreshTokenKey);
  }

  // User data methods
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _userBox.put(userKey, userData);
  }

  static Map<String, dynamic>? getUserData() {
    return _userBox.get(userKey)?.cast<String, dynamic>();
  }

  static Future<void> clearUserData() async {
    await _userBox.delete(userKey);
  }

  // Settings methods
  static Future<void> saveThemeMode(String themeMode) async {
    await _settingsBox.put(themeKey, themeMode);
  }

  static String? getThemeMode() {
    return _settingsBox.get(themeKey);
  }

  static Future<void> saveLanguage(String language) async {
    await _settingsBox.put(languageKey, language);
  }

  static String? getLanguage() {
    return _settingsBox.get(languageKey);
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(onboardingKey, completed);
  }

  static bool isOnboardingCompleted() {
    return _prefs.getBool(onboardingKey) ?? false;
  }

  // Cache methods for offline support
  static Future<void> cacheData(String key, dynamic data) async {
    await _settingsBox.put(key, data);
  }

  static T? getCachedData<T>(String key) {
    return _settingsBox.get(key) as T?;
  }

  static Future<void> clearCache() async {
    await _settingsBox.clear();
  }

  // Clear all data (logout)
  static Future<void> clearAll() async {
    await clearAuthTokens();
    await clearUserData();
    await _userBox.clear();
    // Keep settings but clear sensitive data
  }
}

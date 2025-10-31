import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'storage_service.dart';
import 'mock_api_service.dart';

class ApiService {
  static late Dio _dio;
  static late Logger _logger;

  // Mock mode for development when backend is not available
  static const bool _useMockData = false; // Real backend is now working
  static const bool _enableFallbackToMock =
      false; // DISABLE fallback to mock - use real DB only

  // Base configuration
  // Use 10.0.2.2 for Android emulator, localhost for desktop/web
  // ignore: unused_field
  static const String _androidEmulator =
      'http://10.0.2.2:8000/api'; // Android emulator
  // ignore: unused_field
  static const String _localhost = 'http://127.0.0.1:8000/api'; // Localhost
  static const String _ipAddress =
      'http://192.168.42.41:8000/api'; // Current server IP address

  // Configuration for API endpoint
  static String get baseUrl {
    // Use IP address for physical Android device
    return _ipAddress;
  }

  static const int connectTimeout =
      30000; // 30 seconds - increased for slower connections
  static const int receiveTimeout =
      60000; // 60 seconds - increased for complex queries

  static void init() {
    _logger = Logger();

    _logger.i('Initializing ApiService with baseUrl: $baseUrl');

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          final token = StorageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Data: ${options.data}');

          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          _logger.d('Data: ${response.data}');

          handler.next(response);
        },
        onError: (error, handler) async {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          _logger.e('Message: ${error.message}');
          _logger.e('Data: ${error.response?.data}');
          _logger.e('Error Type: ${error.type}');
          _logger.e('Request URL: ${error.requestOptions.uri}');
          _logger.e('Request Headers: ${error.requestOptions.headers}');
          _logger.e('Request Data: ${error.requestOptions.data}');

          // If unauthorized, attempt a single token refresh and retry the request
          try {
            final statusCode = error.response?.statusCode;
            final requestOptions = error.requestOptions;

            // Only attempt a refresh if we have a refresh token and we haven't retried yet
            final hasRetried = requestOptions.extra['retried'] == true;
            final storedRefresh = StorageService.getRefreshToken();

            if (statusCode == 401 && !hasRetried) {
              if (storedRefresh == null) {
                _logger.w(
                  '401 received but no refresh token available — clearing auth tokens',
                );
                // Ensure local tokens are cleared so app can redirect to login
                await StorageService.clearAuthTokens();
                // Forward original error without trying refresh
              } else {
                _logger.w('401 detected - attempting token refresh');

                try {
                  final refreshData = await ApiService.refreshToken();
                  final newToken =
                      refreshData['access_token'] ?? refreshData['token'];

                  if (newToken != null) {
                    // Save and set header
                    await StorageService.saveAuthToken(newToken);
                    requestOptions.headers['Authorization'] =
                        'Bearer $newToken';
                    requestOptions.extra['retried'] = true;

                    // Retry the original request
                    final opts = Options(
                      method: requestOptions.method,
                      headers: requestOptions.headers,
                    );
                    final response = await _dio.request(
                      requestOptions.path,
                      options: opts,
                      data: requestOptions.data,
                      queryParameters: requestOptions.queryParameters,
                    );

                    _logger.i('Retried request after refresh successful');
                    return handler.resolve(response);
                  } else {
                    _logger.w('Refresh did not return a new token');
                    // Clear tokens to force re-authentication
                    await StorageService.clearAuthTokens();
                  }
                } catch (refreshError) {
                  _logger.w('Token refresh failed: $refreshError');
                  // Clear tokens after failed refresh so the app can re-login
                  await StorageService.clearAuthTokens();
                }
              }
            }
          } catch (e) {
            _logger.e('Error in onError interceptor retry logic: $e');
          }

          handler.next(error);
        },
      ),
    );
  }

  // Reinitialize with new base URL (for debugging)
  static void reinit() {
    _logger.w('Reinitializing ApiService...');
    init();
  }

  // Get current configuration info
  static Map<String, dynamic> getConfig() {
    return {
      'baseUrl': baseUrl,
      'currentDioBaseUrl': _dio.options.baseUrl,
      'connectTimeout': connectTimeout,
      'receiveTimeout': receiveTimeout,
    };
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    if (_useMockData) {
      return await MockApiService.login(email, password);
    }

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      // Reset on successful connection
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError && _enableFallbackToMock) {
        _logger.w('Login connection failed, falling back to mock data');
        return await MockApiService.login(email, password);
      }
      // Provide a more user-friendly message for authentication failures
      if (e.response?.statusCode == 401) {
        _logger.w('Login failed: incorrect credentials');
        throw 'Incorrect email or password';
      }

      // Always throw error when real database is required
      _logger.e('Login failed - real backend required: ${_handleError(e)}');
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
    try {
      // First test a simple GET request to verify connectivity
      _logger.i('Testing connectivity before registration...');
      final testResponse = await _dio.get('/test');
      _logger.i('Connectivity test successful: ${testResponse.data}');

      // Now try the registration
      _logger.i('Attempting registration with data: $userData');
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } on DioException catch (e) {
      _logger.e('Registration failed with DioException: ${e.type}');
      _logger.e('Error message: ${e.message}');
      _logger.e('Error response: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = StorageService.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return response.data;
    } on DioException catch (e) {
      // If refresh failed with 401, clear stored tokens to force re-login
      if (e.response?.statusCode == 401) {
        await StorageService.clearAuthTokens();
      }
      throw _handleError(e);
    }
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      _logger.w('Logout error: ${e.message}');
      // Continue with local logout even if server logout fails
    }
  }

  // Test connectivity
  static Future<Map<String, dynamic>> testConnection() async {
    if (_useMockData) {
      return await MockApiService.testConnection();
    }

    try {
      _logger.i('Testing connection to: $baseUrl/test');
      final response = await _dio.get('/test');
      _logger.i('✅ Real API connection successful');
      // Reset on success
      return response.data;
    } on DioException catch (e) {
      if (_enableFallbackToMock) {
        _logger.w(
          '⚠️ API connection failed, switching to mock data: ${e.type}',
        );
        // Enable fallback mode
        return await MockApiService.testConnection();
      } else {
        // Force use of real backend only
        _logger.e('❌ Real backend connection required but failed: ${e.type}');
        // Don't enable fallback
        throw Exception(
          'Real backend connection required but failed: ${e.type}',
        );
      }
    }
  }

  // Generic CRUD operations
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_useMockData) {
      return await MockApiService.get(
        endpoint,
        queryParameters: queryParameters,
      );
    }

    return await _retryRequest(() async {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      // Reset on successful connection
      return response.data;
    }, endpoint);
  }

  // GET method for endpoints that return arrays/lists
  static Future<List<dynamic>> getList(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_useMockData) {
      // Handle mock data case - for now return empty list
      return [];
    }

    return await _retryListRequest(() async {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data as List<dynamic>;
    }, endpoint);
  }

  // Retry logic for timeout and connection errors
  static Future<Map<String, dynamic>> _retryRequest(
    Future<Map<String, dynamic>> Function() request,
    String endpoint,
  ) async {
    int maxRetries = 2;
    int currentAttempt = 0;

    while (currentAttempt < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        currentAttempt++;

        // Retry on timeout or connection errors, but not on other errors
        bool shouldRetry =
            currentAttempt < maxRetries &&
            (e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.connectionError);

        if (shouldRetry) {
          _logger.w(
            'Request failed (attempt $currentAttempt/$maxRetries), retrying in 2 seconds...',
          );
          await Future.delayed(Duration(seconds: 2));
          continue;
        }

        // Handle fallback for connection errors if enabled
        if (e.type == DioExceptionType.connectionError &&
            _enableFallbackToMock) {
          _logger.w('Connection failed, falling back to mock data');
          return await MockApiService.get(endpoint);
        }

        // Force real backend usage - no more retries
        _logger.e(
          'Real backend API call failed for $endpoint: ${_handleError(e)}',
        );
        throw _handleError(e);
      }
    }

    throw 'Maximum retries exceeded';
  }

  // Retry logic for List requests
  static Future<List<dynamic>> _retryListRequest(
    Future<List<dynamic>> Function() request,
    String endpoint,
  ) async {
    int maxRetries = 2;
    int currentAttempt = 0;

    while (currentAttempt < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        currentAttempt++;

        // Retry on timeout or connection errors, but not on other errors
        bool shouldRetry =
            currentAttempt < maxRetries &&
            (e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.connectionError);

        if (shouldRetry) {
          _logger.w(
            'List request failed (attempt $currentAttempt/$maxRetries), retrying in 2 seconds...',
          );
          await Future.delayed(Duration(seconds: 2));
          continue;
        }

        // Handle fallback for connection errors if enabled
        if (e.type == DioExceptionType.connectionError &&
            _enableFallbackToMock) {
          _logger.w('List request connection failed, returning empty list');
          return [];
        }

        // Force real backend usage - no more retries
        _logger.e(
          'Real backend API list call failed for $endpoint: ${_handleError(e)}',
        );
        throw _handleError(e);
      }
    }

    throw 'Maximum retries exceeded';
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
  }) async {
    if (_useMockData) {
      return await MockApiService.post(endpoint, data: data);
    }

    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
  }) async {
    if (_useMockData) {
      return await MockApiService.put(endpoint, data: data);
    }

    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    if (_useMockData) {
      return await MockApiService.delete(endpoint);
    }

    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Specific API endpoints

  // Users
  static Future<Map<String, dynamic>> getUsers({
    Map<String, dynamic>? filters,
  }) async {
    return get('/users', queryParameters: filters);
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> userData,
  ) async {
    return post('/users', data: userData);
  }

  static Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    return put('/users/$userId', data: userData);
  }

  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    return delete('/users/$userId');
  }

  // Branches
  static Future<Map<String, dynamic>> getBranches() async {
    return get('/branches');
  }

  // Public branches for registration (no auth required)
  static Future<Map<String, dynamic>> getPublicBranches() async {
    return get('/branches/public');
  }

  static Future<Map<String, dynamic>> getBranch(int branchId) async {
    return get('/branches/$branchId');
  }

  static Future<Map<String, dynamic>> createBranch(
    Map<String, dynamic> branchData,
  ) async {
    return post('/branches', data: branchData);
  }

  static Future<Map<String, dynamic>> updateBranch(
    int branchId,
    Map<String, dynamic> branchData,
  ) async {
    return put('/branches/$branchId', data: branchData);
  }

  static Future<Map<String, dynamic>> deleteBranch(int branchId) async {
    return delete('/branches/$branchId');
  }

  // MCs (Missional Communities)
  static Future<Map<String, dynamic>> getMCs({int? branchId}) async {
    return get(
      '/mcs',
      queryParameters: branchId != null ? {'branch_id': branchId} : null,
    );
  }

  static Future<Map<String, dynamic>> getMC(int mcId) async {
    return get('/mcs/$mcId');
  }

  static Future<Map<String, dynamic>> createMC(
    Map<String, dynamic> mcData,
  ) async {
    return post('/mcs', data: mcData);
  }

  static Future<Map<String, dynamic>> updateMC(
    int mcId,
    Map<String, dynamic> mcData,
  ) async {
    return put('/mcs/$mcId', data: mcData);
  }

  static Future<Map<String, dynamic>> deleteMC(int mcId) async {
    return delete('/mcs/$mcId');
  }

  static Future<Map<String, dynamic>> addMCMember(int mcId, int userId) async {
    return post('/mcs/$mcId/members', data: {'user_id': userId});
  }

  static Future<Map<String, dynamic>> removeMCMember(
    int mcId,
    int userId,
  ) async {
    return delete('/mcs/$mcId/members/$userId');
  }

  // Reports
  static Future<Map<String, dynamic>> getReports({
    Map<String, dynamic>? filters,
  }) async {
    return get('/reports', queryParameters: filters);
  }

  static Future<Map<String, dynamic>> getReport(int reportId) async {
    return get('/reports/$reportId');
  }

  static Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> reportData,
  ) async {
    return post('/reports', data: reportData);
  }

  static Future<Map<String, dynamic>> updateReport(
    int reportId,
    Map<String, dynamic> reportData,
  ) async {
    return put('/reports/$reportId', data: reportData);
  }

  static Future<Map<String, dynamic>> approveReport(int reportId) async {
    return post('/reports/$reportId/approve');
  }

  static Future<Map<String, dynamic>> rejectReport(
    int reportId,
    String reason,
  ) async {
    return post('/reports/$reportId/reject', data: {'reason': reason});
  }

  // Events
  static Future<Map<String, dynamic>> getEvents({
    Map<String, dynamic>? filters,
  }) async {
    return get('/events', queryParameters: filters);
  }

  static Future<Map<String, dynamic>> getEvent(int eventId) async {
    return get('/events/$eventId');
  }

  static Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> eventData,
  ) async {
    return post('/events', data: eventData);
  }

  static Future<Map<String, dynamic>> updateEvent(
    int eventId,
    Map<String, dynamic> eventData,
  ) async {
    return put('/events/$eventId', data: eventData);
  }

  static Future<Map<String, dynamic>> deleteEvent(int eventId) async {
    return delete('/events/$eventId');
  }

  // Announcements
  static Future<Map<String, dynamic>> getAnnouncements({
    Map<String, dynamic>? filters,
  }) async {
    return get('/announcements', queryParameters: filters);
  }

  static Future<Map<String, dynamic>> getAnnouncement(
    int announcementId,
  ) async {
    return get('/announcements/$announcementId');
  }

  static Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    return post('/announcements', data: announcementData);
  }

  static Future<Map<String, dynamic>> updateAnnouncement(
    int announcementId,
    Map<String, dynamic> announcementData,
  ) async {
    return put('/announcements/$announcementId', data: announcementData);
  }

  static Future<Map<String, dynamic>> deleteAnnouncement(
    int announcementId,
  ) async {
    return delete('/announcements/$announcementId');
  }

  // Dashboard statistics endpoints
  static Future<Map<String, dynamic>> getUserStatistics() async {
    return get('/users/statistics');
  }

  static Future<Map<String, dynamic>> getMemberDashboard() async {
    return get('/users/dashboard');
  }

  static Future<Map<String, dynamic>> getReportStatistics() async {
    return get('/reports/statistics');
  }

  // Error handling
  static String _handleError(DioException error) {
    String errorMessage = 'An error occurred';

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          errorMessage = data['message'] ?? 'Bad request';
          break;
        case 401:
          errorMessage = 'Unauthorized access';
          break;
        case 403:
          errorMessage = 'Access denied';
          break;
        case 404:
          errorMessage = 'Resource not found';
          break;
        case 422:
          if (data['errors'] != null) {
            // Validation errors
            final errors = data['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first[0];
          } else {
            errorMessage = data['message'] ?? 'Validation failed';
          }
          break;
        case 500:
          errorMessage = 'Server error. Please try again later.';
          break;
        default:
          errorMessage = data['message'] ?? 'An error occurred';
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      errorMessage =
          'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Request timeout. Please try again.';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage =
          'Cannot connect to server. Please ensure:\n• Laravel server is running on port 8000\n• Using correct URL: $baseUrl';
    } else if (error.type == DioExceptionType.unknown) {
      errorMessage =
          'Network error. Please check:\n• Phone and computer are on same WiFi\n• Windows Firewall allows port 8000\n• Server URL: $baseUrl';
    }

    return errorMessage;
  }
}

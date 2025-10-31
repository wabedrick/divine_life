import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class ConnectivityService {
  static final Logger _logger = Logger();
  static final Connectivity _connectivity = Connectivity();

  static bool _isOnline = true;
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  // Stream to listen to connectivity changes
  static Stream<bool> get connectivityStream => _connectivityController.stream;

  // Get current connectivity status
  static bool get isOnline => _isOnline;

  // Initialize connectivity service
  static Future<void> init() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  // Check current connectivity
  static Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _handleConnectivityChange(connectivityResults);
    } catch (e) {
      _logger.e('Error checking connectivity: $e');
      _updateConnectivityStatus(false);
    }
  }

  // Handle connectivity changes
  static void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    _updateConnectivityStatus(isConnected);
  }

  // Update connectivity status
  static void _updateConnectivityStatus(bool isConnected) {
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      _connectivityController.add(_isOnline);

      _logger.i('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    }
  }

  // Get connectivity type
  static Future<ConnectivityResult> getConnectivityType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      _logger.e('Error getting connectivity type: $e');
      return ConnectivityResult.none;
    }
  }

  // Check if connected to WiFi
  static Future<bool> isWiFiConnected() async {
    final type = await getConnectivityType();
    return type == ConnectivityResult.wifi;
  }

  // Check if connected to mobile data
  static Future<bool> isMobileConnected() async {
    final type = await getConnectivityType();
    return type == ConnectivityResult.mobile;
  }

  // Get connectivity status as string
  static Future<String> getConnectivityStatus() async {
    final type = await getConnectivityType();
    switch (type) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  // Execute function only when online
  static Future<T?> executeWhenOnline<T>(Future<T> Function() function) async {
    if (_isOnline) {
      try {
        return await function();
      } catch (e) {
        _logger.e('Error executing online function: $e');
        rethrow;
      }
    } else {
      _logger.w('Cannot execute function: No internet connection');
      throw 'No internet connection';
    }
  }

  // Wait for connection
  static Future<void> waitForConnection({Duration? timeout}) async {
    if (_isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription<bool> subscription;

    subscription = connectivityStream.listen((isConnected) {
      if (isConnected) {
        subscription.cancel();
        completer.complete();
      }
    });

    if (timeout != null) {
      Timer(timeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError('Connection timeout');
        }
      });
    }

    return completer.future;
  }

  // Dispose connectivity service
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

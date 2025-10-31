import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Professional error tracking and debugging utility
class ErrorTracker {
  static final List<String> _errorLog = [];
  static final bool _isDebugging = kDebugMode;

  /// Log an error with context information
  static void logError(String error, {String? context, dynamic data}) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] ${context ?? 'Unknown'}: $error';

    if (data != null) {
      '$logEntry | Data: ${data.toString()}';
    }

    _errorLog.add(logEntry);

    if (_isDebugging) {
      debugPrint('🚨 ERROR TRACKER: $logEntry');
      if (data != null) {
        debugPrint('   📊 Data: ${data.runtimeType} - $data');
      }
    }
  }

  /// Get all logged errors
  static List<String> getAllErrors() => List.from(_errorLog);

  /// Clear error log
  static void clearErrors() => _errorLog.clear();

  /// Check if specific error pattern exists
  static bool hasErrorPattern(String pattern) {
    return _errorLog.any((error) => error.contains(pattern));
  }
}

/// Safe type converter for API data
class TypeSafeConverter {
  /// Safely convert any value to int
  static int? toInt(dynamic value, {int? fallback}) {
    try {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed == null) {
          ErrorTracker.logError(
            'String cannot be parsed to int: "$value"',
            context: 'TypeSafeConverter.toInt',
            data: {'value': value, 'fallback': fallback},
          );
        }
        return parsed ?? fallback;
      }
      if (value is double) return value.round();

      ErrorTracker.logError(
        'Cannot convert ${value.runtimeType} to int: $value',
        context: 'TypeSafeConverter.toInt',
        data: {'value': value, 'type': value.runtimeType, 'fallback': fallback},
      );
      return fallback;
    } catch (e) {
      ErrorTracker.logError(
        'Exception in toInt: $e',
        context: 'TypeSafeConverter.toInt exception',
        data: {'value': value, 'error': e.toString(), 'fallback': fallback},
      );
      return fallback;
    }
  }

  /// Safely convert any value to String
  static String toStringValue(dynamic value) {
    try {
      if (value == null) return '';
      return value.toString();
    } catch (e) {
      ErrorTracker.logError(
        'Exception in toStringValue: $e',
        context: 'TypeSafeConverter.toStringValue',
        data: value,
      );
      return '';
    }
  }

  /// Safely access list index
  static T? safeListAccess<T>(List<T>? list, dynamic index) {
    try {
      if (list == null || list.isEmpty) {
        ErrorTracker.logError(
          'List is null or empty',
          context: 'TypeSafeConverter.safeListAccess',
          data: {'index': index, 'listLength': list?.length},
        );
        return null;
      }

      final safeIndex = toInt(index, fallback: -1);
      if (safeIndex == null || safeIndex < 0 || safeIndex >= list.length) {
        ErrorTracker.logError(
          'Index out of bounds: $index (${index.runtimeType}) -> $safeIndex for list of length ${list.length}',
          context: 'TypeSafeConverter.safeListAccess bounds error',
          data: {
            'originalIndex': index,
            'indexType': index.runtimeType,
            'convertedIndex': safeIndex,
            'listLength': list.length,
          },
        );
        return null;
      }

      return list[safeIndex];
    } catch (e, stackTrace) {
      ErrorTracker.logError(
        'Exception in safeListAccess: $e',
        context: 'TypeSafeConverter.safeListAccess exception',
        data: {
          'index': index,
          'indexType': index.runtimeType,
          'listLength': list?.length,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      return null;
    }
  }
}

/// Safe widget builder with error boundaries
class SafeBuilder extends StatelessWidget {
  final Widget Function() builder;
  final String context;
  final Widget? fallback;

  const SafeBuilder({
    super.key,
    required this.builder,
    required this.context,
    this.fallback,
  });

  @override
  Widget build(BuildContext buildContext) {
    try {
      return builder();
    } catch (e, stackTrace) {
      ErrorTracker.logError(
        'Widget build error: $e',
        context: context,
        data: {'stackTrace': stackTrace.toString()},
      );

      return fallback ??
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(height: 8),
                Text('Error in $context'),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          );
    }
  }
}

import 'package:shelter_partner/services/logger_service.dart';

/// Mock logger implementation for testing
///
/// Captures all log calls for inspection in tests
class MockLoggerService implements LoggerService {
  final List<LogCall> _calls = [];

  /// Get all log calls made to this logger
  List<LogCall> get calls => List.unmodifiable(_calls);

  /// Clear all captured log calls
  void clear() => _calls.clear();

  /// Get calls filtered by log level
  List<LogCall> getCallsByLevel(LogLevel level) {
    return _calls.where((call) => call.level == level).toList();
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _calls.add(LogCall(LogLevel.debug, message, error, stackTrace));
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _calls.add(LogCall(LogLevel.info, message, error, stackTrace));
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _calls.add(LogCall(LogLevel.warning, message, error, stackTrace));
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _calls.add(LogCall(LogLevel.error, message, error, stackTrace));
  }

  @override
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _calls.add(LogCall(LogLevel.critical, message, error, stackTrace));
  }
}

/// Represents a captured log call for testing
class LogCall {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  LogCall(this.level, this.message, this.error, this.stackTrace);

  @override
  String toString() {
    return 'LogCall(level: $level, message: "$message", error: $error, stackTrace: ${stackTrace != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogCall &&
        other.level == level &&
        other.message == message &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode {
    return Object.hash(level, message, error, stackTrace);
  }
}

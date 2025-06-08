import 'package:gcloud/logging.dart';
import 'package:shelter_partner/services/logger_service.dart';

/// Google Cloud Logger implementation for production environments
/// 
/// Sends logs to Google Cloud Logging for centralized log management
class CloudLoggerService implements LoggerService {
  final Logging _logging;
  final String _logName;
  late final Log _log;

  CloudLoggerService({
    required Logging logging,
    String logName = 'shelter-partner-app',
  }) : _logging = logging,
       _logName = logName {
    _log = _logging.log(_logName);
  }

  static Severity _mapLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Severity.DEBUG;
      case LogLevel.info:
        return Severity.INFO;
      case LogLevel.warning:
        return Severity.WARNING;
      case LogLevel.error:
        return Severity.ERROR;
      case LogLevel.critical:
        return Severity.CRITICAL;
    }
  }

  LogEntry _createLogEntry(String message, LogLevel level, [Object? error, StackTrace? stackTrace]) {
    final Map<String, dynamic> jsonPayload = {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (error != null) {
      jsonPayload['error'] = error.toString();
    }
    
    if (stackTrace != null) {
      jsonPayload['stackTrace'] = stackTrace.toString();
    }

    return LogEntry(
      timestamp: DateTime.now(),
      severity: _mapLogLevel(level),
      jsonPayload: jsonPayload,
    );
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log.writeEntry(_createLogEntry(message, LogLevel.debug, error, stackTrace));
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log.writeEntry(_createLogEntry(message, LogLevel.info, error, stackTrace));
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log.writeEntry(_createLogEntry(message, LogLevel.warning, error, stackTrace));
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log.writeEntry(_createLogEntry(message, LogLevel.error, error, stackTrace));
  }

  @override
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log.writeEntry(_createLogEntry(message, LogLevel.critical, error, stackTrace));
  }
}
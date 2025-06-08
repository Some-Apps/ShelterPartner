/// Abstract logger service interface
/// 
/// This provides a unified logging interface that can be implemented
/// for different environments (console for development, cloud for production)
abstract class LoggerService {
  /// Log a debug message
  void debug(String message, [Object? error, StackTrace? stackTrace]);

  /// Log an info message  
  void info(String message, [Object? error, StackTrace? stackTrace]);

  /// Log a warning message
  void warning(String message, [Object? error, StackTrace? stackTrace]);

  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]);

  /// Log a critical error message
  void critical(String message, [Object? error, StackTrace? stackTrace]);
}

/// Log levels for configuration
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}
import 'package:logger/logger.dart';
import 'package:shelter_partner/services/logger_service.dart';

/// Console logger implementation for development environments
/// 
/// Uses the logger package to provide colored console output
/// with proper log levels and formatting
class ConsoleLoggerService implements LoggerService {
  final Logger _logger;

  ConsoleLoggerService({LogLevel minimumLevel = LogLevel.debug}) 
    : _logger = Logger(
        level: _mapLogLevel(minimumLevel),
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
      );

  static Level _mapLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Level.debug;
      case LogLevel.info:
        return Level.info;
      case LogLevel.warning:
        return Level.warning;
      case LogLevel.error:
        return Level.error;
      case LogLevel.critical:
        return Level.fatal;
    }
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
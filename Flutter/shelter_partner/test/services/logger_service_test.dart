import 'package:flutter_test/flutter_test.dart';
import 'package:shelter_partner/services/console_logger_service.dart';
import 'package:shelter_partner/services/mock_logger_service.dart';
import 'package:shelter_partner/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    group('ConsoleLoggerService', () {
      late ConsoleLoggerService logger;

      setUp(() {
        logger = ConsoleLoggerService();
      });

      test('should implement LoggerService interface', () {
        expect(logger, isA<LoggerService>());
      });

      test('should handle debug logging', () {
        // This test just ensures the method doesn't throw
        expect(() => logger.debug('Test debug message'), returnsNormally);
      });

      test('should handle info logging', () {
        expect(() => logger.info('Test info message'), returnsNormally);
      });

      test('should handle warning logging', () {
        expect(() => logger.warning('Test warning message'), returnsNormally);
      });

      test('should handle error logging', () {
        expect(() => logger.error('Test error message'), returnsNormally);
      });

      test('should handle critical logging', () {
        expect(() => logger.critical('Test critical message'), returnsNormally);
      });

      test('should handle logging with error and stack trace', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        expect(
          () => logger.error('Test message with error', error, stackTrace),
          returnsNormally,
        );
      });
    });

    group('MockLoggerService', () {
      late MockLoggerService mockLogger;

      setUp(() {
        mockLogger = MockLoggerService();
      });

      test('should implement LoggerService interface', () {
        expect(mockLogger, isA<LoggerService>());
      });

      test('should capture debug log calls', () {
        mockLogger.debug('Test debug message');

        expect(mockLogger.calls, hasLength(1));
        expect(mockLogger.calls.first.level, equals(LogLevel.debug));
        expect(mockLogger.calls.first.message, equals('Test debug message'));
      });

      test('should capture info log calls', () {
        mockLogger.info('Test info message');

        expect(mockLogger.calls, hasLength(1));
        expect(mockLogger.calls.first.level, equals(LogLevel.info));
        expect(mockLogger.calls.first.message, equals('Test info message'));
      });

      test('should capture warning log calls', () {
        mockLogger.warning('Test warning message');

        expect(mockLogger.calls, hasLength(1));
        expect(mockLogger.calls.first.level, equals(LogLevel.warning));
        expect(mockLogger.calls.first.message, equals('Test warning message'));
      });

      test('should capture error log calls', () {
        mockLogger.error('Test error message');

        expect(mockLogger.calls, hasLength(1));
        expect(mockLogger.calls.first.level, equals(LogLevel.error));
        expect(mockLogger.calls.first.message, equals('Test error message'));
      });

      test('should capture critical log calls', () {
        mockLogger.critical('Test critical message');

        expect(mockLogger.calls, hasLength(1));
        expect(mockLogger.calls.first.level, equals(LogLevel.critical));
        expect(mockLogger.calls.first.message, equals('Test critical message'));
      });

      test('should capture error and stack trace information', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        mockLogger.error('Test message', error, stackTrace);

        expect(mockLogger.calls, hasLength(1));
        final call = mockLogger.calls.first;
        expect(call.error, equals(error));
        expect(call.stackTrace, equals(stackTrace));
      });

      test('should filter calls by log level', () {
        mockLogger.debug('Debug message');
        mockLogger.info('Info message');
        mockLogger.warning('Warning message');
        mockLogger.error('Error message');

        final debugCalls = mockLogger.getCallsByLevel(LogLevel.debug);
        final infoCalls = mockLogger.getCallsByLevel(LogLevel.info);
        final warningCalls = mockLogger.getCallsByLevel(LogLevel.warning);
        final errorCalls = mockLogger.getCallsByLevel(LogLevel.error);

        expect(debugCalls, hasLength(1));
        expect(infoCalls, hasLength(1));
        expect(warningCalls, hasLength(1));
        expect(errorCalls, hasLength(1));
      });

      test('should clear captured calls', () {
        mockLogger.debug('Test message');
        expect(mockLogger.calls, hasLength(1));

        mockLogger.clear();
        expect(mockLogger.calls, isEmpty);
      });

      test('should accumulate multiple log calls', () {
        mockLogger.debug('First message');
        mockLogger.info('Second message');
        mockLogger.error('Third message');

        expect(mockLogger.calls, hasLength(3));
        expect(mockLogger.calls[0].message, equals('First message'));
        expect(mockLogger.calls[1].message, equals('Second message'));
        expect(mockLogger.calls[2].message, equals('Third message'));
      });
    });

    group('LogCall', () {
      test('should have correct equality comparison', () {
        final call1 = LogCall(LogLevel.info, 'Test message', null, null);
        final call2 = LogCall(LogLevel.info, 'Test message', null, null);
        final call3 = LogCall(LogLevel.error, 'Test message', null, null);

        expect(call1, equals(call2));
        expect(call1, isNot(equals(call3)));
      });

      test('should have meaningful toString representation', () {
        final call = LogCall(
          LogLevel.warning,
          'Test message',
          Exception('error'),
          null,
        );
        final string = call.toString();

        expect(string, contains('LogLevel.warning'));
        expect(string, contains('Test message'));
        expect(string, contains('Exception: error'));
      });
    });
  });
}

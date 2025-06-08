# Logging System

This directory contains the production-ready logging system for ShelterPartner. The logging system is designed to be:

- **Environment-aware**: Automatically switches between console logging (development) and Google Cloud Logging (production)
- **Injectable**: Fully integrated with Riverpod for dependency injection and testing
- **Configurable**: Easy to configure log levels and destinations
- **Production-ready**: Ready for Google Cloud Logging with minimal configuration

## Architecture

### Components

- **`LoggerService`** - Abstract interface defining logging methods (debug, info, warning, error, critical)
- **`ConsoleLoggerService`** - Console implementation for development with colored output and emojis
- **`CloudLoggerService`** - Google Cloud Logging implementation for production
- **`MockLoggerService`** - Test implementation that captures log calls for verification

### Environment Detection

The system automatically detects the environment:
- **Development**: Uses `ConsoleLoggerService` with debug-level logging
- **Production**: Uses `CloudLoggerService` (or console fallback) with info-level logging

## Usage

### In Application Code

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class MyRepository {
  final LoggerService _logger;
  
  MyRepository({required LoggerService logger}) : _logger = logger;
  
  Future<void> someOperation() async {
    _logger.info('Starting operation');
    
    try {
      // Do work...
      _logger.debug('Operation completed successfully');
    } catch (e, stackTrace) {
      _logger.error('Operation failed', e, stackTrace);
      rethrow;
    }
  }
}

// Provider definition
final myRepositoryProvider = Provider<MyRepository>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  return MyRepository(logger: logger);
});
```

### In View Models

```dart
class MyViewModel extends StateNotifier<SomeState> {
  final Ref _ref;
  
  MyViewModel(this._ref) : super(SomeState.initial());
  
  Future<void> performAction() async {
    final logger = _ref.read(loggerServiceProvider);
    logger.info('Performing action');
    
    try {
      // Do work...
    } catch (e, stackTrace) {
      logger.error('Action failed', e, stackTrace);
    }
  }
}
```

### In Tests

```dart
void main() {
  group('MyService Tests', () {
    setUp(() {
      FirebaseTestOverrides.initialize();
    });

    test('should log operations correctly', () async {
      final container = ProviderContainer(
        overrides: FirebaseTestOverrides.overrides,
      );
      
      final service = container.read(myServiceProvider);
      await service.performOperation();
      
      // Verify logging
      final mockLogger = FirebaseTestOverrides.mockLogger;
      expect(mockLogger.calls, hasLength(1));
      expect(mockLogger.calls.first.level, equals(LogLevel.info));
      expect(mockLogger.calls.first.message, contains('operation'));
    });
  });
}
```

## Log Levels

- **`debug`** - Detailed diagnostic information, only in development
- **`info`** - General information about application flow
- **`warning`** - Potentially harmful situations that should be noted
- **`error`** - Error events that might still allow the application to continue
- **`critical`** - Very severe error events that might cause the application to abort

## Production Setup

To enable Google Cloud Logging in production:

1. **Set up Google Cloud Project**: Create or use existing Google Cloud project
2. **Enable Cloud Logging API**: Enable the Cloud Logging API in your project
3. **Configure Authentication**: Set up service account credentials
4. **Update Provider**: Uncomment and configure the cloud logging code in `firebase_providers.dart`

Example production configuration:

```dart
final loggerServiceProvider = Provider<LoggerService>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  
  if (environment.isProduction) {
    try {
      // Configure with your Google Cloud project ID
      final logging = Logging(authClient, projectId: 'your-project-id');
      return CloudLoggerService(logging: logging);
    } catch (e) {
      // Fallback to console if cloud logging fails
      return ConsoleLoggerService(minimumLevel: LogLevel.info);
    }
  } else {
    return ConsoleLoggerService(minimumLevel: LogLevel.debug);
  }
});
```

## Features

### Console Logging (Development)
- ✅ Colored output with emojis
- ✅ Timestamps and method information
- ✅ Stack trace support
- ✅ Configurable log levels

### Cloud Logging (Production)
- ✅ Structured JSON logging
- ✅ Integration with Google Cloud Logging
- ✅ Centralized log management
- ✅ Automatic log retention and searching

### Testing
- ✅ Mock logger captures all log calls
- ✅ Easy verification of log messages and levels
- ✅ Complete test coverage of logging functionality

## Migration from Print Statements

The system has replaced 118+ print statements throughout the codebase with proper logging:

- `print("message")` → `logger.info("message")`
- `print("ERROR: $e")` → `logger.error("Operation failed", e, stackTrace)`
- `print(object.toMap())` → `logger.debug("Data: ${object.toMap()}")`

All error handling has been updated to capture stack traces for better debugging.
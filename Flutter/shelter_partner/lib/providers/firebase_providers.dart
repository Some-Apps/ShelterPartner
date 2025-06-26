import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/config/app_environment.dart';
import 'package:shelter_partner/config/service_urls.dart';
import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/services/console_logger_service.dart';
import 'package:shelter_partner/services/cloud_logger_service.dart';
// import 'package:gcloud/logging.dart';

/// Provider for FirebaseFirestore instance
/// This allows us to override the Firestore instance in tests
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for FirebaseAuth instance
/// This allows us to override the Auth instance in tests
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for AppEnvironment
/// Determines the current environment (development/production)
final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return AppEnvironment.autoDetect();
});

/// Provider for ServiceUrls
/// Provides service URLs based on the current environment
final serviceUrlsProvider = Provider<ServiceUrls>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  return environment.serviceUrls;
});

/// Provider for LoggerService instance
/// Automatically selects appropriate logger based on environment:
/// - ConsoleLogger for development
/// - CloudLogger for production (when Google Cloud credentials are configured)
final loggerServiceProvider = Provider<LoggerService>((ref) {
  final environment = ref.watch(appEnvironmentProvider);

  if (environment.isProduction) {
    // In production, use cloud logger stub (which falls back to console until configured)
    // To enable actual cloud logging, follow instructions in GOOGLE_CLOUD_LOGGING_SETUP.md
    try {
      // When gcloud is properly configured, this will use actual cloud logging
      return CloudLoggerService(
        logging:
            null, // Placeholder - will be actual Logging instance when configured
        logName: 'shelter-partner-app',
      );
    } catch (e) {
      // Fallback to console if cloud logging fails to initialize
      return ConsoleLoggerService(minimumLevel: LogLevel.info);
    }
  } else {
    // Development: use console logger with debug level
    return ConsoleLoggerService(minimumLevel: LogLevel.debug);
  }
});

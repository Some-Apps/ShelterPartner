import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/logging/v2.dart';
import 'package:googleapis/servicemanagement/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:riverpod/src/framework.dart';
import 'package:shelter_partner/config/app_environment.dart';
import 'package:shelter_partner/config/service_urls.dart';
import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/services/console_logger_service.dart';
import 'package:shelter_partner/services/cloud_logger_service.dart';

const projectId = String.fromEnvironment('GOOGLE_CLOUD_PROJECT_ID');
const serviceAccountKey = String.fromEnvironment(
  'GOOGLE_CLOUD_LOGGING_SERVICE_ACCOUNT_KEY',
);

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

/// Provider for AppEnvironment.
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
final loggerServiceProvider = Provider<LoggerService>(
  (ref) async {
        final environment = ref.watch(appEnvironmentProvider);

        if (projectId.isNotEmpty && serviceAccountKey.isNotEmpty) {
          // Initialize cloud logging
          try {
            // Configure authentication
            final credentials = ServiceAccountCredentials.fromJson({
              // Your service account key JSON here
              // Or use Application Default Credentials
              serviceAccountKey,
            });

            final authClient = await clientViaServiceAccount(credentials, [
              LoggingApi.cloudPlatformScope,
            ]);

            final logging = Logging();
            return CloudLoggerService(
              logging: logging,
              logName: 'shelter-partner-app',
            );
          } catch (e) {
            // Fallback to console if cloud logging fails to initialize
            return ConsoleLoggerService(minimumLevel: LogLevel.warning);
          }
        } else {
          return ConsoleLoggerService(minimumLevel: LogLevel.debug);
        }
      }
      as Create<LoggerService, ProviderRef<LoggerService>>,
);

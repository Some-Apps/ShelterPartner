import 'package:flutter/foundation.dart';
import 'package:shelter_partner/config/service_urls.dart';

/// Environment configuration for the application
///
/// Provides information about the current environment (development, production)
/// and configuration for services like logging
class AppEnvironment {
  final bool isProduction;
  final bool isDebugMode;
  final String environment;
  final ServiceUrls serviceUrls;

  const AppEnvironment._({
    required this.isProduction,
    required this.isDebugMode,
    required this.environment,
    required this.serviceUrls,
  });

  /// Create development environment configuration
  factory AppEnvironment.development() {
    return AppEnvironment._(
      isProduction: false,
      isDebugMode: true,
      environment: 'development',
      serviceUrls: ServiceUrls.development(),
    );
  }

  /// Create production environment configuration
  factory AppEnvironment.production() {
    return AppEnvironment._(
      isProduction: true,
      isDebugMode: false,
      environment: 'production',
      serviceUrls: ServiceUrls.production(),
    );
  }

  /// Auto-detect environment based on Flutter's kDebugMode
  factory AppEnvironment.autoDetect() {
    return kDebugMode
        ? AppEnvironment.development()
        : AppEnvironment.production();
  }

  @override
  String toString() => 'AppEnvironment($environment, urls: $serviceUrls)';
}

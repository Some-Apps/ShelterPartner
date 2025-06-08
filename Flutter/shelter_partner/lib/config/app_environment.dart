import 'package:flutter/foundation.dart';

/// Environment configuration for the application
/// 
/// Provides information about the current environment (development, production)
/// and configuration for services like logging
class AppEnvironment {
  final bool isProduction;
  final bool isDebugMode;
  final String environment;
  
  const AppEnvironment._({
    required this.isProduction,
    required this.isDebugMode,
    required this.environment,
  });

  /// Create development environment configuration
  factory AppEnvironment.development() {
    return const AppEnvironment._(
      isProduction: false,
      isDebugMode: true,
      environment: 'development',
    );
  }

  /// Create production environment configuration
  factory AppEnvironment.production() {
    return const AppEnvironment._(
      isProduction: true,
      isDebugMode: false,
      environment: 'production',
    );
  }

  /// Auto-detect environment based on Flutter's kDebugMode
  factory AppEnvironment.autoDetect() {
    return kDebugMode 
        ? AppEnvironment.development()
        : AppEnvironment.production();
  }

  @override
  String toString() => 'AppEnvironment($environment)';
}
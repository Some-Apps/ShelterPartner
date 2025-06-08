import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/services/console_logger_service.dart';

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

/// Provider for LoggerService instance
/// Uses ConsoleLogger by default, can be overridden for production or testing
final loggerServiceProvider = Provider<LoggerService>((ref) {
  // Default to console logger for development
  // In production, this would be overridden with CloudLoggerService
  return ConsoleLoggerService();
});

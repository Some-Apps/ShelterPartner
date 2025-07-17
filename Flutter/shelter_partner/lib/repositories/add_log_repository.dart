import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/services/analytics_service.dart';

class AddLogRepository {
  final FirebaseFirestore _firestore;
  final AnalyticsService _analytics;

  AddLogRepository({
    required FirebaseFirestore firestore,
    required AnalyticsService analytics,
  }) : _firestore = firestore,
       _analytics = analytics;

  Future<void> addLogToAnimal(Animal animal, String shelterID, Log log) async {
    // Determine the collection based on species
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';

    // Add the log to the logs attribute in Firestore
    await _firestore
        .collection('shelters/$shelterID/$collection')
        .doc(animal.id)
        .update({
          'logs': FieldValue.arrayUnion([log.toMap()]),
        });

    // Track log completion (animal was taken out and put back)
    await _analytics.trackLogCompleted(animal.id, animal.species, log.type);
  }
}

// Provider for AddLogRepository
final addLogRepositoryProvider = Provider<AddLogRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return AddLogRepository(firestore: firestore, analytics: analytics);
});

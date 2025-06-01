import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/log.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class PutBackConfirmationRepository {
  final FirebaseFirestore _firestore;
  PutBackConfirmationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  Future<void> putBackAnimal(Animal animal, String shelterID, Log log) async {
    try {
      // Determine the collection based on species
      final collection = animal.species.toLowerCase() == 'cat'
          ? 'cats'
          : 'dogs';
      print('Determined collection: $collection');

      // Fetch the current logs
      final docRef = _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null || !data.containsKey('logs')) {
        throw Exception('No logs found for animal ${animal.id}');
      }

      List<dynamic> logs = data['logs'];
      if (logs.isEmpty) {
        throw Exception('Logs are empty for animal ${animal.id}');
      }

      // Update the last log
      Map<String, dynamic> lastLog = logs.last;
      lastLog['earlyReason'] = log.earlyReason;
      lastLog['endTime'] = log.endTime;

      // Update the logs array in Firestore
      if (!animal.inKennel) {
        await docRef.update({'logs': logs});
        print('Updated last log for ${animal.id}');

        // Update the inKennel status
        await docRef.update({'inKennel': true});
        print('Updated inKennel status for ${animal.id}');
      }
    } catch (e) {
      print('Error in putBackAnimal: $e');
    }
  }

  Future<void> deleteLastLog(Animal animal, String shelterID) async {
    try {
      // Determine the collection based on species
      final collection = animal.species.toLowerCase() == 'cat'
          ? 'cats'
          : 'dogs';
      print('Determined collection: $collection');

      // Fetch the current logs
      final docRef = _firestore
          .collection('shelters/$shelterID/$collection')
          .doc(animal.id);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data == null || !data.containsKey('logs')) {
        throw Exception('No logs found for animal ${animal.id}');
      }

      List<dynamic> logs = data['logs'];
      if (logs.isEmpty) {
        throw Exception('Logs are empty for animal ${animal.id}');
      }

      // Remove the last log
      logs.removeLast();

      // Update the logs array and inKennel status in Firestore
      await docRef.update({'logs': logs, 'inKennel': true});
      print('Deleted last log and set inKennel to true for ${animal.id}');
    } catch (e) {
      print('Error in deleteLastLog: $e');
    }
  }
}

// Provider for PutBackConfirmationRepository
final putBackConfirmationRepositoryProvider =
    Provider<PutBackConfirmationRepository>((ref) {
      final firestore = ref.watch(firestoreProvider);
      return PutBackConfirmationRepository(firestore: firestore);
    });

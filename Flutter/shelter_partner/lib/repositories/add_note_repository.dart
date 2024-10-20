// animal_card_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:uuid/uuid.dart';

class AddNoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateAnimalTags(Animal animal, String shelterID, String tagName) async {
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';
    final docRef = _firestore.collection('shelters/$shelterID/$collection').doc(animal.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Animal does not exist!");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final tags = List<Map<String, dynamic>>.from(data['tags'] ?? []);

      bool tagExists = false;
      for (var tag in tags) {
        if (tag['title'] == tagName) {
          tag['count'] = (tag['count'] ?? 0) + 1;
          tagExists = true;
          break;
        }
      }

      if (!tagExists) {
        tags.add({'title': tagName, 'count': 1, 'timestamp': Timestamp.now(), 'id': Uuid().v4().toString()});
      }

      transaction.update(docRef, {'tags': tags});
    });
  }

  Future<void> addNoteToAnimal(Animal animal, String shelterID, Note note) async {
    // Determine the collection based on species
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';

    // Add the note to the notes attribute in Firestore
    await _firestore
        .collection('shelters/$shelterID/$collection')
        .doc(animal.id)
        .update({
          'notes': FieldValue.arrayUnion([note.toMap()])
        });
  }
}

// Provider for AddNoteRepository
final addNoteRepositoryProvider = Provider<AddNoteRepository>((ref) {
  return AddNoteRepository();
});

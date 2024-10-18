// animal_card_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';

class AddNoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

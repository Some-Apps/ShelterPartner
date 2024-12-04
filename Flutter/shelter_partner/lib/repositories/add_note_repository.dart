// animal_card_repository.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddNoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateAnimalTags(Animal animal, String shelterID, String tagName) async {
    final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';
    final docRef = _firestore.collection('shelters/$shelterID/$collection').doc(animal.id);
    final appUser = appUserProvider.read;

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
        tags.add({'title': tagName, 'count': 1, 'timestamp': Timestamp.now(), 'id': const Uuid().v4().toString()});
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

  Future<void> uploadImageToAnimal(Animal animal, String shelterID, XFile image, WidgetRef ref) async {
  final photoId = const Uuid().v4().toString(); // Generate UUID once
  final storageRef = FirebaseStorage.instance.ref().child('$shelterID/${animal.id}/$photoId');

  // Determine the upload task based on the platform
  UploadTask uploadTask;
  if (kIsWeb) {
    // On web, upload image bytes directly with metadata
    final imageBytes = await image.readAsBytes();
    uploadTask = storageRef.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
  } else {
    // On mobile/desktop, upload using File conversion
    uploadTask = storageRef.putFile(File(image.path), SettableMetadata(contentType: 'image/jpeg'));
  }

  // Get the download URL after the upload completes
  final snapshot = await uploadTask.whenComplete(() => {});
  final downloadUrl = await snapshot.ref.getDownloadURL();

  // Create the Photo object with the download URL
  final photo = Photo(
    id: photoId, // Use the same ID as storage path
    url: downloadUrl,
    timestamp: Timestamp.now(),
    author: ref.read(appUserProvider)?.firstName ?? 'Unknown',
    authorID: ref.read(appUserProvider)?.id ?? 'Unknown',
  );

  // Determine the correct collection for the animal and update Firestore
  final collection = animal.species.toLowerCase() == 'cat' ? 'cats' : 'dogs';
  await _firestore
      .collection('shelters/$shelterID/$collection')
      .doc(animal.id)
      .update({
        'photos': FieldValue.arrayUnion([photo.toMap()])
      });
}



}

// Provider for AddNoteRepository
final addNoteRepositoryProvider = Provider<AddNoteRepository>((ref) {
  return AddNoteRepository();
});

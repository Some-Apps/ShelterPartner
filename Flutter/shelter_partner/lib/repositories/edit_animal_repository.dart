import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class EditAnimalRepository {
  final FirebaseFirestore _firestore;
  EditAnimalRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<void> deleteItem(
    String shelterId,
    String animalType,
    String animalId,
    String field,
    String itemId,
  ) async {
    final documentRef = _firestore
        .collection('shelters')
        .doc(shelterId)
        .collection(animalType == "dog" ? "dogs" : "cats")
        .doc(animalId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(documentRef);

      if (snapshot.exists) {
        final data = snapshot.data();
        final List<dynamic> items = data?[field] ?? [];

        // Filter out the item with the matching id
        final updatedItems =
            items.where((item) => item['id'] != itemId).toList();

        // Update the field with the filtered list
        transaction.update(documentRef, {field: updatedItems});
      }
    });
  }

  Future<void> deletePhotoFromStorage(
    String shelterId,
    String animalId,
    Photo photo, // PhotoId to Photo object
    String animalType,
  ) async {
    final storage = FirebaseStorage.instance;
    final List<String> sizes = ['100x100', '250x250', '500x500', '750x750'];

    final animalRef = _firestore
        .collection('shelters')
        .doc(shelterId)
        .collection(animalType == "dog" ? "dogs" : "cats")
        .doc(animalId);

    // For manual photos , delete from storage
    if (photo.source == 'manual') {
      try {
        // Delete original photo
        final originalPhotoRef = storage.ref().child(
          '$shelterId/$animalId/${photo.id}',
        );
        await originalPhotoRef.delete();

        // Delete resized photos
        for (final size in sizes) {
          final resizedPhotoRef = storage.ref().child(
            '$shelterId/$animalId/${photo.id}_$size',
          );
          try {
            await resizedPhotoRef.delete();
          } catch (e) {
            print('Failed to delte resized photos: ${e.toString()}');
          }
        }
      } catch (e) {
        print('Error deleting manual photo from storage: $e');
      }
    }
    // For ShelterLuv/asm photos , add to deleted_photos collection
    else if (photo.source == 'shelterluv' || photo.source == 'asm') {
      try {
        await animalRef.collection('deleted_photos').add({
          'url': photo.url,
          'deletedAt': Timestamp.now(),
          'source': photo.source,
        });
      } catch (e) {
        print('Error adding to deleted photos: $e');
      }
    }
  }
}

final editAnimalRepositoryProvider = Provider<EditAnimalRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return EditAnimalRepository(firestore: firestore);
});

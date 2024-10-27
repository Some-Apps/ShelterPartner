import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditAnimalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteItem(String shelterId, String animalType, String animalId, String field, String itemId) async {
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
        final updatedItems = items.where((item) => item['id'] != itemId).toList();

        // Update the field with the filtered list
        transaction.update(documentRef, {field: updatedItems});
      }
    });
  }

  Future<void> deletePhotoFromStorage(String shelterId, String animalId, String photoId) async {
    print('Deleting photo from storage: gs://development-e5282.appspot.com/$shelterId/$animalId/$photoId');

    final storage = FirebaseStorage.instance;
    final List<String> sizes = ['100x100', '250x250', '500x500', '750x750'];

    // Delete the original photo
    final originalPhotoRef = storage.ref().child('$shelterId/$animalId/$photoId');
    await originalPhotoRef.delete();

    // Delete the resized photos
    for (final size in sizes) {
      final resizedPhotoRef = storage.ref().child('$shelterId/$animalId/${photoId}_$size');
      try {
        await resizedPhotoRef.delete();
        print('Deleted resized photo: gs://development-e5282.appspot.com/$shelterId/$animalId/${photoId}_$size');
      } catch (e) {
        print('Failed to delete resized photo: ${e.toString()}');
        // You can handle the error if needed
      }
    }
  }
}

final editAnimalRepositoryProvider = Provider<EditAnimalRepository>((ref) {
  return EditAnimalRepository();
});

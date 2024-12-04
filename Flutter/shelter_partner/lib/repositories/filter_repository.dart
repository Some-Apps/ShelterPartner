import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveFilterExpression(
    String collection,
    String documentID,
    Map<String, dynamic> filterExpression,
    String filterFieldPath,
  ) async {
    final docRef = _firestore.collection(collection).doc(documentID);
    return docRef.update({
      filterFieldPath: filterExpression,
    }).catchError((error) {
      throw Exception("Failed to save filter expression: $error");
    });
  }

  Future<Map<String, dynamic>?> loadFilterExpression(
    String collection,
    String documentID,
    String filterFieldPath,
  ) async {
    final docRef = _firestore.collection(collection).doc(documentID);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null) {
        final filterData = _getNestedField(data, filterFieldPath);
        if (filterData != null) {
          return Map<String, dynamic>.from(filterData);
        }
      }
    }
    return null;
  }

  dynamic _getNestedField(Map<String, dynamic> data, String fieldPath) {
    final parts = fieldPath.split('.');
    dynamic currentData = data;
    for (final part in parts) {
      if (currentData is Map<String, dynamic> && currentData.containsKey(part)) {
        currentData = currentData[part];
      } else {
        return null;
      }
    }
    return currentData;
  }
}


final filterRepositoryProvider =
    Provider<FilterRepository>((ref) {
  return FilterRepository();
});

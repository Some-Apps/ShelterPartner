import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AppUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user by ID
  Future<AppUser?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromDocument(doc);
    }
    return null;
  }
}

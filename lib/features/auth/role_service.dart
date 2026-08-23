import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    return data?['role'] as String?;
  }
}
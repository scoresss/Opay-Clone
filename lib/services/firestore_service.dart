import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user document on registration
  Future<void> createUser(String uid, String name, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'balance': 2000.0, // Initial balance
    });
  }

  // Get user data
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Update balance
  Future<void> updateBalance(String uid, double newBalance) async {
    await _firestore.collection('users').doc(uid).update({
      'balance': newBalance,
    });
  }
}

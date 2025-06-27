import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create user document after registration
  Future<void> createUser(String uid, String name, String email) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': uid,
        'name': name,
        'email': email,
        'balance': 0.0,
      });
    }
  }

  /// Stream user document for live updates
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Get current user balance
  Future<double> getBalance(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.data()?['balance'] ?? 0).toDouble();
  }

  /// Update user balance
  Future<void> updateBalance(String uid, double newBalance) async {
    await _firestore.collection('users').doc(uid).update({
      'balance': newBalance,
    });
  }

  /// Transfer balance from one user to another
  Future<void> sendMoney({
    required String senderUid,
    required String receiverUid,
    required double amount,
  }) async {
    final senderRef = _firestore.collection('users').doc(senderUid);
    final receiverRef = _firestore.collection('users').doc(receiverUid);

    await _firestore.runTransaction((transaction) async {
      final senderSnapshot = await transaction.get(senderRef);
      final receiverSnapshot = await transaction.get(receiverRef);

      double senderBalance = senderSnapshot['balance'];
      double receiverBalance = receiverSnapshot['balance'];

      if (senderBalance < amount) {
        throw Exception("Insufficient funds");
      }

      transaction.update(senderRef, {'balance': senderBalance - amount});
      transaction.update(receiverRef, {'balance': receiverBalance + amount});
    });
  }

  /// Add transaction record (optional)
  Future<void> addTransaction(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(data);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payment_reminder/src/models/payment.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'name': user.displayName ?? 'Unknown',
      'email': user.email,
      'role': 'user'
    });
  }

  Future<void> addPayment(Payment payment) async {
    await _db.collection('payments').add(payment.toFirestore());
  }

  Stream<List<Payment>> streamPayments(String userId) {
    return _db
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Payment.fromFirestore(doc.data()))
            .toList());
  }
}

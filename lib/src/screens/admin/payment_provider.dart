import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentProvider with ChangeNotifier {
  int _totalPayments = 0;
  double _totalAmount = 0.0;
  int _totalUsers = 0;
  double _totalInterest = 0.0;
  List<Map<String, dynamic>> _payments = [];
  List<String> _users = [];
  Map<String, String> _userNames = {};
  Map<String, double> _paymentModeDistribution = {};

  int get totalPayments => _totalPayments;
  double get totalAmount => _totalAmount;
  int get totalUsers => _totalUsers;
  double get totalInterest => _totalInterest;
  List<Map<String, dynamic>> get payments => _payments;
  List<String> get users => _users;
  Map<String, String> get userNames => _userNames;
  Map<String, double> get paymentModeDistribution => _paymentModeDistribution;

  PaymentProvider() {
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      double totalAmount = 0;
      double totalInterest = 0;
      int totalPayments = 0;
      List<Map<String, dynamic>> payments = [];
      Map<String, String> userNames = {};
      Map<String, double> paymentModeDistribution = {};

      for (var userDoc in userSnapshot.docs) {
        userNames[userDoc.id] = userDoc['name'] ?? 'Unknown';

        totalInterest += userDoc['interest'] is int
            ? (userDoc['interest'] as int).toDouble()
            : userDoc['interest'] ?? 0.0;

        QuerySnapshot paymentSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('payments')
            .get();

        for (var paymentDoc in paymentSnapshot.docs) {
          double amount = paymentDoc['amount'] is int
              ? (paymentDoc['amount'] as int).toDouble()
              : paymentDoc['amount'] ?? 0.0;
          totalAmount += amount;

          String paymentMode = paymentDoc['paymentMode'] ?? 'Unknown';
          DateTime date =
              (paymentDoc['date'] as Timestamp?)?.toDate() ?? DateTime.now();

          payments.add({
            'amount': amount,
            'date': date,
            'paymentMode': paymentMode,
            'userId': userDoc.id,
          });

          paymentModeDistribution[paymentMode] =
              (paymentModeDistribution[paymentMode] ?? 0.0) + 1;

          totalPayments++;
        }
      }

      _totalPayments = totalPayments;
      _totalAmount = totalAmount;
      _totalUsers = userSnapshot.docs.length;
      _totalInterest = totalInterest;
      _payments = payments;
      _users = userSnapshot.docs
          .map((doc) => doc['name'] as String? ?? 'Unknown')
          .toList();
      _userNames = userNames;
      _paymentModeDistribution = paymentModeDistribution;

      notifyListeners();
    } catch (e) {
      print('Error fetching data: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Payment History'),
        ),
        body: Center(
          child: Text('Please log in to view your payment history.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter functionality here
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payments')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final payments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final amount = payment['amount'];
              final date = (payment['date'] as Timestamp).toDate();
              final paymentMode = payment['paymentMode'];

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('₹$amount'),
                  subtitle: Text(
                      '${date.day}/${date.month}/${date.year} - $paymentMode'),
                  leading: Icon(Icons.monetization_on, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

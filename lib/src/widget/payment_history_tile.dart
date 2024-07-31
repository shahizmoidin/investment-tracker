import 'package:flutter/material.dart';
import 'package:payment_reminder/src/models/payment.dart';

class PaymentHistoryTile extends StatelessWidget {
  final Payment payment;

  const PaymentHistoryTile({Key? key, required this.payment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Payment of ${payment.amount} on ${payment.date}'),
    );
  }
}

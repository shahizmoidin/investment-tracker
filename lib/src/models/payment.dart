class Payment {
  final String userId;
  final double amount;
  final DateTime date;

  Payment({required this.userId, required this.amount, required this.date});

  factory Payment.fromFirestore(Map<String, dynamic> json) {
    return Payment(
      userId: json['userId'],
      amount: json['amount'],
      date: json['date'].toDate(), // Firestore Timestamp to DateTime
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'date': date,
    };
  }
}

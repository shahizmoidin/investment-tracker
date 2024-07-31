import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'payment_provider.dart'; // Import the PaymentProvider class

class TotalPaymentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentProvider(),
      child: Scaffold(
        body: Consumer<PaymentProvider>(
          builder: (context, paymentProvider, _) {
            return SingleChildScrollView(
              child: Center(
                child: Card(
                  elevation: 4.0,
                  margin:
                      EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildDashboardCard(
                          title: 'Total Users',
                          value: paymentProvider.totalUsers.toString(),
                          color: Colors.blue,
                          onTap: () =>
                              _showUsersDialog(context, paymentProvider),
                        ),
                        SizedBox(height: 10),
                        _buildDashboardCard(
                          title: 'Total Payments',
                          value: paymentProvider.totalPayments.toString(),
                          color: Colors.green,
                          onTap: () => _showPaymentModePieChart(
                              context, paymentProvider),
                        ),
                        SizedBox(height: 10),
                        _buildDashboardCard(
                          title: 'Total Amount',
                          value: '₹${paymentProvider.totalAmount}',
                          color: Colors.orange,
                          onTap: () =>
                              _showPaymentsDialog(context, paymentProvider),
                        ),
                        SizedBox(height: 10),
                        _buildDashboardCard(
                          title: 'Total Interest',
                          value: '₹${paymentProvider.totalInterest}',
                          color: Colors.red,
                          onTap: () =>
                              _showInterestDialog(context, paymentProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUsersDialog(BuildContext context, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Total Users'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: paymentProvider.users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(paymentProvider.users[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPaymentsDialog(
      BuildContext context, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payments Details'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: paymentProvider.payments.length,
              itemBuilder: (context, index) {
                var payment = paymentProvider.payments[index];
                return ListTile(
                  title: Text('₹${payment['amount']}'),
                  subtitle: Text(
                    'Paid by ${paymentProvider.userNames[payment['userId']]} on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(payment['date'])} using ${payment['paymentMode']}',
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showInterestDialog(
      BuildContext context, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Total Interest Details'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: paymentProvider.userNames.length,
              itemBuilder: (context, index) {
                String userId = paymentProvider.userNames.keys.elementAt(index);
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container();
                    double interest = snapshot.data!.get('interest') ?? 0.0;
                    return ListTile(
                      title: Text(paymentProvider.userNames[userId]!),
                      subtitle: Text('Interest: ₹$interest'),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPaymentModePieChart(
      BuildContext context, PaymentProvider paymentProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payment Mode Distribution'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: PieChart(
              PieChartData(
                sections: paymentProvider.paymentModeDistribution.entries
                    .map(
                      (entry) => PieChartSectionData(
                        color: Colors.primaries[paymentProvider
                                .paymentModeDistribution.keys
                                .toList()
                                .indexOf(entry.key) %
                            Colors.primaries.length],
                        value: entry.value,
                        title: entry.key,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

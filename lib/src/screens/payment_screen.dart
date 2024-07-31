import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payment_reminder/src/services/notification_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:upi_india/upi_india.dart';

class AddPaymentScreen extends StatefulWidget {
  final NotificationService notificationService;

  AddPaymentScreen({required this.notificationService});

  @override
  _AddPaymentScreenState createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _paymentMode = 'cash';
  double _totalInvestment = 0;
  double _totalInterestReceived = 0;
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  UpiIndia _upiIndia = UpiIndia();
  late Future<List<UpiApp>> _apps;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fetchTotalInvestment();
    _fetchTotalInterestReceived();
    _apps = _upiIndia.getAllUpiApps();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchTotalInvestment() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot paymentsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .get();

      double total = 0;
      for (var doc in paymentsSnapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }

      setState(() {
        _totalInvestment = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTotalInterestReceived() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      double totalInterest = (userSnapshot['interest'] as num).toDouble();

      setState(() {
        _totalInterestReceived = totalInterest;
        _isLoading = false;
      });
    }
  }

  Future<void> _addPayment() async {
    if (_paymentMode == 'upi') {
      _initiateUpiPayment();
    } else {
      await _addPaymentToFirestore();
    }
  }

  Future<void> _initiateUpiPayment() async {
    UpiResponse response = await _upiIndia.startTransaction(
      app: UpiApp.phonePe, // or any other UpiApp available in the list
      receiverUpiId: '8431088272@ybl',
      receiverName: 'MALATESH S TALAWAR',
      transactionRefId: 'TXNID_12345',
      transactionNote: 'Payment for swavalambi savings',
      amount: 300.00,
    );

    if (response.status == UpiPaymentStatus.SUCCESS) {
      await _addPaymentToFirestore();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('UPI Payment Failed: ${response.status}')),
      );
    }
  }

  Future<void> _addPaymentToFirestore() async {
    User? user = _auth.currentUser;
    if (user != null) {
      bool confirmed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Payment'),
          content: Text('Are you sure you want to add this payment of ₹300?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('payments')
              .add({
            'amount': 300,
            'date': DateTime.now(),
            'paymentMode': _paymentMode,
          });
          _fetchTotalInvestment(); // Update total investment after adding payment
          widget.notificationService.scheduleWeeklyMondayNotification(
              0, 'Payment Reminder', 'Make payment of ₹300 today!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment added successfully!')),
          );
        } catch (e) {
          print('Error adding payment: $e');
        }
      }
    } else {
      print('User not authenticated');
    }
  }

  void _showQrCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan QR Code to Pay'),
        content: QrImageView(
          data:
              'upi://pay?pa=9380666237@axl&pn=MALATESH%20S%20TALAWAR&am=300&cu=INR',
          version: QrVersions.auto,
          size: 200.0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Payment'),
        backgroundColor: Colors.deepPurple,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Card(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Container(
                                height: 100,
                                width: double.infinity,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : FadeTransition(
                            opacity: _animation,
                            child: Card(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Investment:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purpleAccent,
                                            Colors.deepPurpleAccent
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurple
                                                .withOpacity(0.5),
                                            blurRadius: 10.0,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '₹$_totalInvestment',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      'Total Interest Received:',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.greenAccent,
                                            Colors.teal
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.green.withOpacity(0.5),
                                            blurRadius: 10.0,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '₹$_totalInterestReceived',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    SizedBox(height: 30),
                    Text(
                      'Select Payment Mode:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    RadioListTile(
                      title: Text('Cash'),
                      value: 'cash',
                      groupValue: _paymentMode,
                      onChanged: (value) {
                        setState(() {
                          _paymentMode = value.toString();
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text('UPI'),
                      value: 'upi',
                      groupValue: _paymentMode,
                      onChanged: (value) {
                        setState(() {
                          _paymentMode = value.toString();
                        });
                      },
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _addPayment,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text('Add Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

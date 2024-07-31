import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class UserPaymentsScreen extends StatefulWidget {
  @override
  _UserPaymentsScreenState createState() => _UserPaymentsScreenState();
}

class _UserPaymentsScreenState extends State<UserPaymentsScreen> {
  String _selectedUser = '';
  List<Map<String, String>> _allUsers = [];
  List<Map<String, String>> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, String>> users = [];

      for (var doc in userSnapshot.docs) {
        users.add({
          'id': doc.id,
          'name': doc['name'],
          'email': doc['email'],
        });
      }

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _searchUser(String query) {
    final suggestions = _allUsers.where((user) {
      final userName = user['name']!.toLowerCase();
      final input = query.toLowerCase();
      return userName.contains(input);
    }).toList();

    setState(() {
      _filteredUsers = suggestions;
    });
  }

  void _onUserSelected(Map<String, String> user) {
    setState(() {
      _selectedUser = user['id']!;
      _searchController.text = user['name']!;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPaymentDetailScreen(
          userId: user['id']!,
          userName: user['name']!,
          userEmail: user['email']!,
        ),
      ),
    ).then((_) {
      // Refresh user data on return
      setState(() {
        _selectedUser = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Payments'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search User',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: _searchUser,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return Card(
                    elevation: 4.0,
                    margin: EdgeInsets.symmetric(vertical: 10.0),
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.blueAccent),
                      title: Text(user['name']!),
                      subtitle: Text(user['email']!),
                      onTap: () => _onUserSelected(user),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserPaymentDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;

  UserPaymentDetailScreen({
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  _UserPaymentDetailScreenState createState() =>
      _UserPaymentDetailScreenState();
}

class _UserPaymentDetailScreenState extends State<UserPaymentDetailScreen> {
  double _totalAmountPaid = 0.0;
  double _totalInterest = 0.0;
  List<Map<String, dynamic>> _paymentHistory = [];
  Map<String, double> _paymentModeDistribution = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchUserPayments(widget.userId);
  }

  Future<void> _fetchUserPayments(String userId) async {
    try {
      QuerySnapshot userPaymentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('payments')
          .get();

      double totalAmount = 0.0;
      double totalInterest = 0.0;
      List<Map<String, dynamic>> paymentHistory = [];
      Map<String, double> paymentModeDistribution = {};

      for (var doc in userPaymentSnapshot.docs) {
        double amount = doc['amount'] is int
            ? (doc['amount'] as int).toDouble()
            : (doc['amount'] as double);
        DateTime date = (doc['date'] as Timestamp).toDate();
        double interest = _calculateInterest(amount, date);
        totalAmount += amount;
        totalInterest += interest;
        paymentHistory.add({
          'id': doc.id,
          'amount': amount,
          'date': date,
          'paymentMode': doc['paymentMode'],
          'interest': interest,
        });

        paymentModeDistribution[doc['paymentMode']] =
            (paymentModeDistribution[doc['paymentMode']] ?? 0.0) + 1;
      }

      // Fetch total interest directly from user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      setState(() {
        _totalAmountPaid = totalAmount;
        _totalInterest = userDoc['interest'] is int
            ? (userDoc['interest'] as int).toDouble()
            : (userDoc['interest'] ?? 0.0);
        _paymentHistory = paymentHistory;
        _paymentModeDistribution = paymentModeDistribution;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('Error fetching user payments: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  double _calculateInterest(double amount, DateTime date) {
    DateTime now = DateTime.now();
    int differenceInMonths =
        ((now.year - date.year) * 12) + now.month - date.month;
    if (differenceInMonths >= 6) {
      return amount * 0.06;
    }
    return 0.0;
  }

  Future<void> _deletePayment(String paymentId, double amount) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('payments')
        .doc(paymentId)
        .delete();

    setState(() {
      _totalAmountPaid -= amount;
      _paymentHistory.removeWhere((payment) => payment['id'] == paymentId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment deleted successfully')),
    );
  }

  Future<void> _addInterestAutomatically() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'interest': FieldValue.increment(_totalInterest)});
      await _fetchUserPayments(widget.userId); // Refresh data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Interest added automatically successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding interest: $e')),
      );
    }
  }

  Future<void> _addCustomInterest(double customInterest) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'interest': FieldValue.increment(customInterest)});
      await _fetchUserPayments(widget.userId); // Refresh data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Custom interest added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding custom interest: $e')),
      );
    }
  }

  void _showAddInterestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController customInterestController =
            TextEditingController();
        double customInterest = _totalAmountPaid * 0.06;

        return AlertDialog(
          title: Text('Add Interest'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _addInterestAutomatically();
                  Navigator.of(context).pop();
                },
                child: Text('Add Interest Automatically'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: customInterestController
                  ..text = customInterest.toStringAsFixed(2),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Custom Interest Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  double customInterest =
                      double.parse(customInterestController.text);
                  _addCustomInterest(customInterest);
                  Navigator.of(context).pop();
                },
                child: Text('Add Custom Interest'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Payment Details'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(child: Text('Error fetching data'))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payments for ${widget.userName}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Total Amount Paid: ₹${_totalAmountPaid.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Total Interest: ₹${_totalInterest.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _showAddInterestDialog,
                            child: Text('Add Interest'),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Payment History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _paymentHistory.length,
                            itemBuilder: (context, index) {
                              var payment = _paymentHistory[index];
                              return ListTile(
                                title: Text(
                                    '₹${payment['amount'].toStringAsFixed(2)}'),
                                subtitle: Text(
                                  'Paid on ${DateFormat('yyyy-MM-dd').format(payment['date'])} using ${payment['paymentMode']} \nInterest: ₹${payment['interest'].toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePayment(
                                      payment['id'], payment['amount']),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Payment Mode Distribution',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _paymentModeDistribution.entries
                                    .map((entry) {
                                  return PieChartSectionData(
                                    color: Colors.primaries[entry.key.length %
                                        Colors.primaries.length],
                                    value: entry.value,
                                    title:
                                        '${entry.key} (${entry.value.toInt()})',
                                    radius: 50,
                                    titleStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

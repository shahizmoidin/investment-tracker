import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:payment_reminder/src/screens/admin/userpayme_detailscreen.dart';

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

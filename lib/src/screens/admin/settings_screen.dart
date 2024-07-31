import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class AdminSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete User Data by Email'),
                subtitle: Text('Remove all data of a specific user by email'),
                onTap: () async {
                  String? userEmail =
                      await _showDeleteUserDialogByEmail(context);
                  if (userEmail != null) {
                    await _deleteUserDataByEmail(userEmail);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User data deleted')));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.clear, color: Colors.red),
                title: Text('Clear All User Data'),
                subtitle: Text('Remove all data of all users'),
                onTap: () async {
                  bool? confirm = await _showClearAllUsersDialog(context);
                  if (confirm == true) {
                    await _clearAllUserData();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('All user data cleared')));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.file_download, color: Colors.blue),
                title: Text('Download Payments PDF'),
                subtitle:
                    Text('Download a PDF of all user payments and interests'),
                onTap: () async {
                  await _downloadPaymentsPDF();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('PDF downloaded')));
                },
              ),
              ListTile(
                leading: Icon(Icons.file_download, color: Colors.blue),
                title: Text('Download Investment Notes PDF'),
                subtitle: Text('Download a PDF of all investment notes'),
                onTap: () async {
                  await _downloadInvestmentNotesPDF();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('PDF downloaded')));
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: Colors.green),
                title: Text('Update User Role'),
                subtitle: Text('Update the role of a specific user'),
                onTap: () async {
                  await _showUpdateUserRoleDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showDeleteUserDialogByEmail(BuildContext context) async {
    String userEmail = '';
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User Data by Email'),
          content: TextField(
            onChanged: (value) {
              userEmail = value;
            },
            decoration: InputDecoration(hintText: "Enter User Email"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(userEmail);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showClearAllUsersDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All User Data'),
          content: Text('Are you sure you want to delete all user data?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Clear All'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserDataByEmail(String email) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _clearAllUserData() async {
    QuerySnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    for (var doc in userSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _downloadPaymentsPDF() async {
    final pdf = pw.Document();

    QuerySnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    for (var userDoc in userSnapshot.docs) {
      String userName = userDoc['name'];
      String userEmail = userDoc['email'];
      double userInterest = userDoc['interest'] is int
          ? (userDoc['interest'] as int).toDouble()
          : userDoc['interest'] ?? 0.0;

      List<List<String>> paymentData = [
        <String>['Amount', 'Date', 'Payment Mode']
      ];
      QuerySnapshot paymentSnapshot =
          await userDoc.reference.collection('payments').get();
      for (var paymentDoc in paymentSnapshot.docs) {
        double amount = paymentDoc['amount'] is int
            ? (paymentDoc['amount'] as int).toDouble()
            : paymentDoc['amount'].toDouble();
        paymentData.add([
          amount.toString(),
          DateFormat('yyyy-MM-dd HH:mm:ss')
              .format((paymentDoc['date'] as Timestamp).toDate()),
          paymentDoc['paymentMode']
        ]);
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Padding(
              padding: pw.EdgeInsets.all(20.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('User: $userName',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Email: $userEmail',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total Interest: Rs $userInterest',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Payments:',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    data: paymentData,
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellStyle: pw.TextStyle(fontSize: 12),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerDecoration:
                        pw.BoxDecoration(color: PdfColors.grey300),
                  ),
                  pw.Divider(),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _downloadInvestmentNotesPDF() async {
    final pdf = pw.Document();

    QuerySnapshot noteSnapshot =
        await FirebaseFirestore.instance.collection('notes').get();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(20.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Investment Notes',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Title', 'Content', 'Date'],
                    ...noteSnapshot.docs.map((noteDoc) {
                      return [
                        noteDoc['title'] as String,
                        noteDoc['content'] as String,
                        DateFormat('yyyy-MM-dd HH:mm:ss')
                            .format((noteDoc['date'] as Timestamp).toDate()),
                      ];
                    }).toList(),
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(fontSize: 12),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _showUpdateUserRoleDialog(BuildContext context) async {
    String userEmail = '';
    String newRole = '';
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update User Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  userEmail = value;
                },
                decoration: InputDecoration(hintText: "Enter User Email"),
              ),
              TextField(
                onChanged: (value) {
                  newRole = value;
                },
                decoration: InputDecoration(hintText: "Enter New Role"),
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
            TextButton(
              child: Text('Update'),
              onPressed: () async {
                await _updateUserRole(userEmail, newRole);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('User role updated')));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserRole(String email, String newRole) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'role': newRole});
    }
  }
}

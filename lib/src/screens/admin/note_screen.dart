import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // You no longer need to fetch the total amount
  }

  Future<void> _addNote() async {
    String title = _titleController.text;
    String content = _contentController.text;
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double interestRate = double.tryParse(_interestController.text) ?? 0.0;
    double interest = (amount * interestRate) / 100;
    String period = _periodController.text;
    DateTime now = DateTime.now();

    try {
      await FirebaseFirestore.instance.collection('notes').add({
        'title': title,
        'content': content,
        'amount': amount,
        'interest': interest,
        'interestRate': interestRate,
        'period': period,
        'date': now,
      });

      // Clear the text fields
      _titleController.clear();
      _contentController.clear();
      _amountController.clear();
      _periodController.clear();
      _interestController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note added successfully')),
      );
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  Future<void> _deleteNoteAndRefund(String noteId) async {
    try {
      DocumentSnapshot noteDoc = await FirebaseFirestore.instance
          .collection('notes')
          .doc(noteId)
          .get();
      double amount = (noteDoc['amount'] as num).toDouble();

      await FirebaseFirestore.instance.collection('notes').doc(noteId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note deleted successfully')),
      );
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Investment Notes'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Investment Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Interest Rate (%)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _periodController,
                decoration: InputDecoration(
                  labelText: 'Investment Period',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addNote,
                child: Text('Add Note'),
              ),
              SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('notes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var notes = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      var note = notes[index];
                      return Card(
                        elevation: 4.0,
                        margin: EdgeInsets.symmetric(vertical: 10.0),
                        child: ListTile(
                          title: Text(note['title']),
                          subtitle: Text(
                            'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format((note['date'] as Timestamp).toDate())}\n'
                            'Amount: ₹${(note['amount'] as num).toDouble().toStringAsFixed(2)}\n'
                            'Interest: ₹${(note['interest'] as num).toDouble().toStringAsFixed(2)} at ${note['interestRate']}%\n'
                            'Period: ${note['period']}\n'
                            '${note['content']}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNoteAndRefund(note.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

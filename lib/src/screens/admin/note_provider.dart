import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoteProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _notes = [];

  List<Map<String, dynamic>> get notes => _notes;

  NoteProvider() {
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    QuerySnapshot snapshot = await _firestore.collection('notes').get();
    _notes = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    notifyListeners();
  }

  Future<void> addNote(String title, String content, double amount) async {
    DocumentReference ref = await _firestore.collection('notes').add({
      'title': title,
      'content': content,
      'amount': amount,
    });
    _notes.add({'id': ref.id, 'title': title, 'content': content, 'amount': amount});
    notifyListeners();
  }

  Future<void> editNote(String id, String title, String content, double amount) async {
    await _firestore.collection('notes').doc(id).update({
      'title': title,
      'content': content,
      'amount': amount,
    });
    int index = _notes.indexWhere((note) => note['id'] == id);
    if (index != -1) {
      _notes[index] = {'id': id, 'title': title, 'content': content, 'amount': amount};
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection('notes').doc(id).delete();
    _notes.removeWhere((note) => note['id'] == id);
    notifyListeners();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _userRole;
  Future<String>? _roleFuture;

  User? get user => _firebaseAuth.currentUser;
  String? get userRole => _userRole;

  AuthProvider() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    print("_onAuthStateChanged: ${user != null ? user.uid : 'null'}");
    if (user != null) {
      _user = user;
      print("User signed in: ${user.uid}");
      _roleFuture = _fetchUserRole(user.uid);
      await _roleFuture;
    } else {
      print("User signed out");
      _user = null;
      _userRole = null;
      _roleFuture = null;
      notifyListeners();
    }
  }

  Future<String> _fetchUserRole(String uid) async {
    try {
      print("Fetching user role for: $uid");
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _userRole = userDoc.get('role');
        print("Fetched user role: $_userRole");
      } else {
        _userRole = 'user'; // default role
        print("User role not found, defaulting to 'user'");
      }
    } catch (e) {
      _userRole = 'user'; // default role in case of error
      print("Error fetching user role: $e, defaulting to 'user'");
    }
    notifyListeners();
    print("notifyListeners called in _fetchUserRole");
    return _userRole!;
  }

  Future<String> getRoleFuture() {
    print("getRoleFuture called");
    if (_roleFuture == null && _user != null) {
      _roleFuture = _fetchUserRole(_user!.uid);
    }
    return _roleFuture ?? Future.value('user');
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
      print("User signed in with email: $email");
      _roleFuture = _fetchUserRole(_user!.uid);
      await _roleFuture;
    } catch (e) {
      print("Login failed: $e");
      throw Exception('Login Failed: ${e.toString()}');
    }
  }

  Future<void> signUpWithEmailPassword(
      String email, String password, String name) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;
      print("User registered with email: $email");
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .set({'email': email, 'role': 'user', 'name': name, 'interest': 0.0});
      _roleFuture = _fetchUserRole(_user!.uid);
      await _roleFuture;
    } catch (e) {
      print("Registration failed: $e");
      throw Exception('Registration Failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _user = null;
    _userRole = null;
    _roleFuture = null;
    notifyListeners();
  }
}

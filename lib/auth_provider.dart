import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  AuthProvider() {
    // Listen to auth state changes directly
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  /// Sign Up with improved error handling
  Future<void> signUp(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore 'users' collection
      // Using set with merge to be safe
      await _db.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw "An unexpected error occurred. Please try again.";
    }
  }

  /// Login with improved error handling
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Update last login
      if (currentUser != null) {
        _db.collection('users').doc(currentUser!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).catchError((_) {}); // Ignore error on this background task
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw "An unexpected error occurred.";
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Helper to parse Firebase exceptions into user-friendly messages
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-email':
      case 'wrong-password':
      case 'invalid-credential':
        return "Invalid email or password.";
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'weak-password':
        return "Password should be at least 6 characters.";
      case 'network-request-failed':
        return "Please check your internet connection.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      default:
        return e.message ?? "Authentication failed.";
    }
  }
}
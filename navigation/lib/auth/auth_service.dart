import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password complexity (at least 6 characters)
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Sign up user with email, password, and full name
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('All fields are required');
      }
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (!_isValidPassword(password)) {
        throw Exception('Password must be at least 6 characters');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.reload();
        user = _auth.currentUser;

        // Save extra user info to Firestore
        await _firestore.collection('users').doc(user?.uid).set({
          'uid': user?.uid,
          'name': fullName,
          'email': email,
          'photoURL': null,
        });

        log('User created: ${user?.uid}');
        return user;
      } else {
        throw Exception("Failed to create user");
      }
    } catch (e) {
      log('Error creating user: $e');
      rethrow;
    }
  }

  /// Login user with email and password
  Future<User?> loginUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      log('Login error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // Always update Firestore with latest Google info, not just new users
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? googleUser.displayName ?? 'User',
        'email': user.email,
        'photoURL': user.photoURL ?? googleUser.photoUrl,
      }, SetOptions(merge: true));
    }

    return user;
  } catch (e) {
    log('Google sign-in error: $e');
    rethrow;
  }
}


  /// Logout current user
  Future<void> signOut() async {
    await _auth.signOut();
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
  }
}

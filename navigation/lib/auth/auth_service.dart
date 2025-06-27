import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  /// Validates email format and password strength.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // Password must be at least 6 characters, include uppercase, lowercase, and a number
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$');
    return passwordRegex.hasMatch(password);
  }

  /// Creates a new user with the given email and password.
  /// Returns the [User] object on success, throws an exception on failure or invalid input.
  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      // Validate email and password
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (!_isValidPassword(password)) {
        throw Exception(
            'Password must be at least 6 characters with uppercase, lowercase, and a number');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('User created: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      log('Error creating user: $e');
      rethrow;
    }
  }

  /// Logs in a user with the given email and password.
  /// Returns the [User] object on success, throws an exception on failure or invalid input.
  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      // Validate email and password
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (!_isValidPassword(password)) {
        throw Exception(
            'Password must be at least 6 characters with uppercase, lowercase, and a number');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('User logged in: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      log('Error logging in: $e');
      rethrow;
    }
  }

  /// Signs in a user with Google.
  /// Returns the [User] object on success, throws an exception on failure.
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await _auth.signInWithCredential(credential);
      log('User signed in with Google: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      log('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Signs out the current user.
  /// Throws an exception on failure.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      log('User signed out');
    } catch (e) {
      log('Error signing out: $e');
      rethrow;
    }
  }
}
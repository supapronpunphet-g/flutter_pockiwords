import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] createUserWithEmailAndPassword: $email');
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    debugPrint('[AuthService] user created: ${user.uid}');

    await user.updateDisplayName(username.trim());

    // Seed user document.
    await _firestore.collection(FirestoreCollections.users).doc(user.uid).set({
      'username': username.trim(),
      'email': email.trim(),
      'streak': 0,
      'longestStreak': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[AuthService] user doc seeded for ${user.uid}');

    await user.sendEmailVerification(); //firebase ส่งอีเมลให้เอง
    debugPrint('[AuthService] verification email sent to $email');
    return user;
  }

  Future<User> login({required String email, required String password}) async {
    debugPrint('[AuthService] signInWithEmailAndPassword: $email');
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    debugPrint(
      '[AuthService] login ok: ${cred.user?.uid} '
      'verified=${cred.user?.emailVerified}',
    );
    return cred.user!;
  }

  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      debugPrint('[AuthService] resent verification email');
    } else {
      debugPrint('[AuthService] resend skipped — already verified');
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    debugPrint('[AuthService] reloadAndCheckVerified → $verified');
    return verified;
  }

  Future<void> sendPasswordReset(String email) async {
    debugPrint('[AuthService] sendPasswordResetEmail: $email');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    debugPrint('[AuthService] signOut');
    await _auth.signOut();
  }

  /// Map FirebaseAuthException codes to friendly messages.
  static String describeError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'That email address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' => 'No account found for that email.',
        'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Password is too weak (use at least 6 characters).',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => error.message ?? 'Something went wrong. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<String?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile with name
      await result.user?.updateDisplayName(name);
      await result.user?.reload();
      
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'The password is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return 'An error occurred: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // Sign in with email and password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        default:
          return 'An error occurred: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Google sign-in was cancelled.';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    notifyListeners();
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-not-found':
          return 'No user found for that email.';
        default:
          return 'An error occurred: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // Delete account
  Future<String?> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please sign in again to delete your account.';
      }
      return 'An error occurred: ${e.message}';
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }
}

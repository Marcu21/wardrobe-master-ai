import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      if (googleAuth == null) return null;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': name,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign up.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  bool get isGoogleUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ??
      false;

  /// Re-authenticates then deletes all user data and the Auth account.
  /// Pass [password] for email/password accounts; omit for Google accounts.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No signed-in user');

    if (isGoogleUser) {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      if (googleAuth == null) throw Exception('Google sign-in cancelled');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      if (password == null || password.isEmpty) {
        throw Exception('Password required');
      }
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }

    await _deleteAllUserData(user.uid);
    await user.delete();
    await GoogleSignIn().signOut();
  }

  Future<void> _deleteAllUserData(String uid) async {
    final db = FirebaseFirestore.instance;

    // Single-doc delete
    await db.collection('users').doc(uid).delete();

    // Collection sweeps
    await _deleteWhere(db, 'clothing', 'userId', uid);
    await _deleteWhere(db, 'wardrobes', 'userId', uid);
    await _deleteWhere(db, 'outfits', 'user_id', uid);
    await _deleteWhere(db, 'outfit_feedback', 'user_id', uid);
    await _deleteWhere(db, 'trips', 'user_id', uid);
  }

  Future<void> _deleteWhere(
    FirebaseFirestore db,
    String collection,
    String field,
    String uid,
  ) async {
    const limit = 400;
    while (true) {
      final snap = await db
          .collection(collection)
          .where(field, isEqualTo: uid)
          .limit(limit)
          .get();
      if (snap.docs.isEmpty) break;
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < limit) break;
    }
  }
}

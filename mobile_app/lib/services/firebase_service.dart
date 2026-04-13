
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth == null) {
        return null;
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail({required String email, required String password, required String name}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
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

  Future<UserCredential?> signInWithEmail({required String email, required String password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
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

  Future<String?> uploadImageToStorage(Uint8List imageBytes, String folderName) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference ref = FirebaseStorage.instance.ref().child(folderName).child(fileName);
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/png');
      
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading to storage: $e');
      return null;
    }
  }

  Future<void> saveItem({
    required String imageUrl,
    required Map<String, dynamic> metadata,
  }) async {
    // Prepare data for Firestore
    Map<String, dynamic> itemData = {
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser?.uid,
      ...metadata,
    };

    // Save to Firestore
    try {
      await _firestore.collection('clothing').add(itemData);
      debugPrint("Item saved to Firestore");
    } catch (e) {
      debugPrint("Firestore save failed: $e");
      throw Exception("Failed to save item to wardrobe: $e");
    }
  }

  Future<void> updateItem(String docId, Map<String, dynamic> newMetadata) async {
    try {
      // Create a map to update specific fields without wiping the whole document
      // We assume newMetadata contains the structure for basic_info, styling_info, etc.
      // We might want to flatten it or just merge.
      // Since we are passing the whole structure from the details screen, standard merge is fine.
      
      await _firestore.collection('clothing').doc(docId).update(newMetadata);
      debugPrint("Item updated in Firestore: $docId");
    } catch (e) {
      debugPrint("Firestore update failed: $e");
      throw Exception("Failed to update item: $e");
    }
  }

  Future<void> deleteItem(String docId, {String? imageUrl}) async {
    try {
      // Delete image from storage if it's a Firebase Storage URL
      if (imageUrl != null && imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
        try {
          final Reference ref = _storage.refFromURL(imageUrl);
          await ref.delete();
          debugPrint("Image deleted from Firebase Storage");
        } catch (e) {
          debugPrint("Failed to delete image: $e");
          // Proceed with document deletion even if image deletion fails
        }
      }

      // Delete document from Firestore
      await _firestore.collection('clothing').doc(docId).delete();
      debugPrint("Item deleted from Firestore: $docId");
    } catch (e) {
      debugPrint("Firestore delete failed: $e");
      throw Exception("Failed to delete item: $e");
    }
  }
  Future<List<Map<String, dynamic>>> getItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      // Firestore 'in' query supports up to 10 items. 
      // If we have more, we might need to batch or loop. 
      // For an outfit (usually 3-5 items), this is fine.
      // If we expect more, we should split the list.
      
      List<Map<String, dynamic>> items = [];
      
      // Process in chunks of 10 just to be safe
      for (var i = 0; i < ids.length; i += 10) {
        var end = (i + 10 < ids.length) ? i + 10 : ids.length;
        var chunk = ids.sublist(i, end);
        
        var querySnapshot = await _firestore
            .collection('clothing')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in querySnapshot.docs) {
          var data = doc.data();
          data['id'] = doc.id; // Ensure ID is included
          items.add(data);
        }
      }
      return items;
    } catch (e) {
      debugPrint("Error fetching items by IDs: $e");
      return [];
    }
  }
  Future<void> saveOutfit(Map<String, dynamic> outfitData) async {
    try {
      // Ensure required fields are present
      final data = {
        ...outfitData,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': _auth.currentUser?.uid ?? 'unknown_user',
      };

      await _firestore.collection('outfits').add(data);
      debugPrint("Outfit saved to Firestore");
    } catch (e) {
      debugPrint("Failed to save outfit: $e");
      throw Exception("Failed to save outfit: $e");
    }
  }
}

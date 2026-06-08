import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsService {
  final _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  Future<bool> getPrioritizeNeglected() async {
    final doc = await _userDoc?.get();
    return (doc?.data()?['prioritize_neglected'] as bool?) ?? true;
  }

  Future<void> setPrioritizeNeglected(bool value) async {
    await _userDoc?.set({'prioritize_neglected': value}, SetOptions(merge: true));
  }
}

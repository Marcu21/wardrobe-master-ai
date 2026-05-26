import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImageToStorage(
    Uint8List imageBytes,
    String folderName,
  ) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference ref = _storage.ref().child(folderName).child(fileName);
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/png',
      );
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading to storage: $e');
      return null;
    }
  }
}

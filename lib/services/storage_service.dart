import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: kIsWeb
            ? ImageSource.gallery
            : (fromCamera ? ImageSource.camera : ImageSource.gallery),
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      debugPrint('Pick image error: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePhoto(XFile imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Pakai UID sebagai nama file supaya konsisten
      final ref = _storage.ref().child('profile_photos/$uid.jpg');
      final bytes = await imageFile.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}

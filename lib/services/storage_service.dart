import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Fungsi untuk memilih gambar
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

  /// Fungsi internal untuk upload ke folder tertentu
  Future<String?> _uploadToFolder(XFile imageFile, String folderName) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Menggunakan timestamp agar file tidak saling menimpa
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${uid}_$timestamp.jpg';
      
      // Mengarahkan ke folder sesuai parameter (builder_photo atau profile_photos)
      final ref = _storage.ref().child('$folderName/$fileName');
      
      final bytes = await imageFile.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error di $folderName: $e');
      return null;
    }
  }

  /// Panggil ini dari profile_page.dart
  Future<String?> uploadProfilePhoto(XFile imageFile) async {
    return await _uploadToFolder(imageFile, 'profile_photos');
  }

  /// Panggil ini dari cv_builder_page.dart
  Future<String?> uploadCVPhoto(XFile imageFile) async {
    return await _uploadToFolder(imageFile, 'builder_photo');
  }
}
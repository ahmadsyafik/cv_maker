import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _profileImage = '';
  bool _isLoading = false;

  // Getters
  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get profileImage => _profileImage;
  bool get isLoading => _isLoading;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  DocumentReference? get _doc => _uid != null
      ? FirebaseFirestore.instance.collection('users').doc(_uid)
      : null;

  // Load user data dari Firestore
  Future<void> loadUserData() async {
    if (_doc == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _doc!.get();
      if (!snap.exists) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = snap.data() as Map<String, dynamic>;

      // Prioritas: data dari Firestore > data dari Firebase Auth
      _fullName = data['fullName'] ??
          FirebaseAuth.instance.currentUser?.displayName ??
          '';
      _email = data['email'] ??
          FirebaseAuth.instance.currentUser?.email ??
          '';
      _phone = data['phone'] ?? '';
      _profileImage = data['photoUrl'] ??
          FirebaseAuth.instance.currentUser?.photoURL ??
          '';
    } catch (e) {
      debugPrint('Load user data error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update profil user
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    if (fullName != null) _fullName = fullName;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (profileImage != null) _profileImage = profileImage;

    notifyListeners();
    await _saveToFirestore();
  }

  // Update foto profil
  Future<void> updateProfileImage(String imageUrl) async {
    _profileImage = imageUrl;
    notifyListeners();
    await _saveToFirestore();
  }

  // Simpan ke Firestore
  Future<void> _saveToFirestore() async {
    if (_doc == null) return;
    try {
      await _doc!.set({
        'fullName': _fullName,
        'email': _email,
        'phone': _phone,
        'photoUrl': _profileImage,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save user data error: $e');
    }
  }

  // Reset saat logout
  void reset() {
    _fullName = '';
    _email = '';
    _phone = '';
    _profileImage = '';
    notifyListeners();
  }
}
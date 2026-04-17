import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _profileImage = '';

  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get profileImage => _profileImage;

  // Method untuk load user data (alternatif nama)
  Future<void> loadUserData() async {
    await fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _fullName = data['fullName'] ?? user.displayName ?? '';
        _email = user.email ?? '';
        _phone = data['phone'] ?? '';
        _profileImage = user.photoURL ?? data['profileImage'] ?? '';
        notifyListeners();
      } else {
        // If document doesn't exist, create it
        await _createUserDocument(user);
      }
    }
  }

  // Create user document if not exists
  Future<void> _createUserDocument(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.set({
      'fullName': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': '',
      'profileImage': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'Aktif',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await fetchUserData(); // Refresh data
  }

  // Update profile (only name and phone)
  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update displayName di Firebase Auth
        await user.updateDisplayName(fullName);
        
        // Update di Firestore
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final updateData = {
          'fullName': fullName,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (phone != null && phone.isNotEmpty) {
          updateData['phone'] = phone;
        }
        
        await userDoc.update(updateData);
        
        // Refresh data lokal
        await fetchUserData();
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Update profile image
  Future<void> updateProfileImage(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update photoURL di Firebase Auth
        await user.updatePhotoURL(imageUrl);
        
        // Update di Firestore
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.update({
          'profileImage': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Refresh data lokal
        await fetchUserData();
      }
    } catch (e) {
      print('Error updating profile image: $e');
      rethrow;
    }
  }

  // Reset user data (for logout)
  void reset() {
    _fullName = '';
    _email = '';
    _phone = '';
    _profileImage = '';
    notifyListeners();
  }
}
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
      try {
        // Refresh user data terlebih dahulu
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _fullName = data['fullName'] ?? refreshedUser?.displayName ?? '';
          _email = refreshedUser?.email ?? user.email ?? '';
          _phone = data['phone'] ?? '';
          
          // PRIORITASKAN dari Firestore dulu, baru dari Auth
          final firestoreImage = data['profileImage'] ?? '';
          final authImage = refreshedUser?.photoURL ?? '';
          
          // Gunakan yang dari Firestore karena lebih reliable
          _profileImage = firestoreImage.isNotEmpty ? firestoreImage : authImage;
          
          print('✅ FetchUserData - Firestore image: $firestoreImage');
          print('✅ FetchUserData - Auth image: $authImage');
          print('✅ FetchUserData - Final image: $_profileImage');
          
          notifyListeners();
        } else {
          // If document doesn't exist, create it
          await _createUserDocument(user);
        }
      } catch (e) {
        print('❌ Error fetching user data: $e');
      }
    }
  }

  // Create user document if not exists
  Future<void> _createUserDocument(User user) async {
    try {
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
      print('✅ User document created for: ${user.uid}');
      await fetchUserData(); // Refresh data
    } catch (e) {
      print('❌ Error creating user document: $e');
    }
  }

  // Method khusus untuk refresh profile image
  Future<void> refreshProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final firestoreImage = userDoc.data()?['profileImage'] ?? '';
          final authImage = refreshedUser?.photoURL ?? '';
          
          // Prioritaskan Firestore
          _profileImage = firestoreImage.isNotEmpty ? firestoreImage : authImage;
          
          // Sinkronkan ke Auth jika Firestore punya gambar tapi Auth tidak
          if (firestoreImage.isNotEmpty && authImage != firestoreImage) {
            await user.updatePhotoURL(firestoreImage);
            print('✅ Synced image from Firestore to Auth: $firestoreImage');
          }
          
          print('✅ RefreshProfileImage - Final image: $_profileImage');
          notifyListeners();
        }
      } catch (e) {
        print('❌ Error refreshing profile image: $e');
      }
    }
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
        
        print('✅ Profile updated for: ${user.uid}');
        
        // Refresh data lokal
        await fetchUserData();
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  // Update profile image
  Future<void> updateProfileImage(String imageUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('📤 Updating profile image to: $imageUrl');
        
        // Update photoURL di Firebase Auth
        await user.updatePhotoURL(imageUrl);
        await user.reload();
        
        // Update di Firestore
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.update({
          'profileImage': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Verifikasi data tersimpan
        final savedDoc = await userDoc.get();
        final savedImage = savedDoc.data()?['profileImage'];
        final authImage = FirebaseAuth.instance.currentUser?.photoURL;
        
        print('✅ Saved image in Firestore: $savedImage');
        print('✅ Saved image in Auth: $authImage');
        
        // Refresh data lokal
        await fetchUserData();
        
        print('✅ Profile image updated successfully');
      }
    } catch (e) {
      print('❌ Error updating profile image: $e');
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
    print('🔄 UserProvider reset - all data cleared');
  }
}
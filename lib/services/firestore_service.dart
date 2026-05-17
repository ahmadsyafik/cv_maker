import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/achievement.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/publication.dart';
import '../models/skill.dart';

class FirestoreService {
  static final FirestoreService _instance =
      FirestoreService._internal();

  factory FirestoreService() => _instance;

  FirestoreService._internal();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  //  USER

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  // HELPERS

  Future<List<Map<String, dynamic>>> _getList(
    String field,
  ) async {
    final doc = await _userDoc.get();

    final data = doc.data();

    if (data == null || data[field] == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(data[field]);
  }

  Future<void> _saveList(
    String field,
    List<Map<String, dynamic>> data,
  ) async {
    await _userDoc.set(
      {
        field: data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _addItem(
    String field,
    Map<String, dynamic> item,
  ) async {
    final existing = await _getList(field);

    existing.add(item);

    await _saveList(field, existing);
  }

  Future<void> _updateItem(
    String field,
    String id,
    Map<String, dynamic> item,
  ) async {
    final existing = await _getList(field);

    final index =
        existing.indexWhere((e) => e['id'] == id);

    if (index == -1) return;

    existing[index] = item;

    await _saveList(field, existing);
  }

  Future<void> _deleteItem(
    String field,
    String id,
  ) async {
    final existing = await _getList(field);

    existing.removeWhere((e) => e['id'] == id);

    await _saveList(field, existing);
  }

  // SAVE ALL CV DATA

  Future<void> saveAllCVData({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String linkedin,
    required String github,
    required String summary,
    required String fotoCV,
    required List<Education> educations,
    required List<Experience> experiences,
    required List<Skill> skills,
    required List<Achievement> achievements,
    required List<Publication> publications,
  }) async {
    try {
      final data = {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'linkedin': linkedin,
        'github': github,
        'summary': summary,
        'fotoCV': fotoCV,
        'pendidikan':
            educations.map((e) => e.toJson()).toList(),
        'pengalaman':
            experiences.map((e) => e.toJson()).toList(),
        'skills':
            skills.map((e) => e.toJson()).toList(),
        'achievements':
            achievements.map((e) => e.toJson()).toList(),
        'publications':
            publications.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _userDoc.set(
        data,
        SetOptions(merge: true),
      );

      debugPrint('✅ CV data saved');
    } catch (e) {
      debugPrint('❌ Save CV error: $e');
      rethrow;
    }
  }

  // LOAD

  Future<Map<String, dynamic>> loadAllCVData() async {
    try {
      final doc = await _userDoc.get();

      if (!doc.exists) {
        return {};
      }

      return doc.data() ?? {};
    } catch (e) {
      debugPrint('❌ Load CV error: $e');
      return {};
    }
  }

  // EDUCATION

  Future<void> addEducation(
    Education education,
  ) async {
    await _addItem(
      'pendidikan',
      education.toJson(),
    );
  }

  Future<void> updateEducation(
    Education education,
  ) async {
    await _updateItem(
      'pendidikan',
      education.id,
      education.toJson(),
    );
  }

  Future<void> deleteEducation(
    String id,
  ) async {
    await _deleteItem('pendidikan', id);
  }

  // EXPERIENCE

  Future<void> addExperience(
    Experience experience,
  ) async {
    await _addItem(
      'pengalaman',
      experience.toJson(),
    );
  }

  Future<void> updateExperience(
    Experience experience,
  ) async {
    await _updateItem(
      'pengalaman',
      experience.id,
      experience.toJson(),
    );
  }

  Future<void> deleteExperience(
    String id,
  ) async {
    await _deleteItem('pengalaman', id);
  }

  // SKILL

  Future<void> addSkill(
    Skill skill,
  ) async {
    await _addItem(
      'skills',
      skill.toJson(),
    );
  }

  Future<void> deleteSkill(
    String id,
  ) async {
    await _deleteItem('skills', id);
  }

  // ACHIEVEMENT 

  Future<void> addAchievement(
    Achievement achievement,
  ) async {
    await _addItem(
      'achievements',
      achievement.toJson(),
    );
  }

  Future<void> updateAchievement(
    Achievement achievement,
  ) async {
    await _updateItem(
      'achievements',
      achievement.id,
      achievement.toJson(),
    );
  }

  Future<void> deleteAchievement(
    String id,
  ) async {
    await _deleteItem('achievements', id);
  }

  // PUBLICATION 

  Future<void> addPublication(
    Publication publication,
  ) async {
    await _addItem(
      'publications',
      publication.toJson(),
    );
  }

  Future<void> updatePublication(
    Publication publication,
  ) async {
    await _updateItem(
      'publications',
      publication.id,
      publication.toJson(),
    );
  }

  Future<void> deletePublication(
    String id,
  ) async {
    await _deleteItem('publications', id);
  }

  Future<void> clearAllData() async {
    await _userDoc.delete();

    debugPrint('✅ All CV data cleared');
  }
}
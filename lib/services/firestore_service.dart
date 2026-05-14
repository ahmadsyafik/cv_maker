import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';
import '../models/achievement.dart';
import '../models/publication.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }
  
  DocumentReference get _userDoc => _firestore.collection('users').doc(_userId);

  // ==================== SAVE ALL CV DATA ====================
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
        'pendidikan': educations.map((e) => e.toMap()).toList(),
        'pengalaman': experiences.map((e) => e.toMap()).toList(),
        'skills': skills.map((e) => e.toMap()).toList(),
        'achievements': achievements.map((e) => e.toMap()).toList(),
        'publications': publications.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _userDoc.set(data, SetOptions(merge: true));
      print('✅ CV data saved to Firestore');
    } catch (e) {
      print('❌ Error saving CV data: $e');
      rethrow;
    }
  }

  // ==================== LOAD ALL CV DATA ====================
  Future<Map<String, dynamic>> loadAllCVData() async {
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) return {};
      
      final data = doc.data() as Map<String, dynamic>;
      print('✅ CV data loaded from Firestore');
      return data;
    } catch (e) {
      print('❌ Error loading CV data: $e');
      return {};
    }
  }

  // ==================== OPERATIONS PENDIDIKAN (Task #2) ====================
  Future<void> addEducation(Education education) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['pendidikan'] ?? [];
    final newList = [...existing, education.toMap()];
    await _userDoc.update({'pendidikan': newList});
  }

  Future<void> updateEducation(Education education) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['pendidikan'] ?? [];
    final index = existing.indexWhere((item) => item['id'] == education.id);
    
    if (index != -1) {
      existing[index] = education.toMap();
      await _userDoc.update({'pendidikan': existing});
    }
  }

  Future<void> deleteEducation(String id) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['pendidikan'] ?? [];
    final newList = existing.where((item) => item['id'] != id).toList();
    await _userDoc.update({'pendidikan': newList});
  }

  // ==================== OPERATIONS PENGALAMAN ====================
  Future<void> addExperience(Experience experience) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['pengalaman'] ?? [];
    final newList = [...existing, experience.toMap()];
    await _userDoc.update({'pengalaman': newList});
  }

  Future<void> updateExperience(Experience experience) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['pengalaman'] ?? [];
    final index = existing.indexWhere((item) => item['id'] == experience.id);
    
    if (index != -1) {
      existing[index] = experience.toMap();
      await _userDoc.update({'pengalaman': existing});
    }
  }

  Future<void> deleteExperience(String id) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['pengalaman'] ?? [];
    final newList = existing.where((item) => item['id'] != id).toList();
    await _userDoc.update({'pengalaman': newList});
  }

  // ==================== OPERATIONS SKILL ====================
  Future<void> addSkill(Skill skill) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['skills'] ?? [];
    final newList = [...existing, skill.toMap()];
    await _userDoc.update({'skills': newList});
  }

  Future<void> deleteSkill(String id) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['skills'] ?? [];
    final newList = existing.where((item) => item['id'] != id).toList();
    await _userDoc.update({'skills': newList});
  }

  // ==================== OPERATIONS ACHIEVEMENT ====================
  Future<void> addAchievement(Achievement achievement) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['achievements'] ?? [];
    final newList = [...existing, achievement.toMap()];
    await _userDoc.update({'achievements': newList});
  }

  Future<void> updateAchievement(Achievement achievement) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['achievements'] ?? [];
    final index = existing.indexWhere((item) => item['id'] == achievement.id);
    
    if (index != -1) {
      existing[index] = achievement.toMap();
      await _userDoc.update({'achievements': existing});
    }
  }

  Future<void> deleteAchievement(String id) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['achievements'] ?? [];
    final newList = existing.where((item) => item['id'] != id).toList();
    await _userDoc.update({'achievements': newList});
  }

  // ==================== OPERATIONS PUBLICATION ====================
  Future<void> addPublication(Publication publication) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['publications'] ?? [];
    final newList = [...existing, publication.toMap()];
    await _userDoc.update({'publications': newList});
  }

  Future<void> updatePublication(Publication publication) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['publications'] ?? [];
    final index = existing.indexWhere((item) => item['id'] == publication.id);
    
    if (index != -1) {
      existing[index] = publication.toMap();
      await _userDoc.update({'publications': existing});
    }
  }

  Future<void> deletePublication(String id) async {
    final doc = await _userDoc.get();
    final List existing = doc.data()?['publications'] ?? [];
    final newList = existing.where((item) => item['id'] != id).toList();
    await _userDoc.update({'publications': newList});
  }

  // ==================== CLEAR ALL DATA ====================
  Future<void> clearAllData() async {
    await _userDoc.delete();
    print('✅ All CV data cleared from Firestore');
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';

enum CVTemplate { ats, creative, modern, minimal }

class CVProvider extends ChangeNotifier {
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _linkedin = '';
  String _github = '';
  String _profileImage = '';
  CVTemplate _selectedTemplate = CVTemplate.ats;
  String _summary = '';
  bool _isLoading = false;

  final List<Education> _educations = [];
  final List<Experience> _experiences = [];
  final List<Skill> _skills = [];

  // Getters
  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String get linkedin => _linkedin;
  String get github => _github;
  String get profileImage => _profileImage;
  String get summary => _summary;
  bool get isLoading => _isLoading;
  CVTemplate get selectedTemplate => _selectedTemplate;
  List<Education> get educations => List.unmodifiable(_educations);
  List<Experience> get experiences => List.unmodifiable(_experiences);
  List<Skill> get skills => List.unmodifiable(_skills);
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference? get _doc => _uid != null
      ? FirebaseFirestore.instance.collection('users').doc(_uid)
      : null;
  Future<void> loadFromFirestore() async {
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
      final cv = data['cvData'] as Map<String, dynamic>? ?? {};
      _fullName = cv['fullName'] ?? data['fullName'] ?? '';
      _email = cv['email'] ?? data['email'] ?? '';
      _phone = cv['phone'] ?? '';
      _address = cv['address'] ?? '';
      _linkedin = cv['linkedin'] ?? '';
      _github = cv['github'] ?? '';
      _summary = cv['summary'] ?? '';
      _profileImage = cv['profileImage'] ?? data['photoUrl'] ?? '';

      final templateStr = cv['template'] ?? 'ats';
      _selectedTemplate = CVTemplate.values.firstWhere(
        (e) => e.name == templateStr,
        orElse: () => CVTemplate.ats,
      );

      _educations.clear();
      final eduList = cv['educations'] as List<dynamic>? ?? [];
      for (final e in eduList) {
        _educations.add(Education.fromJson(Map<String, dynamic>.from(e)));
      }

      _experiences.clear();
      final expList = cv['experiences'] as List<dynamic>? ?? [];
      for (final e in expList) {
        _experiences.add(Experience.fromJson(Map<String, dynamic>.from(e)));
      }

      _skills.clear();
      final skillList = cv['skills'] as List<dynamic>? ?? [];
      for (final e in skillList) {
        _skills.add(Skill.fromJson(Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save semua data ke Firestore
  Future<void> _saveToFirestore() async {
    if (_doc == null) return;
    try {
      await _doc!.set({
        'cvData': {
          'fullName': _fullName,
          'email': _email,
          'phone': _phone,
          'address': _address,
          'linkedin': _linkedin,
          'github': _github,
          'summary': _summary,
          'profileImage': _profileImage,
          'template': _selectedTemplate.name,
          'educations': _educations.map((e) => e.toJson()).toList(),
          'experiences': _experiences.map((e) => e.toJson()).toList(),
          'skills': _skills.map((e) => e.toJson()).toList(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  void setTemplate(CVTemplate template) {
    _selectedTemplate = template;
    notifyListeners();
    _saveToFirestore();
  }

  void updateSummary(String summary) {
    _summary = summary;
    notifyListeners();
    _saveToFirestore();
  }

  void updatePersonalData({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? linkedin,
    String? github,
    String? summary,
  }) {
    if (fullName != null) _fullName = fullName;
    if (email != null) _email = email;
    if (phone != null) _phone = phone;
    if (address != null) _address = address;
    if (linkedin != null) _linkedin = linkedin;
    if (github != null) _github = github;
    if (summary != null) _summary = summary;
    notifyListeners();
    _saveToFirestore();
  }

  void updateProfileImage(String imageUrl) {
    _profileImage = imageUrl;
    notifyListeners();
    _saveToFirestore();
  }

  // ── Education ──────────────────────────────────────────────────────────────
  void addEducation(Education education) {
    _educations.add(education);
    notifyListeners();
    _saveToFirestore();
  }

  void removeEducation(int index) {
    _educations.removeAt(index);
    notifyListeners();
    _saveToFirestore();
  }

  void updateEducation(int index, Education education) {
    _educations[index] = education;
    notifyListeners();
    _saveToFirestore();
  }

  // ── Experience ─────────────────────────────────────────────────────────────
  void addExperience(Experience experience) {
    _experiences.add(experience);
    notifyListeners();
    _saveToFirestore();
  }

  void removeExperience(int index) {
    _experiences.removeAt(index);
    notifyListeners();
    _saveToFirestore();
  }

  void updateExperience(int index, Experience experience) {
    _experiences[index] = experience;
    notifyListeners();
    _saveToFirestore();
  }

  void addSkill(Skill skill) {
    _skills.add(skill);
    notifyListeners();
    _saveToFirestore();
  }

  void removeSkill(int index) {
    _skills.removeAt(index);
    notifyListeners();
    _saveToFirestore();
  }

  double get cvProgress {
    int totalFields = 0;
    int filledFields = 0;

    if (_fullName.isNotEmpty) filledFields++;
    if (_email.isNotEmpty) filledFields++;
    if (_phone.isNotEmpty) filledFields++;
    if (_address.isNotEmpty) filledFields++;
    if (_linkedin.isNotEmpty) filledFields++;
    if (_github.isNotEmpty) filledFields++;
    if (_summary.isNotEmpty) filledFields++;
    totalFields += 7;

    if (_educations.isNotEmpty) {
      filledFields += _educations.length;
      totalFields += _educations.length;
    } else {
      totalFields += 1;
    }

    if (_experiences.isNotEmpty) {
      filledFields += _experiences.length;
      totalFields += _experiences.length;
    } else {
      totalFields += 1;
    }
    if (_skills.isNotEmpty) {
      filledFields += _skills.length.clamp(0, 3);
      totalFields += 3;
    } else {
      totalFields += 3;
    }
    return filledFields / totalFields;
  }

  void resetAll() {
    _fullName = '';
    _email = '';
    _phone = '';
    _address = '';
    _linkedin = '';
    _github = '';
    _profileImage = '';
    _summary = '';
    _selectedTemplate = CVTemplate.ats;
    _educations.clear();
    _experiences.clear();
    _skills.clear();
    notifyListeners();
  }
}

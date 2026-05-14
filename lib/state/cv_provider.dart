import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';
import '../models/achievement.dart';
import '../models/publication.dart';

enum CVTemplate { ats, ats2, creative, creative2 }

class CVProvider extends ChangeNotifier {
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _linkedin = '';
  String _github = '';
  String _fotoCV = '';
  CVTemplate _selectedTemplate = CVTemplate.ats;
  String _summary = '';
  bool _isLoading = false;
  bool _isSaving = false;

  // Gunakan List biasa (bukan final) agar bisa di-reassign
  List<Education> _educations = [];
  List<Experience> _experiences = [];
  List<Skill> _skills = [];
  List<Achievement> _achievements = [];
  List<Publication> _publications = [];

  // Getters
  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String get linkedin => _linkedin;
  String get github => _github;
  String get fotoCV => _fotoCV;
  String get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  CVTemplate get selectedTemplate => _selectedTemplate;
  List<Education> get educations => List.unmodifiable(_educations);
  List<Experience> get experiences => List.unmodifiable(_experiences);
  List<Skill> get skills => List.unmodifiable(_skills);
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  List<Publication> get publications => List.unmodifiable(_publications);
  
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference? get _doc => _uid != null
      ? FirebaseFirestore.instance.collection('users').doc(_uid)
      : null;

  // ==================== LOAD DATA FROM FIRESTORE ====================
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
      _fotoCV = cv['profileImage'] ?? '';
      
      final templateStr = cv['template'] ?? 'ats';
      _selectedTemplate = CVTemplate.values.firstWhere(
        (e) => e.name == templateStr,
        orElse: () => CVTemplate.ats,
      );

      // Load Pendidikan (Task #2 - unlimited via array)
      final eduList = cv['educations'] as List<dynamic>? ?? [];
      _educations = eduList
          .map((e) => Education.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Load Pengalaman (Task #3)
      final expList = cv['experiences'] as List<dynamic>? ?? [];
      _experiences = expList
          .map((e) => Experience.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Load Skills
      final skillList = cv['skills'] as List<dynamic>? ?? [];
      _skills = skillList
          .map((e) => Skill.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Load Achievements
      final achList = cv['achievements'] as List<dynamic>? ?? [];
      _achievements = achList
          .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Load Publications
      final pubList = cv['publications'] as List<dynamic>? ?? [];
      _publications = pubList
          .map((e) => Publication.fromJson(Map<String, dynamic>.from(e)))
          .toList();
          
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SAVE TO FIRESTORE ====================
  Future<void> _saveToFirestore() async {
    if (_doc == null) return;
    if (_isSaving) return; // Prevent multiple simultaneous saves
    
    _isSaving = true;
    
    try {
      await _doc!.set({
        'fullName': _fullName,
        'email': _email,
        'cvData': {
          'fullName': _fullName,
          'email': _email,
          'phone': _phone,
          'address': _address,
          'linkedin': _linkedin,
          'github': _github,
          'summary': _summary,
          'profileImage': _fotoCV,
          'template': _selectedTemplate.name,
          // SIMPAN SEBAGAI ARRAY (Task #2 - unlimited)
          'educations': _educations.map((e) => e.toJson()).toList(),
          'experiences': _experiences.map((e) => e.toJson()).toList(),
          'skills': _skills.map((e) => e.toJson()).toList(),
          'achievements': _achievements.map((e) => e.toJson()).toList(),
          'publications': _publications.map((e) => e.toJson()).toList(),
        }
      }, SetOptions(merge: true));
      
      debugPrint('✅ CV saved to Firestore');
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      _isSaving = false;
    }
  }

  // ==================== PERSONAL DATA METHODS ====================
  void updateCVPhoto(String imageUrl) {
    _fotoCV = imageUrl; 
    notifyListeners();
    _saveToFirestore();
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

  // ==================== EDUCATION METHODS (Task #2 - Unlimited) ====================
  // Pendidikan sudah menggunakan ID dari model, disimpan sebagai ARRAY di Firestore
  
  void addEducation(Education education) {
    // Pastikan education memiliki ID (gunakan Education.create() di UI)
    _educations = [..._educations, education];
    notifyListeners();
    _saveToFirestore();
  }

  void removeEducation(int index) {
    if (index >= 0 && index < _educations.length) {
      _educations = [..._educations]..removeAt(index);
      notifyListeners();
      _saveToFirestore();
    }
  }

  void updateEducation(int index, Education education) {
    if (index >= 0 && index < _educations.length) {
      // Pertahankan ID asli jika education baru tidak memiliki ID
      final updatedEducation = education.id.isNotEmpty 
          ? education 
          : _educations[index].copyWith(
              university: education.university,
              major: education.major,
              startYear: education.startYear,
              endYear: education.endYear,
              gpa: education.gpa,
            );
      _educations = [..._educations];
      _educations[index] = updatedEducation;
      notifyListeners();
      _saveToFirestore();
    }
  }
  
  // Method untuk replace seluruh list pendidikan (saat load dari Firebase)
  void setAllEducations(List<Education> educations) {
    _educations = educations;
    notifyListeners();
  }

  // ==================== EXPERIENCE METHODS ====================
  void addExperience(Experience experience) {
    _experiences = [..._experiences, experience];
    notifyListeners();
    _saveToFirestore();
  }

  void removeExperience(int index) {
    if (index >= 0 && index < _experiences.length) {
      _experiences = [..._experiences]..removeAt(index);
      notifyListeners();
      _saveToFirestore();
    }
  }

  void updateExperience(int index, Experience experience) {
    if (index >= 0 && index < _experiences.length) {
      final updatedExp = experience.id.isNotEmpty 
          ? experience 
          : _experiences[index].copyWith(
              organization: experience.organization,
              position: experience.position,
              startYear: experience.startYear,
              endYear: experience.endYear,
              description: experience.description,
            );
      _experiences = [..._experiences];
      _experiences[index] = updatedExp;
      notifyListeners();
      _saveToFirestore();
    }
  }
  
  void setAllExperiences(List<Experience> experiences) {
    _experiences = experiences;
    notifyListeners();
  }

  // ==================== SKILL METHODS ====================
  void addSkill(Skill skill) {
    _skills = [..._skills, skill];
    notifyListeners();
    _saveToFirestore();
  }

  void removeSkill(int index) {
    if (index >= 0 && index < _skills.length) {
      _skills = [..._skills]..removeAt(index);
      notifyListeners();
      _saveToFirestore();
    }
  }
  
  void setAllSkills(List<Skill> skills) {
    _skills = skills;
    notifyListeners();
  }

  // ==================== ACHIEVEMENT METHODS ====================
  void addAchievement(Achievement achievement) {
    _achievements = [..._achievements, achievement];
    notifyListeners();
    _saveToFirestore();
  }

  void removeAchievement(int index) {
    if (index >= 0 && index < _achievements.length) {
      _achievements = [..._achievements]..removeAt(index);
      notifyListeners();
      _saveToFirestore();
    }
  }

  void updateAchievement(int index, Achievement achievement) {
    if (index >= 0 && index < _achievements.length) {
      final updatedAch = achievement.id.isNotEmpty 
          ? achievement 
          : Achievement(
              id: _achievements[index].id,
              title: achievement.title,
              description: achievement.description,
            );
      _achievements = [..._achievements];
      _achievements[index] = updatedAch;
      notifyListeners();
      _saveToFirestore();
    }
  }
  
  void setAllAchievements(List<Achievement> achievements) {
    _achievements = achievements;
    notifyListeners();
  }

  // ==================== PUBLICATION METHODS ====================
  void addPublication(Publication publication) {
    _publications = [..._publications, publication];
    notifyListeners();
    _saveToFirestore();
  }

  void removePublication(int index) {
    if (index >= 0 && index < _publications.length) {
      _publications = [..._publications]..removeAt(index);
      notifyListeners();
      _saveToFirestore();
    }
  }

  void updatePublication(int index, Publication publication) {
    if (index >= 0 && index < _publications.length) {
      final updatedPub = publication.id.isNotEmpty 
          ? publication 
          : Publication(
              id: _publications[index].id,
              title: publication.title,
              journal: publication.journal,
              year: publication.year,
              url: publication.url,
            );
      _publications = [..._publications];
      _publications[index] = updatedPub;
      notifyListeners();
      _saveToFirestore();
    }
  }
  
  void setAllPublications(List<Publication> publications) {
    _publications = publications;
    notifyListeners();
  }

  // ==================== PROGRESS & RESET ====================
  double get cvProgress {
    int completedItems = 0;
    const int totalItems = 4;

    bool hasPersonalData = (_fullName.isNotEmpty && _fullName != 'Nama Lengkap') &&
        (_email.isNotEmpty && _email != 'email@example.com');
    if (hasPersonalData) completedItems++;

    bool hasValidEducation = _educations.any((edu) => 
      edu.university.isNotEmpty && edu.major.isNotEmpty);
    if (hasValidEducation) completedItems++;

    bool hasValidExperience = _experiences.any((exp) => 
      exp.organization.isNotEmpty && exp.position.isNotEmpty);
    if (hasValidExperience) completedItems++;

    if (_skills.isNotEmpty) completedItems++;

    return completedItems / totalItems;
  }

  void resetAll() {
    _fullName = '';
    _email = '';
    _phone = '';
    _address = '';
    _linkedin = '';
    _github = '';
    _fotoCV = '';
    _summary = '';
    _selectedTemplate = CVTemplate.ats;
    _educations = [];
    _experiences = [];
    _skills = [];
    _achievements = [];
    _publications = [];
    notifyListeners();
    _saveToFirestore();
  }
  
  // Clear all data (untuk logout)
  void clearAllData() {
    resetAll();
  }
}
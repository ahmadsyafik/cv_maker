import 'package:flutter/material.dart';
import '../models/education.dart';
import '../models/experience.dart';
import '../models/skill.dart';

enum CVTemplate {
  ats,
  creative,
  modern,
  minimal
}

class CVProvider extends ChangeNotifier {
  // Personal Data
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _linkedin = '';
  String _github = '';
  String _profileImage = '';
  CVTemplate _selectedTemplate = CVTemplate.ats;
  String _summary = ''; // Ringkasan profesional untuk template ATS

  // Lists
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
  CVTemplate get selectedTemplate => _selectedTemplate;
  List<Education> get educations => List.unmodifiable(_educations);
  List<Experience> get experiences => List.unmodifiable(_experiences);
  List<Skill> get skills => List.unmodifiable(_skills);

  // Template Methods
  void setTemplate(CVTemplate template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  // Summary Methods
  void updateSummary(String summary) {
    _summary = summary;
    notifyListeners();
  }

  // Personal Data Setters
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
  }

  void updateProfileImage(String imagePath) {
    _profileImage = imagePath;
    notifyListeners();
  }

  // Education Methods
  void addEducation(Education education) {
    _educations.add(education);
    notifyListeners();
  }

  void removeEducation(int index) {
    _educations.removeAt(index);
    notifyListeners();
  }

  void updateEducation(int index, Education education) {
    _educations[index] = education;
    notifyListeners();
  }

  // Experience Methods
  void addExperience(Experience experience) {
    _experiences.add(experience);
    notifyListeners();
  }

  void removeExperience(int index) {
    _experiences.removeAt(index);
    notifyListeners();
  }

  void updateExperience(int index, Experience experience) {
    _experiences[index] = experience;
    notifyListeners();
  }

  // Skill Methods
  void addSkill(Skill skill) {
    _skills.add(skill);
    notifyListeners();
  }

  void removeSkill(int index) {
    _skills.removeAt(index);
    notifyListeners();
  }

  // Progress Calculation
  double get cvProgress {
    int totalFields = 0;
    int filledFields = 0;

    // Personal Data (7 fields termasuk summary)
    if (_fullName.isNotEmpty) filledFields++;
    if (_email.isNotEmpty) filledFields++;
    if (_phone.isNotEmpty) filledFields++;
    if (_address.isNotEmpty) filledFields++;
    if (_linkedin.isNotEmpty) filledFields++;
    if (_github.isNotEmpty) filledFields++;
    if (_summary.isNotEmpty) filledFields++;
    totalFields += 7;

    // Education (minimum 1)
    if (_educations.isNotEmpty) {
      filledFields += _educations.length;
      totalFields += _educations.length;
    } else {
      totalFields += 1;
    }

    // Experience (minimum 1)
    if (_experiences.isNotEmpty) {
      filledFields += _experiences.length;
      totalFields += _experiences.length;
    } else {
      totalFields += 1;
    }

    // Skills (minimum 3)
    if (_skills.isNotEmpty) {
      filledFields += _skills.length.clamp(0, 3);
      totalFields += 3;
    } else {
      totalFields += 3;
    }

    return filledFields / totalFields;
  }

  // Reset all data
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
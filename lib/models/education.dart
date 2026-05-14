class Education {
  final String id;
  final String university;
  final String major;
  final String startYear;
  final String endYear;
  final double? gpa;

  Education({
    required this.id,
    required this.university,
    required this.major,
    required this.startYear,
    required this.endYear,
    this.gpa,
  });

  // Factory untuk create baru dengan auto-generate ID
  factory Education.create({
    required String university,
    required String major,
    required String startYear,
    required String endYear,
    double? gpa,
  }) {
    return Education(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      university: university,
      major: major,
      startYear: startYear,
      endYear: endYear,
      gpa: gpa,
    );
  }

  // Copy with untuk edit
  Education copyWith({
    String? id,
    String? university,
    String? major,
    String? startYear,
    String? endYear,
    double? gpa,
  }) {
    return Education(
      id: id ?? this.id,
      university: university ?? this.university,
      major: major ?? this.major,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      gpa: gpa ?? this.gpa,
    );
  }

  // Convert ke JSON untuk Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'university': university,
      'major': major,
      'startYear': startYear,
      'endYear': endYear,
      if (gpa != null) 'gpa': gpa,
    };
  }

  // Convert dari JSON Firestore
  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      university: json['university'] ?? '',
      major: json['major'] ?? '',
      startYear: json['startYear'] ?? '',
      endYear: json['endYear'] ?? '',
      gpa: json['gpa'] != null
          ? (json['gpa'] is int
              ? (json['gpa'] as int).toDouble()
              : json['gpa'] as double)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Education && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
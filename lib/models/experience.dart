class Experience {
  final String id;
  final String organization;
  final String position;
  final String startYear;
  final String endYear;
  final String description;

  Experience({
    required this.id,
    required this.organization,
    required this.position,
    required this.startYear,
    required this.endYear,
    required this.description,
  });

  // Factory untuk create baru
  factory Experience.create({
    required String organization,
    required String position,
    required String startYear,
    required String endYear,
    required String description,
  }) {
    return Experience(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      organization: organization,
      position: position,
      startYear: startYear,
      endYear: endYear,
      description: description,
    );
  }

  // Copy with untuk edit
  Experience copyWith({
    String? id,
    String? organization,
    String? position,
    String? startYear,
    String? endYear,
    String? description,
  }) {
    return Experience(
      id: id ?? this.id,
      organization: organization ?? this.organization,
      position: position ?? this.position,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      description: description ?? this.description,
    );
  }

  // Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization': organization,
      'position': position,
      'startYear': startYear,
      'endYear': endYear,
      'description': description,
    };
  }

  // Convert dari JSON
  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      organization: json['organization'] ?? '',
      position: json['position'] ?? '',
      startYear: json['startYear'] ?? '',
      endYear: json['endYear'] ?? '',
      description: json['description'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Experience && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
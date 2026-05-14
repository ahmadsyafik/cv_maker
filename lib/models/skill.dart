class Skill {
  final String id;
  final String name;

  Skill({
    required this.id,
    required this.name,
  });

  // Factory untuk create baru
  factory Skill.create({required String name}) {
    return Skill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
  }

  // Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Convert dari JSON
  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Skill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
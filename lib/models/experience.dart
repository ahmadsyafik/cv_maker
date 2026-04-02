class Experience {
  String organization;
  String position;
  String startYear;
  String endYear;
  String description;

  Experience({
    required this.organization,
    required this.position,
    required this.startYear,
    required this.endYear,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'organization': organization,
      'position': position,
      'startYear': startYear,
      'endYear': endYear,
      'description': description,
    };
  }

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      organization: json['organization'],
      position: json['position'],
      startYear: json['startYear'],
      endYear: json['endYear'],
      description: json['description'],
    );
  }
}
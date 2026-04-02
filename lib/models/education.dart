class Education {
  String university;
  String major;
  String startYear;
  String endYear;
  double? gpa;

  Education({
    required this.university,
    required this.major,
    required this.startYear,
    required this.endYear,
    this.gpa,
  });

  Map<String, dynamic> toJson() {
    return {
      'university': university,
      'major': major,
      'startYear': startYear,
      'endYear': endYear,
      'gpa': gpa,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      university: json['university'],
      major: json['major'],
      startYear: json['startYear'],
      endYear: json['endYear'],
      gpa: json['gpa'],
    );
  }
}
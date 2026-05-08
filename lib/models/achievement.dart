class Achievement {
  String title;
  String description;

  Achievement({required this.title, this.description = ''});

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
      );
}

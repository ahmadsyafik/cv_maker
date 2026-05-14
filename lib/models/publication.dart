class Publication {
  final String id;
  final String title;
  final String journal;
  final String year;
  final String url;

  Publication({
    required this.id,
    required this.title,
    required this.journal,
    required this.year,
    required this.url,
  });

  // Factory untuk create baru
  factory Publication.create({
    required String title,
    required String journal,
    required String year,
    required String url,
  }) {
    return Publication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      journal: journal,
      year: year,
      url: url,
    );
  }

  // Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'journal': journal,
      'year': year,
      'url': url,
    };
  }

  // Convert dari JSON
  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      journal: json['journal'] ?? '',
      year: json['year'] ?? '',
      url: json['url'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Publication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
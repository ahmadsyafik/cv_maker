class Publication {
  String title;
  String journal;
  String year;
  String url;

  Publication({
    required this.title,
    this.journal = '',
    this.year = '',
    this.url = '',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'journal': journal,
        'year': year,
        'url': url,
      };

  factory Publication.fromJson(Map<String, dynamic> json) => Publication(
        title: json['title'] ?? '',
        journal: json['journal'] ?? '',
        year: json['year'] ?? '',
        url: json['url'] ?? '',
      );
}

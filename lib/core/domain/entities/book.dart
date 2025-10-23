class Book {
  final String id;
  final String title;
  final String? author;
  final String? coverAsset;
  final List<String> genres;

  final String? summary;
  final double? rating;
  final int chapterCount;
  final int? updateAtMillis;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.coverAsset,
    required this.genres,
    this.summary,
    this.rating,
    required this.chapterCount,
    this.updateAtMillis,
  });
}

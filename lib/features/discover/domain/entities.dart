class Book {
  final String id;
  final String title;
  final String? author;
  final String? coverAsset;
  final List<String> genres;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverAsset,
    required this.genres,
  });
}

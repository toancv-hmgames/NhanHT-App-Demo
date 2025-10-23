class ChapterSummary {
  final String bookId;
  final int idx;           // 0..N-1
  final String id;         // chapter id (từ assets)
  final String? title;
  final String path;       // đường dẫn .txt (assets hoặc external)
  final int? length;       // số ký tự (optional)

  ChapterSummary({
    required this.bookId,
    required this.idx,
    required this.id,
    this.title,
    required this.path,
    this.length,
  });
}

import '../../domain/entities/chapter_summary.dart';

class ChapterMapper {
  static ChapterSummary fromRow(Map<String, Object?> r) {
    // đọc đúng tên cột trong DB
    final bookId = r['bookId'] as String;                 // ✅
    final idx = (r['idx'] as num).toInt();
    final title = r['title'] as String?;
    final assetPath = (r['assetPath'] ?? r['path']) as String?; // fallback nếu máy còn DB cũ

    // an toàn: tránh cast null → String
    if (assetPath == null) {
      // log để bắt đúng row lỗi nếu có
      // ignore: avoid_print
      print('ChapterMapper: assetPath is NULL for row=$r');
    }

    // Nếu entity còn field 'id', ta sinh id từ file name (không cần cột riêng trong DB)
    final id = _deriveIdFromAsset(assetPath ?? '');

    return ChapterSummary(
      bookId: bookId,
      idx: idx,
      id: id,                         // ✅ sinh từ assetPath
      title: title,
      path: assetPath ?? '',          // ✅ map assetPath -> path (giữ tương thích entity cũ)
      length: (r['length'] as num?)?.toInt(),
    );
  }

  /// Ví dụ: assets/books/a/chapters/ch_001.txt -> "ch_001"
  static String _deriveIdFromAsset(String p) {
    final name = p.split('/').last;       // ch_001.txt
    final base = name.split('.').first;   // ch_001
    return base.isEmpty ? p : base;
  }
}

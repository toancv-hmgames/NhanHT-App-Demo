import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'data_sources/assets_data_source.dart';
import 'data_sources/local_db.dart';

class ImportJob {
  final AssetsDataSource assets;
  final Database db;

  ImportJob(this.assets, this.db);

  static const int dataVersion = 2;

  Future<void> runOnceIfNeeded() async {
    // check version
    final exist = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM ${LocalDb.tableMeta} "
          "WHERE key='data_version' AND value='$dataVersion'",
    ));
    if (exist == 1) {
      debugPrint('✅ ImportJob skipped — already at version $dataVersion');
      return;
    }

    debugPrint('📚 ImportJob started (v$dataVersion)...');

    // xoa DB cu
    await db.delete(LocalDb.tableBook);
    await db.delete(LocalDb.tableSearch);
    await db.delete(LocalDb.tableChapter);

    // Load books
    final books = await assets.loadBooksJson();
    debugPrint('✅ Loaded books.json: ${books.length} items');

    final batch = db.batch();

    for (final b in books) {
      final id = b['id'] as String;

      try {
        // chapters count
        final chapters = await assets.listChapterFiles(id);
        final realCount = chapters.length;

        batch.insert(LocalDb.tableBook, {
          'id': id,
          'title': b['title'],
          'author': b['author'],
          'coverAsset': b['coverAsset'],
          'genres': (b['genres'] as List?)?.join(',') ?? '',
          'chapterCount': realCount,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'summary': b['summary'],
          'rating': b['rating'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        batch.insert(LocalDb.tableSearch, {
          'bookId': id,
          'title': b['title'],
          'author': b['author'],
          'genres': (b['genres'] as List?)?.join(',') ?? '',
        });

        // 3) Ghi CHAPTERS (ĐÚNG CỘT)
        for (var i = 0; i < chapters.length; i++) {
          final path = chapters[i];                 // vd: assets/books/<id>/ch_001.txt
          final chTitle = _titleFromPath(path) ?? 'Chapter ${i + 1}';
          // final length = await _maybeAssetLength(path); // có thể trả null nếu bạn chưa cần

          batch.insert(LocalDb.tableChapter, {
            'bookId': id,
            'idx': i,
            'title': chTitle,
            'assetPath': path,   // 👈 KHỚP cột trong LocalDb
            'length': null,    // null cũng được
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        debugPrint('✅ Imported book "$id" ($realCount chapters)');
      } catch (e) {
        debugPrint('⚠️ Skipped book "$id" — missing folder or error: $e');
        continue;
      }
    }

    // add new version
    batch.insert(LocalDb.tableMeta, {
      'key': 'data_version',
      'value': '$dataVersion',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await batch.commit(noResult: true);
    debugPrint('🏁 ImportJob completed (v$dataVersion).');
  }

  String? _titleFromPath(String p) {
    final name = p.split('/').last;          // ch_001.txt
    final base = name.split('.').first;      // ch_001
    final numStr = RegExp(r'\d+').stringMatch(base);
    return numStr != null ? 'Chapter $numStr' : null;
  }
}

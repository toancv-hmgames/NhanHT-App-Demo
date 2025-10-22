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
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        batch.insert(LocalDb.tableSearch, {
          'bookId': id,
          'title': b['title'],
          'author': b['author'],
          'genres': (b['genres'] as List?)?.join(',') ?? '',
        });

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
}

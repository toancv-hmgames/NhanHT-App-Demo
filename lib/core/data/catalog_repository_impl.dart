import 'dart:io';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:story_reading_app/core/domain/entities/chapter_summary.dart';

import '../domain/entities/book.dart';
import '../domain/repositories/repositories.dart';
import 'data_sources/local_db.dart';
import 'mappers/book_mapper.dart';
import 'mappers/chapter_mapper.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final Database db;
  final AssetBundle _bundle;

  CatalogRepositoryImpl(this.db, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  @override
  Future<List<Book>> getBooks() async {
    final rows = await db.query(LocalDb.tableBook, orderBy: 'title ASC');
    return rows.map(BookMapper.fromRow).toList();
  }

  @override
  Future<List<Book>> searchBooks(
      {String? q, List<String> genres = const []}) async {
    if (q == null || q.isEmpty) {
      return getBooks();
    }
    final rows = await db.query(
      LocalDb.tableSearch,
      where: 'title MATCH ?',
      whereArgs: ['*$q*'],
    );
    final ids = rows.map((r) => r['bookId'] as String).toList();
    final books = await db.query(LocalDb.tableBook,
        where: 'id IN (${List.filled(ids.length, '?').join(',')})',
        whereArgs: ids);
    return books.map(BookMapper.fromRow).toList();
  }

  @override
  Future<Book> getBookById(String bookId) async {
    final rows = await db.query(
      LocalDb.tableBook,
      where: 'id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Book not found: $bookId');
    }
    return BookMapper.fromRow(rows.first);
  }

  @override
  Future<List<ChapterSummary>> listChapters(String bookId) async {
    final rows = await db.query(
      LocalDb.tableChapter,
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'idx ASC',
    );
    return rows.map(ChapterMapper.fromRow).toList();
  }

  @override
  Future<String> loadChapterText(String bookId, int chapterIdx) async {
    final rows = await db.query(
      LocalDb.tableChapter,
      columns: ['assetPath'],                  // 👈 chỉ lấy cột cần
      where: 'bookId = ? AND idx = ?',
      whereArgs: [bookId, chapterIdx],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Chapter not found: $bookId#$chapterIdx');
    }

    final assetPath = rows.first['assetPath'] as String;  // 👈 dùng assetPath

    if (assetPath.startsWith('assets/')) {
      return _bundle.loadString(assetPath);
    } else {
      final file = File(assetPath);
      return file.readAsString();
    }
  }
}

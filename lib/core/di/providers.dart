// lib/core/di/providers.dart

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sqflite/sqflite.dart';

// Discover (presentation)
import '../../features/discover/presentation/discover_state.dart';
import '../../features/discover/presentation/discover_view_model.dart';

// Book Detail (presentation)
import '../../features/book_detail/presentation/book_detail_state.dart';
import '../../features/book_detail/presentation/book_detail_view_model.dart';

// Core data
import '../data/catalog_repository_impl.dart';
import '../data/data_sources/assets_data_source.dart';
import '../data/data_sources/local_db.dart';
import '../data/import_job.dart';

// Core domain
import '../domain/entities/book.dart';
import '../domain/entities/chapter_summary.dart';
import '../domain/repositories/repositories.dart' as repo;
import '../domain/usecases.dart' as uc;

/// -------------------------------
/// Data sources (assets, db)
/// -------------------------------

/// AssetsDataSource: chỉ phục vụ ImportJob (không dùng trực tiếp ở UI)
final assetsDataSourceProvider = Provider<AssetsDataSource>((ref) {
  return AssetsDataSource(rootBundle);
});

/// SQLite LocalDb + ImportJob (chạy 1 lần khi mở app)
final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await LocalDb.open();

  // Seed/import data vào DB nếu cần
  final assets = ref.read(assetsDataSourceProvider);
  final importer = ImportJob(assets, db);
  await importer.runOnceIfNeeded();

  return db;
});

/// -------------------------------
/// Repository (Clean)
/// -------------------------------

/// Repo thực tế (Future): đợi DB sẵn sàng rồi mới tạo impl
final _catalogRepoFutureProvider =
FutureProvider<repo.CatalogRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CatalogRepositoryImpl(db);
});

/// Repo đồng bộ cho phần còn lại của app, nhưng bên trong sẽ đợi Future
/// Tránh phải đổi code ở ViewModel/UI, đồng thời không trả dữ liệu rỗng tạm thời
final catalogRepoProvider = Provider<repo.CatalogRepository>((ref) {
  final future = ref.watch(_catalogRepoFutureProvider.future);
  return _DeferredCatalogRepository(future);
});

/// Bọc Future<repo> -> repo; mỗi method sẽ chờ repo thực tế sẵn sàng
class _DeferredCatalogRepository implements repo.CatalogRepository {
  _DeferredCatalogRepository(this._innerFuture);
  final Future<repo.CatalogRepository> _innerFuture;

  Future<repo.CatalogRepository> get _r async => await _innerFuture;

  @override
  Future<List<Book>> getBooks() async => (await _r).getBooks();

  @override
  Future<Book> getBookById(String bookId) async =>
      (await _r).getBookById(bookId);

  @override
  Future<List<ChapterSummary>> listChapters(String bookId) async =>
      (await _r).listChapters(bookId);

  @override
  Future<String> loadChapterText(String bookId, int chapterIdx) async =>
      (await _r).loadChapterText(bookId, chapterIdx);

  @override
  Future<List<Book>> searchBooks({String? q, List<String> genres = const []}) async =>
      (await _r).searchBooks(q: q, genres: genres);
}

/// -------------------------------
/// Use cases
/// -------------------------------

final getBooksProvider = Provider<uc.GetBooks>((ref) {
  final r = ref.watch(catalogRepoProvider);
  return uc.GetBooks(repo: r);
});

final searchBooksProvider = Provider<uc.SearchBooks>((ref) {
  final r = ref.watch(catalogRepoProvider);
  return uc.SearchBooks(repo: r);
});

/// (nếu bạn có thêm use case như GetBookById/ListChapters, có thể tạo provider tương tự)

/// -------------------------------
/// Discover (VM + UI state)
/// -------------------------------

final discoverVMProvider =
StateNotifierProvider<DiscoverVM, DiscoverState>((ref) {
  final getBooks = ref.watch(getBooksProvider);
  return DiscoverVM(getBooks);
});

final discoverSearchQueryProvider =
StateProvider.autoDispose<String>((ref) => '');

final discoverCategoryIndexProvider =
StateProvider.autoDispose<int>((_) => 0);

/// -------------------------------
/// Book Detail data (dùng chung repo)
/// -------------------------------

final bookDetailVMProvider =
StateNotifierProvider.autoDispose.family<BookDetailVM, BookDetailState, String>((ref, bookId) {
  final repo = ref.read(catalogRepoProvider);
  final vm = BookDetailVM(repo);
  vm.load(bookId);   // tải 1 lần khi tạo VM
  return vm;
});


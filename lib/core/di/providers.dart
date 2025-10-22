import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/discover/data/data_sources/assets_data_source.dart';
import '../../features/discover/data/data_sources/local_db.dart';
import '../../features/discover/domain/entities.dart' as ent;
import '../../features/discover/domain/repositories.dart' as repo;
import '../../features/discover/domain/usecases.dart' as uc;

import '../../features/discover/data/catalog_repository_impl.dart';
import '../../features/discover/data/import_job.dart';
import '../../features/discover/presentation/discover_view_model.dart';

// Data Sources
// AssetsDataSource đọc file từ assets/
final assetsDataSourceProvider = Provider<AssetsDataSource>((ref) {
  return AssetsDataSource(rootBundle);
});

// SQLite LocalDb
final databaseProvider = FutureProvider<Database>((ref) async {
  final db = await LocalDb.open();

  final assets = ref.read(assetsDataSourceProvider);
  final importer = ImportJob(assets, db);
  await importer.runOnceIfNeeded();
  return db;
});

final catalogRepoProvider = Provider<repo.CatalogRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);

  return dbAsync.when(
    data: (db) => CatalogRepositoryImpl(db),
    loading: () => _FallbackCatalogRepository(),
    error: (_, __) => _FallbackCatalogRepository(),
  );
});

// Use case tokens
final getBooksProvider = Provider<uc.GetBooks>((ref) {
  return uc.GetBooks(repo: ref.watch(catalogRepoProvider));
});

final searchBooksProvider = Provider<uc.SearchBooks>((ref) {
  return uc.SearchBooks(repo: ref.watch(catalogRepoProvider));
});

// Fallback (nếu DB chưa kịp mở)
class _FallbackCatalogRepository implements repo.CatalogRepository {
  @override
  Future<List<ent.Book>> getBooks() async => const [];

  @override
  Future<List<ent.Book>> searchBooks(
          {String? q, List<String> genres = const []}) async =>
      const [];
}

// Discover provider
final discoverVMProvider =
    StateNotifierProvider<DiscoverVM, DiscoverState>((ref) {
  final getBooks = ref.watch(getBooksProvider);
  return DiscoverVM(getBooks);
});

// Search provider
final discoverSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

// Tab categories
final discoverCategoryIndexProvider = StateProvider.autoDispose<int>((_) => 0);

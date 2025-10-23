import 'dart:convert';

import 'package:flutter/material.dart';

class AssetsDataSource {
  final AssetBundle bundle;

  AssetsDataSource(this.bundle);

  // check books.json
  Future<List<Map<String, dynamic>>> loadBooksJson() async {
    final jsonStr = await bundle.loadString('assets/books.json');
    final List data = json.decode(jsonStr);
    return data.cast<Map<String, dynamic>>();
  }

  // check AssetManifest.json
  Future<List<String>> scanBookFolders() async {
    final jsonStr = await bundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(jsonStr);
    final paths =
        manifest.keys.where((p) => p.startsWith('assets/books/')).toList();
    return paths;
  }
  // Chapter path
  Future<List<String>> listChapterFiles(String bookId) async {
    debugPrint('🔎 listChapterFiles($bookId) start');
    final manifestStr = await bundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestStr);

    final prefix = 'assets/books/$bookId/chapters/';
    final chapterPaths = manifest.keys
        .where((p) => p.startsWith(prefix) && p.endsWith('.txt'))
        .toList()
      ..sort();

    debugPrint('✅ listChapterFiles($bookId) found ${chapterPaths.length}');
    return chapterPaths;
  }
}

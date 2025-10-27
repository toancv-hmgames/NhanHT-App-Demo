import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/domain/entities/chapter_summary.dart';
import '../../../share/const_value.dart';
import '../../reader/domain/reading_repository.dart';
import 'reader_state.dart';

class ReaderVM extends StateNotifier<ReaderState> {
  final ReadingRepository _repo;

  final ScrollController scrollController = ScrollController();

  // Danh sách metadata tất cả chương trong sách (idx -> title, etc.)
  List<ChapterSummary> _allChapters = const [];

  // Cache chiều cao thực tế của từng chương (pixel)
  // key: chapterIdx, value: height px
  final Map<int, double> _chapterHeights = {};

  // Debounce lưu progress xuống DB
  Timer? _saveTimer;

  // === Runtime flags / state machine ===
  bool _isRestoringScroll =
      false; // đang cố khôi phục offset đã lưu (chỉ dùng trong init ban đầu)
  bool _suppressActiveDetect =
      false; // tạm thời KHÔNG cho _updateActiveChapterFromScroll() đụng vào activeChapterIdx
  bool _loadingNext = false;
  bool _loadingPrev = false;

  _PrependAdjustInfo? _pendingPrependAdjust;

  ReaderVM({
    required ReadingRepository repo,
    required String bookId,
  })  : _repo = repo,
        super(ReaderState.initial(bookId)) {
    _init(bookId);
  }

  // -------- INIT FLOW --------
  //
  // Đây là flow khi mở ReaderPage từ BookDetail hoặc resume đọc.
  // Yêu cầu:
  // - Load chương đã đọc gần nhất
  // - Khôi phục offset bên trong chương đó
  // - AppBar phải hiển thị đúng chương đó
  // - KHÔNG để _updateActiveChapterFromScroll() ghi đè lung tung trong lúc restore
  //
  Future<void> _init(String bookId) async {
    try {
      // 1. load toàn bộ chapter metadata (SQLite, rất nhanh)
      _allChapters = await _repo.listChapters(bookId);
      if (_allChapters.isEmpty) {
        throw Exception("No chapters");
      }

      // 2. đọc session cũ (để biết đang ở chap nào + offset bao nhiêu)
      final session = await _repo.loadSession(bookId);
      final startChapterIdx = session?.chapterIdx ?? 0;
      final savedOffsetInChapter = session?.scrollOffset ?? 0.0;

      // Lấy title chương ngay lập tức từ metadata (nhanh, không cần content)
      final immediateTitle = _allChapters[startChapterIdx].title ?? '';

      // 3. set state sớm để AppBar có title ngay
      //    Trong giai đoạn này ta CHƯA muốn active detection đè lại.
      _suppressActiveDetect = true;
      _isRestoringScroll = true;

      state = state.copyWith(
        activeChapterIdx: startChapterIdx,
        activeChapterTitle: immediateTitle,
        savedOffsetInActiveChapter: savedOffsetInChapter,
        initLoading: true,
        isLoadingMorePrev: false,
        isLoadingMoreNext: false,
        error: null,
        loadedChapters: const [],
        isRestoring: true,
      );

      // 4. load chương đang đọc + chương kế để cuộn mượt
      final centerChapter = await _loadChapterItem(bookId, startChapterIdx);

      final List<ReaderChapterItem> initialList = [
        centerChapter,
      ];

      final nextIdx = startChapterIdx + 1;
      if (nextIdx < _allChapters.length) {
        final nextChap = await _loadChapterItem(bookId, nextIdx);
        initialList.add(nextChap);
      }

      // 5. cập nhật state với nội dung thật
      state = state.copyWith(
        loadedChapters: initialList,
        activeChapterTitle: centerChapter.title,
        initLoading: false,
        isLoadingMorePrev: false,
        isLoadingMoreNext: false,
        error: null,
      );

      // 6. attach listener scroll
      scrollController.addListener(_onScroll);

      // Quan trọng:
      // - _isRestoringScroll = true: chúng ta sẽ nhảy tới offset cũ sau khi đo đủ height
      // - _suppressActiveDetect = true: chặn đổi AppBar lung tung trong giai đoạn khôi phục
    } catch (e) {
      state = state.copyWith(
        initLoading: false,
        error: e,
      );
      _isRestoringScroll = false;
      _suppressActiveDetect = false;
    }
  }

  Future<ReaderChapterItem> _loadChapterItem(
    String bookId,
    int chapterIdx,
  ) async {
    final meta = _allChapters[chapterIdx];
    final content = await _repo.loadChapterText(bookId, chapterIdx);
    return ReaderChapterItem(
      chapterIdx: chapterIdx,
      title: meta.title ?? '',
      content: content,
    );
  }

  Future<void> saveProgress() async {
    await saveProgressNow();
  }

  // -------- SCROLL RESTORE --------
  //
  // Gọi từ reportChapterLayout() sau khi đo height từng chương.
  // Khi đủ thông tin height, nó sẽ jumpTo(savedOffsetInActiveChapter).
  // Sau khi done:
  //   - tắt _isRestoringScroll
  //   - tắt _suppressActiveDetect (cho phép AppBar đổi theo cuộn bình thường)
  //
  void tryRestoreScrollIfNeeded() {
    if (!_isRestoringScroll) return;
    if (!scrollController.hasClients) return;
    if (state.loadedChapters.isEmpty) return;

    final activeChapIdx = state.activeChapterIdx;
    final idxInList = state.loadedChapters.indexWhere(
      (c) => c.chapterIdx == activeChapIdx,
    );
    if (idxInList < 0) return;

    final canComputeAllHeightsBefore = _canComputePrefixHeight(idxInList);
    if (!canComputeAllHeightsBefore) return;

    final prefixHeight = _prefixHeight(idxInList);
    final targetOffset = prefixHeight + state.savedOffsetInActiveChapter;

    scrollController.jumpTo(targetOffset);

    // Done restore. Từ giờ AppBar có thể cập nhật bình thường.
    _isRestoringScroll = false;
    _suppressActiveDetect = false;

    // 👇 thêm dòng này: báo cho UI biết đã ổn, có thể render nội dung thật
    state = state.copyWith(
      isRestoring: false,
      initLoading: false, // chắc chắn initLoading xong ở thời điểm này
    );
  }

  bool _canComputePrefixHeight(int itemCountBefore) {
    for (int i = 0; i < itemCountBefore; i++) {
      final chapIdx = state.loadedChapters[i].chapterIdx;
      if (!_chapterHeights.containsKey(chapIdx)) return false;
    }
    return true;
  }

  double _prefixHeight(int itemCountBefore) {
    double sum = 0;
    for (int i = 0; i < itemCountBefore; i++) {
      final chapIdx = state.loadedChapters[i].chapterIdx;
      sum += _chapterHeights[chapIdx] ?? 0;
    }
    return sum;
  }

  Future<void> _scrollToLoadedListIndex(int listIndex,
      {double insideOffset = 0.0}) async {
    if (!scrollController.hasClients) return;
    if (listIndex < 0 || listIndex >= state.loadedChapters.length) return;

    double targetOffset = 0;
    for (int i = 0; i < listIndex; i++) {
      final chapIdxBefore = state.loadedChapters[i].chapterIdx;
      targetOffset += _chapterHeights[chapIdxBefore] ?? 0.0;
    }

    targetOffset += insideOffset;

    await scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // -------- THEME TOGGLE --------
  void toggleTheme() {
    final nextMode = state.themeMode == ReaderThemeMode.dark
        ? ReaderThemeMode.light
        : ReaderThemeMode.dark;

    state = state.copyWith(themeMode: nextMode);

    // (tuỳ chọn) lưu xuống DB/session để nhớ lựa chọn
    // ví dụ: await _repo.saveReaderPrefs(bookId, nextMode);
  }

  /// Nhảy đến chương có chỉ số 'globalChapterIdx' trong toàn bộ truyện
  /// (tức là _allChapters[globalChapterIdx]).
  ///
  /// - Nếu chương đó đã tồn tại trong state.loadedChapters => tính offset và scroll tới nó.
  /// - Nếu chưa load => chỉ cập nhật state.activeChapterIdx / activeChapterTitle
  ///   để AppBar đổi ngay (tạm thời), nội dung thật sẽ load khi user cuộn/tiếp tục.
  ///
  Future<void> jumpToChapterByGlobalIndex(int globalChapterIdx) async {
    if (globalChapterIdx < 0 || globalChapterIdx >= _allChapters.length) {
      return;
    }

    final meta = _allChapters[globalChapterIdx];
    final pickedTitle = meta.title ?? '';

    final listIndex = state.loadedChapters.indexWhere(
      (it) => it.chapterIdx == globalChapterIdx,
    );

    if (listIndex == -1) {
      state = state.copyWith(
        activeChapterIdx: globalChapterIdx,
        activeChapterTitle: pickedTitle,
        savedOffsetInActiveChapter: 0.0,
      );
      return;
    }

    state = state.copyWith(
      activeChapterIdx: globalChapterIdx,
      activeChapterTitle: pickedTitle,
      savedOffsetInActiveChapter: 0.0,
    );

    await _scrollToLoadedListIndex(listIndex, insideOffset: 0.0);
  }

  /// User chọn chapter từ side panel.
  /// Yêu cầu: reset session đọc sang chapterIdx, đọc từ đầu chương đó.
  /// KHÔNG cố restore offset cũ nữa.
  Future<void> openChapterAsRoot(int chapterIdx) async {
    if (chapterIdx < 0) chapterIdx = 0;
    if (chapterIdx >= _allChapters.length) {
      chapterIdx = _allChapters.length - 1;
    }

    final bookId = state.bookId;

    // Đây KHÔNG phải restore session cũ -> tắt restore.
    _isRestoringScroll = false;

    // Trong lúc rebuild list mới, tắt active-detect để tránh AppBar nhảy loạn.
    _suppressActiveDetect = true;

    // Reset toàn bộ bối cảnh scroll/measure trước đó
    _chapterHeights.clear();
    _pendingPrependAdjust = null;
    _loadingPrev = false;
    _loadingNext = false;

    final immediateTitle = _allChapters[chapterIdx].title ?? '';

    // phase 1: AppBar đổi ngay, body tạm loading
    state = state.copyWith(
      activeChapterIdx: chapterIdx,
      activeChapterTitle: immediateTitle,
      savedOffsetInActiveChapter: 0.0,
      initLoading: true,
      isLoadingMorePrev: false,
      isLoadingMoreNext: false,
      error: null,
      loadedChapters: const [],
    );

    try {
      // Load chương hiện tại
      final centerChapter = await _loadChapterItem(bookId, chapterIdx);

      // Preload chương sau (nếu có)
      final List<ReaderChapterItem> newList = [
        centerChapter,
      ];

      final nextIdx = chapterIdx + 1;
      if (nextIdx < _allChapters.length) {
        final nextChap = await _loadChapterItem(bookId, nextIdx);
        newList.add(nextChap);
      }

      // phase 2: gán list mới vào state
      state = state.copyWith(
        loadedChapters: newList,
        activeChapterIdx: chapterIdx,
        activeChapterTitle: centerChapter.title,
        savedOffsetInActiveChapter: 0.0,
        initLoading: false,
        isLoadingMorePrev: false,
        isLoadingMoreNext: false,
        error: null,
      );

      // Đảm bảo scroll về đầu chương mới
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(0.0);
        }
        // Lúc này list ổn định, ta cho phép detect active theo cuộn trở lại.
        _suppressActiveDetect = false;
      });

      // Ghi session mới (chapterIdx + offset=0)
      await saveProgressNow();
    } catch (e) {
      state = state.copyWith(
        initLoading: false,
        error: e,
      );
      // Nếu fail load, cứ cho phép detect lại để tránh khóa vĩnh viễn
      _suppressActiveDetect = false;
    }
  }

  double? _computeOffsetInsideActiveChapter() {
    if (!scrollController.hasClients) return null;
    if (state.loadedChapters.isEmpty) return null;

    final currentChapterIdx = state.activeChapterIdx;
    final offsetPx = scrollController.offset;

    double runningTop = 0;

    for (final item in state.loadedChapters) {
      final chIdx = item.chapterIdx;
      final h = _chapterHeights[chIdx];

      if (h == null || h <= 0) {
        // height chưa sẵn sàng -> không thể tính chính xác
        return null;
      }

      final chapterTop = runningTop;
      final chapterBottom = runningTop + h;

      if (chIdx == currentChapterIdx) {
        // offset trong chương hiện tại
        final localOffset =
            offsetPx.clamp(chapterTop, chapterBottom) - chapterTop;
        return localOffset;
      }

      runningTop += h;
    }

    // nếu activeChapterIdx không nằm trong loadedChapters (rất hiếm)
    return null;
  }

  // -------- ACTIVE CHAPTER DETECTION (INSTANT APPBAR UPDATE) --------
  //
  // Behavior: đổi title NGAY khi chương mới chạm top.
  // Nhưng: chỉ chạy nếu _suppressActiveDetect == false,
  // vì trong giai đoạn init/jump, height chưa ổn định ⇒ không được override state.activeChapterIdx.
  //
  void _updateActiveChapterFromScroll() {
    if (_suppressActiveDetect) return;
    if (!scrollController.hasClients) return;
    if (state.loadedChapters.isEmpty) return;

    final offsetPx = scrollController.offset;

    double runningTop = 0;
    int? foundChapterIdx;
    String? foundTitle;

    for (final item in state.loadedChapters) {
      final chIdx = item.chapterIdx;
      final h = _chapterHeights[chIdx];

      if (h == null || h <= 0) {
        // chiều cao chưa đo xong -> không kết luận sai
        break;
      }

      final chapterTop = runningTop;
      final chapterBottom = runningTop + h;

      if (offsetPx >= chapterTop && offsetPx < chapterBottom) {
        foundChapterIdx = chIdx;
        foundTitle = item.title;
        break;
      }

      runningTop += h;
    }

    if (foundChapterIdx == null) {
      // Không xác định rõ => giữ nguyên state hiện tại, KHÔNG fallback
      return;
    }

    if (foundChapterIdx == state.activeChapterIdx &&
        foundTitle == state.activeChapterTitle) {
      return;
    }

    state = state.copyWith(
      activeChapterIdx: foundChapterIdx,
      activeChapterTitle: foundTitle ?? state.activeChapterTitle,
      // savedOffsetInActiveChapter sẽ cập nhật trong _scheduleSaveProgress
    );
  }

  // -------- SCROLL LISTENER / INFINITE LOAD --------

  void _onScroll() {
    final pos = scrollController.position;

    // 1. Cập nhật chương active ngay lập tức để AppBar đổi tức thì (nếu được phép)
    _updateActiveChapterFromScroll();

    // 2. near bottom -> load next
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      _loadNextChapter();
    }

    // 3. near top -> load prev
    if (pos.pixels < 100) {
      _loadPrevChapter();
    }

    // 4. debounce save progress xuống DB
    _scheduleSaveProgress();
  }

  Future<void> _loadNextChapter() async {
    if (_loadingNext) return;
    if (state.isLoadingMoreNext) return;
    if (state.loadedChapters.isEmpty) return;

    final lastLoadedIdx = state.loadedChapters.last.chapterIdx;
    final nextIdx = lastLoadedIdx + 1;
    if (nextIdx >= _allChapters.length) return; // hết truyện

    _loadingNext = true;
    state = state.copyWith(isLoadingMoreNext: true);

    try {
      final nextChap = await _loadChapterItem(state.bookId, nextIdx);
      final updated = [...state.loadedChapters, nextChap];
      state = state.copyWith(
        loadedChapters: updated,
        isLoadingMoreNext: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e,
        isLoadingMoreNext: false,
      );
    } finally {
      _loadingNext = false;
    }
  }

  Future<void> _loadPrevChapter() async {
    if (_loadingPrev) return;
    if (state.isLoadingMorePrev) return;
    if (state.loadedChapters.isEmpty) return;

    final firstLoadedIdx = state.loadedChapters.first.chapterIdx;
    final prevIdx = firstLoadedIdx - 1;
    if (prevIdx < 0) return; // không còn chương trước

    _loadingPrev = true;
    state = state.copyWith(isLoadingMorePrev: true);

    try {
      final prevChap = await _loadChapterItem(state.bookId, prevIdx);

      // 1. Ghi lại offset hiện tại.
      final oldOffset =
          scrollController.hasClients ? scrollController.position.pixels : 0.0;

      // 2. Cập nhật list: prepend prevChap
      final updated = [prevChap, ...state.loadedChapters];
      state = state.copyWith(
        loadedChapters: updated,
        isLoadingMorePrev: false,
      );

      // 3. Sau frame build tiếp theo, khi prevChap báo height,
      //    ta cộng height prevChap vào oldOffset để giữ vị trí đọc không nhảy.
      _pendingPrependAdjust = _PrependAdjustInfo(
        newChapterIdx: prevIdx,
        oldScrollOffset: oldOffset,
      );
    } catch (e) {
      state = state.copyWith(
        error: e,
        isLoadingMorePrev: false,
      );
    } finally {
      _loadingPrev = false;
    }
  }

  /// Nhảy tới một chapter đang có trong `state.loadedChapters`,
  /// dựa trên vị trí của nó trong list hiện tại (listIndex).
  Future<void> jumpToChapter(int listIndex) async {
    if (listIndex < 0 || listIndex >= state.loadedChapters.length) {
      return;
    }
    if (!scrollController.hasClients) {
      return;
    }

    final item = state.loadedChapters[listIndex];
    final targetChapterIdx = item.chapterIdx;

    // Tính offset tới đầu phần tử đó
    double targetOffset = 0;
    for (int i = 0; i < listIndex; i++) {
      final beforeChapIdx = state.loadedChapters[i].chapterIdx;
      targetOffset += _chapterHeights[beforeChapIdx] ?? 0.0;
    }

    await scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    final meta = _allChapters[targetChapterIdx];
    final pickedTitle = meta.title ?? '';

    state = state.copyWith(
      activeChapterIdx: targetChapterIdx,
      activeChapterTitle: pickedTitle,
      savedOffsetInActiveChapter: 0.0,
    );
  }

  // -------- SAVE PROGRESS TO DB (DEBOUNCED) --------

  void _scheduleSaveProgress() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      saveProgressNow();
    });
  }

  /// Ghi tiến độ đọc (chương + offset trong chương) xuống DB.
  /// savedOffsetInActiveChapter sẽ được cập nhật dần ở _updateActiveChapterFromScroll()
  /// và logic đo scroll.
  Future<void> saveProgressNow() async {
    if (!scrollController.hasClients) return;
    if (state.loadedChapters.isEmpty) return;

    final pickedChapterIdx = state.activeChapterIdx;

    // Tính offset thực trong chương active, nếu có
    final computedOffset = _computeOffsetInsideActiveChapter();

    final offsetInsidePicked =
        computedOffset ?? state.savedOffsetInActiveChapter;

    // Nếu vừa tính được offset mới và nó khác cái đang giữ trong state,
    // mình update state để lần sau không bị lệch dần.
    if (computedOffset != null &&
        computedOffset != state.savedOffsetInActiveChapter) {
      state = state.copyWith(
        savedOffsetInActiveChapter: computedOffset,
      );
    }

    final session = ReaderSession(
      bookId: state.bookId,
      chapterIdx: pickedChapterIdx,
      scrollOffset: offsetInsidePicked,
    );

    await _repo.saveSession(session);
  }

  // -------- LAYOUT REPORTING --------
  //
  // Gọi khi mỗi ChapterBlock đo được kích thước (chiều cao).
  // - Lưu height vào _chapterHeights
  // - Nếu đang restore initial scroll (_isRestoringScroll == true),
  //   thử nhảy đến offset đã lưu trong session.
  // - Nếu vừa prepend thêm chương ở đầu, bù offset để không bị nhảy ngược.
  // - Cập nhật lại active chapter để AppBar sync với vị trí thật sau layout.
  //
  void reportChapterLayout({
    required int chapterIdx,
    required double heightPx,
  }) {
    final oldHeight = _chapterHeights[chapterIdx];
    _chapterHeights[chapterIdx] = heightPx;

    final heightChanged = (oldHeight == null || oldHeight != heightPx);

    // 1. Thử restore scroll (case mở từ BookDetail/resume)
    tryRestoreScrollIfNeeded();

    // 2. Nếu vừa prepend một chương mới ở đầu list, phải bù offset để không nhảy
    if (_pendingPrependAdjust != null && heightChanged) {
      final info = _pendingPrependAdjust!;
      if (info.newChapterIdx == chapterIdx && scrollController.hasClients) {
        final newOffset = info.oldScrollOffset + heightPx;
        scrollController.jumpTo(newOffset);
        _pendingPrependAdjust = null;
      }
    }

    // 3. Sau khi có height ổn định hơn, update activeChapter theo offset hiện tại
    _updateActiveChapterFromScroll();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}

class _PrependAdjustInfo {
  final int newChapterIdx;
  final double oldScrollOffset;
  _PrependAdjustInfo({
    required this.newChapterIdx,
    required this.oldScrollOffset,
  });
}

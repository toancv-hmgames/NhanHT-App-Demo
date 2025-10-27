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

  // Khi prepend chương ở đầu danh sách, ta cần giữ nguyên viewport
  _PrependAdjustInfo? _pendingPrependAdjust;

  // Ngăn loadPrev quá sớm (tránh vụ "vừa vào chap N mà AppBar nhảy về chap N-1")
  bool _allowLoadPrev = false;

  int? _pendingJumpChapterIdx;

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
      _allowLoadPrev = false;

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
      _allowLoadPrev = true; // cho phép hành vi bình thường nếu init fail
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
  //   - thiết lập _allowLoadPrev dựa trên vị trí thực tế
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

    // Nhảy đến đúng pixel đã lưu
    scrollController.jumpTo(targetOffset);

    // Done restore. Từ giờ AppBar có thể cập nhật bình thường.
    _isRestoringScroll = false;
    _suppressActiveDetect = false;

    // Cho phép loadPrev ngay nếu người dùng thực tế đang ở sâu trong chương
    // (ví dụ targetOffset > 200)
    _allowLoadPrev = targetOffset > 200;

    // Báo cho UI biết: đã khôi phục xong, có thể render mượt
    state = state.copyWith(
      isRestoring: false,
      initLoading: false,
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

  Future<void> _scrollToLoadedListIndex(
      int listIndex, {
        double insideOffset = 0.0,
      }) async {
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

    // (tương lai) có thể lưu xuống DB để nhớ theme người dùng
  }

  /// User bấm "Go to chapter X" trong side panel nhanh:
  /// - Nếu chương đã có trong loadedChapters => scroll tới nó.
  /// - Nếu chưa load => chỉ cập nhật tiêu đề AppBar tạm thời.
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

    _isRestoringScroll = false;
    _suppressActiveDetect = true;

    _allowLoadPrev = false;
    // (bỏ _canLoadPrevDynamically hoàn toàn, chúng ta không dùng nữa)

    // reset bối cảnh cũ
    _chapterHeights.clear();
    _pendingPrependAdjust = null;
    _loadingPrev = false;
    _loadingNext = false;

    final immediateTitle = _allChapters[chapterIdx].title ?? '';

    // phase 1: cập nhật state tối thiểu để AppBar đổi ngay
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
      // load prev / current / next
      ReaderChapterItem? prevChapter;
      if (chapterIdx - 1 >= 0) {
        prevChapter = await _loadChapterItem(bookId, chapterIdx - 1);
      }
      final currentChapter = await _loadChapterItem(bookId, chapterIdx);

      ReaderChapterItem? nextChapter;
      if (chapterIdx + 1 < _allChapters.length) {
        nextChapter = await _loadChapterItem(bookId, chapterIdx + 1);
      }

      final List<ReaderChapterItem> newList = [
        if (prevChapter != null) prevChapter,
        currentChapter,
        if (nextChapter != null) nextChapter,
      ];

      state = state.copyWith(
        loadedChapters: newList,
        activeChapterIdx: chapterIdx,
        activeChapterTitle: currentChapter.title,
        savedOffsetInActiveChapter: 0.0,
        initLoading: false,
        isLoadingMorePrev: false,
        isLoadingMoreNext: false,
        error: null,
      );

      // đánh dấu rằng sau khi layout đo xong height của các chương đứng trước,
      // ta cần nhảy viewport đến đầu chapterIdx (currentChapter).
      _pendingJumpChapterIdx = chapterIdx;

      // lưu session: đang ở chapterIdx, offset = 0
      await saveProgressNow();

      // mở lại detect active sau frame đầu tiên
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _suppressActiveDetect = false;
      });
    } catch (e) {
      state = state.copyWith(
        initLoading: false,
        error: e,
      );
      _suppressActiveDetect = false;
      // fallback: cho phép loadPrev bình thường nếu fail
      _allowLoadPrev = false;
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
    int? bestChapterIdx;
    String? bestTitle;

    for (final item in state.loadedChapters) {
      final chIdx = item.chapterIdx;
      final h = _chapterHeights[chIdx];

      if (h == null || h <= 0) {
        // height chưa đo xong => ta không thể xác định ranh giới kế tiếp,
        // nhưng nếu đã có bestChapterIdx rồi thì giữ nguyên best và dừng vòng lặp.
        break;
      }

      final chapterTop = runningTop;
      final chapterBottom = runningTop + h;

      // nếu offsetPx nằm TRONG chương này -> chọn chương này và kết thúc.
      if (offsetPx >= chapterTop && offsetPx < chapterBottom) {
        bestChapterIdx = chIdx;
        bestTitle = item.title;
        break;
      }

      // nếu offsetPx ở SAU chương này (tức là đã cuộn qua hết chương này),
      // ta tạm thời coi chương này là best fallback.
      if (offsetPx >= chapterBottom) {
        bestChapterIdx = chIdx;
        bestTitle = item.title;
      }

      runningTop += h;
    }

    if (bestChapterIdx == null) {
      // Không xác định rõ => giữ nguyên, KHÔNG ép state
      return;
    }

    if (bestChapterIdx == state.activeChapterIdx &&
        bestTitle == state.activeChapterTitle) {
      return;
    }

    state = state.copyWith(
      activeChapterIdx: bestChapterIdx,
      activeChapterTitle: bestTitle ?? state.activeChapterTitle,
    );
  }


  // -------- SCROLL LISTENER / INFINITE LOAD --------
  //
  // Quy tắc mới:
  // - Nếu _isRestoringScroll == true -> KHÔNG làm gì cả.
  //   (không detect active, không load prev/next, không save progress)
  //   Điều này ngăn việc tự ý prepend chap 1 và ghi session sai lúc vừa mở sách.
  //
  // - Chỉ loadPrev khi:
  //   + người dùng đã cuộn xuống đủ sâu (_allowLoadPrev = true)
  //   + rồi họ kéo ngược lên đầu (pixels < 100)
  //
  void _onScroll() {
    if (!scrollController.hasClients) return;

    final pos = scrollController.position;

    // Đang restore resume-session? Đừng đụng gì.
    if (_isRestoringScroll) {
      return;
    }

    _updateActiveChapterFromScroll();

    // Load chương kế tiếp khi gần chạm đáy -> đọc xuôi
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      _loadNextChapter();
    }

    // Arm/disarm loadPrev cho đọc lùi xa hơn:
    final offset = pos.pixels;

    // Nếu user đã đọc sâu xuống (offset > 400), ta arm:
    if (offset > 400) {
      _allowLoadPrev = true;
    }

    // Nếu user quay lại sát đầu (< 20) và đã arm => prepend thêm 1 chương trước đó
    if (_allowLoadPrev && offset < 20) {
      _allowLoadPrev = false; // disarm cho vòng này
      _loadPrevChapter();
    }

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
  // - Nếu vừa prepend thêm chương ở đầu, bù offset để không bị nhảy
  // - Cập nhật lại active chapter để AppBar sync với vị trí thật sau layout.
  //
  void reportChapterLayout({
    required int chapterIdx,
    required double heightPx,
  }) {
    final oldHeight = _chapterHeights[chapterIdx];
    _chapterHeights[chapterIdx] = heightPx;

    final heightChanged = (oldHeight == null || oldHeight != heightPx);

    // 1. Nếu đang restore session cũ (case mở từ BookDetail/resume)
    tryRestoreScrollIfNeeded();

    // 1b. Nếu vừa openChapterAsRoot(), ta có _pendingJumpChapterIdx.
    //     Ta muốn nhảy viewport đến ĐẦU chương đã chọn (ví dụ chap6),
    //     ngay cả khi danh sách hiện giờ là [5,6,7].
    if (_pendingJumpChapterIdx != null &&
        scrollController.hasClients &&
        state.loadedChapters.isNotEmpty) {
      final targetIdx = _pendingJumpChapterIdx!;
      // xem targetIdx đang đứng ở vị trí thứ mấy trong loadedChapters
      final listPos = state.loadedChapters.indexWhere(
            (it) => it.chapterIdx == targetIdx,
      );
      if (listPos != -1) {
        // kiểm tra đã đo đủ chiều cao của tất cả mục trước nó chưa
        bool canJump = true;
        double offsetBefore = 0;
        for (int i = 0; i < listPos; i++) {
          final beforeChapIdx = state.loadedChapters[i].chapterIdx;
          final h = _chapterHeights[beforeChapIdx];
          if (h == null || h <= 0) {
            canJump = false;
            break;
          }
          offsetBefore += h;
        }
        if (canJump) {
          // Ta muốn đứng đầu chapter được chọn (offsetInChapter = 0)
          scrollController.jumpTo(offsetBefore);
          // sau khi nhảy thành công 1 lần thì clear
          _pendingJumpChapterIdx = null;
        }
      }
    }

    // 2. Nếu vừa prepend 1 chương trước đó
    if (_pendingPrependAdjust != null && heightChanged) {
      final info = _pendingPrependAdjust!;
      if (info.newChapterIdx == chapterIdx && scrollController.hasClients) {
        final newOffset = info.oldScrollOffset + heightPx;
        scrollController.jumpTo(newOffset);
        _pendingPrependAdjust = null;
      }
    }

    // 3. Update activeChapter theo offset hiện tại
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

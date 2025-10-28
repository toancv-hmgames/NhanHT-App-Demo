import '../../../../share/const_value.dart';

class ReaderPrefs {
  final double fontPx;
  final ReaderThemeMode themeMode;
  final ReaderReadingMode readingMode;

  const ReaderPrefs({
    required this.fontPx,
    required this.themeMode,
    required this.readingMode,
  });
}

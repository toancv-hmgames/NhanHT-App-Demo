class AppConsts {
  static const categories = <String>[
    'Hot',
    'New',
    'Romance',
    'Werewolf',
    'Sci-fi Ro',
    'Fantasy',
    'Wuxia'
  ];
  static const normalValue = r'[^a-z0-9]+';
  // book detail
  static const basePadding = 30.0;
  static const extraInset = 20.0;
  static const maxImage = 320.0;
}

// discoverPage UI
const horizontalPadding = 16.0;
const crossAxisSpacing = 16.0;
const coverGap = 8.0;
const titleFontSize = 16.0;
const authorFontSize = 12.0;
const lineHeight = 1.25;
const titleLines = 2;
const authorLines = 1;
const spacingBelow = 5.0;

enum ReaderThemeMode {
  light,
  dark,
}

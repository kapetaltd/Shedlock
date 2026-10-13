import '../core/daily/share_text.dart';
import '../game/palette.dart';

/// 1240 → "1,240".
String formatScore(int n) => formatThousands(n);

/// 140 → "×1.4" ("x1.4" in the retro look).
String formatMultiplier(int percent) {
  final whole = percent ~/ 100;
  final tenths = (percent % 100) ~/ 10;
  return '${Palette.retro ? 'x' : '×'}$whole.$tenths';
}

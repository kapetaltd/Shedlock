import '../core/daily/share_text.dart';

/// 1240 → "1,240".
String formatScore(int n) => formatThousands(n);

/// 140 → "x1.4".
String formatMultiplier(int percent) {
  final whole = percent ~/ 100;
  final tenths = (percent % 100) ~/ 10;
  return 'x$whole.$tenths';
}

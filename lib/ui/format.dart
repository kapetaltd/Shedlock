/// 1240 → "1,240".
String formatScore(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 140 → "x1.4".
String formatMultiplier(int percent) {
  final whole = percent ~/ 100;
  final tenths = (percent % 100) ~/ 10;
  return 'x$whole.$tenths';
}

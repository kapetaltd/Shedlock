// Renders the app icon and splash images from the in-app logo painter
// (lib/ui/widgets/logo_art.dart), so the icon always matches the app:
//
//   flutter test tool/render_icon_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// Lives in tool/ so a normal `flutter test` doesn't rewrite the PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/core/core.dart';
import 'package:shedlock/game/palette.dart';
import 'package:shedlock/ui/widgets/logo_art.dart';

Future<void> _write(String name, int size, {Color? fill, required Look look, double logo = 0.7}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (fill != null) canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = fill);
  final box = s * logo;
  canvas.translate((s - box) / 2, (s - box) / 2);
  LogoMarkPainter(lock: look.ink, snake: look.snake, background: look.background)
      .paint(canvas, Size.square(box));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File('assets/icon/$name').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('render icon and splash', () async {
    final paper = Palette.looks[BoardTheme.paper]!;
    final dusk = Palette.looks[BoardTheme.dusk]!;
    // Full icon (iOS, legacy Android): square, opaque.
    await _write('icon.png', 1024, fill: paper.background, look: paper, logo: 0.74);
    // Android adaptive foreground: inside the 66% safe zone, transparent.
    await _write('icon_foreground.png', 1024, look: paper, logo: 0.56);
    // Native launch screens, light and dark.
    await _write('splash.png', 768, look: paper, logo: 0.86);
    await _write('splash_dark.png', 768, look: dusk, logo: 0.86);
  });
}

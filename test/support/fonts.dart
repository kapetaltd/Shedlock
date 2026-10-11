import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's bundled fonts so rendered PNGs show real text (widget
/// tests otherwise draw every glyph as a box).
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('PressStart2P', ['PressStart2P-Regular.ttf']);
  await load('Nunito', [
    'Nunito-Medium.ttf',
    'Nunito-SemiBold.ttf',
    'Nunito-Bold.ttf',
    'Nunito-ExtraBold.ttf',
  ]);
}

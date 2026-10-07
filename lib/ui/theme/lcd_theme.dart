import 'package:flutter/material.dart';

import '../../game/lcd_palette.dart';

export '../../game/lcd_palette.dart';

const String pixelFont = 'PressStart2P';

/// Pixel text style. Sizes are multiples of 8 at their best, but anything
/// whole works.
TextStyle pixelStyle(double size, {Color? color, double height = 1.4}) =>
    TextStyle(
      fontFamily: pixelFont,
      fontSize: size,
      color: color ?? LcdPalette.ink,
      height: height,
      letterSpacing: 0,
    );

ThemeData buildLcdTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: pixelFont,
    scaffoldBackgroundColor: LcdPalette.screen,
    colorScheme: ColorScheme.light(
      primary: LcdPalette.ink,
      onPrimary: LcdPalette.screen,
      secondary: LcdPalette.inkMid,
      surface: LcdPalette.screen,
      onSurface: LcdPalette.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: pixelFont,
      bodyColor: LcdPalette.ink,
      displayColor: LcdPalette.ink,
    ),
  );
}

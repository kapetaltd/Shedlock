import 'dart:ui';

import '../core/monetization/catalog.dart';

/// One screen colour scheme: a "lit" background with dark ink pixels.
class ScreenPalette {
  const ScreenPalette({
    required this.screen,
    required this.screenDim,
    required this.ghost,
    required this.ink,
    required this.inkMid,
    required this.inkSoft,
    required this.shadow,
  });

  final Color screen;
  final Color screenDim;
  final Color ghost;
  final Color ink;
  final Color inkMid;
  final Color inkSoft;
  final Color shadow;
}

/// The monochrome LCD palette shared by the game renderer and the UI.
/// Original colours. The active scheme follows the player's board theme.
class LcdPalette {
  static const Map<BoardTheme, ScreenPalette> themes = {
    BoardTheme.lime: ScreenPalette(
      screen: Color(0xFFB2C69A),
      screenDim: Color(0xFFA3B98B),
      ghost: Color(0x12203018),
      ink: Color(0xFF1E2A1B),
      inkMid: Color(0xFF4A5F3F),
      inkSoft: Color(0xFF7D9468),
      shadow: Color(0x2E1E2A1B),
    ),
    BoardTheme.amber: ScreenPalette(
      screen: Color(0xFFE6C17E),
      screenDim: Color(0xFFD9B26D),
      ghost: Color(0x14402808),
      ink: Color(0xFF3A2208),
      inkMid: Color(0xFF7A4E1E),
      inkSoft: Color(0xFFA98048),
      shadow: Color(0x2E3A2208),
    ),
    BoardTheme.ice: ScreenPalette(
      screen: Color(0xFFAFCCD6),
      screenDim: Color(0xFF9FBFCA),
      ghost: Color(0x12102A36),
      ink: Color(0xFF102A36),
      inkMid: Color(0xFF3C6476),
      inkSoft: Color(0xFF6F94A3),
      shadow: Color(0x2E102A36),
    ),
    BoardTheme.mono: ScreenPalette(
      screen: Color(0xFFC6C8C1),
      screenDim: Color(0xFFB7BAB2),
      ghost: Color(0x121C1D1B),
      ink: Color(0xFF1C1D1B),
      inkMid: Color(0xFF555852),
      inkSoft: Color(0xFF888B84),
      shadow: Color(0x2E1C1D1B),
    ),
    // Inverted: bright pixels on a dark screen.
    BoardTheme.night: ScreenPalette(
      screen: Color(0xFF162113),
      screenDim: Color(0xFF1D2A19),
      ghost: Color(0x10B6E07E),
      ink: Color(0xFFB6E07E),
      inkMid: Color(0xFF6E9450),
      inkSoft: Color(0xFF4C663A),
      shadow: Color(0x40000000),
    ),
  };

  /// The scheme in use. Set from the player's loadout.
  static ScreenPalette active = themes[BoardTheme.lime]!;

  static void apply(BoardTheme theme) => active = themes[theme]!;

  static Color get screen => active.screen;
  static Color get screenDim => active.screenDim;
  static Color get ghost => active.ghost;
  static Color get ink => active.ink;
  static Color get inkMid => active.inkMid;
  static Color get inkSoft => active.inkSoft;
  static Color get shadow => active.shadow;

  /// Device body around the screen (not themed).
  static const bezel = Color(0xFF262C23);
  static const bezelLight = Color(0xFF3A4235);
}

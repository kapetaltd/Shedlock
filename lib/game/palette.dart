import 'dart:ui';

import '../core/monetization/catalog.dart';

/// Every colour one theme needs, for both the app chrome and the board.
///
/// Modern themes use all of them. Retro LCD themes are monochrome: the
/// snake, food, runners and obstacles are all [ink], and the board is the
/// lit LCD [board] colour with [boardAlt] ghost pixels.
class Look {
  const Look({
    required this.background,
    required this.surface,
    required this.line,
    required this.board,
    required this.boardAlt,
    required this.ink,
    required this.inkMid,
    required this.inkSoft,
    required this.accent,
    required this.onAccent,
    required this.snake,
    required this.snakeAlt,
    required this.food,
    required this.runner,
    required this.obstacle,
    required this.wall,
    required this.shadow,
    this.dark = false,
    this.retro = false,
  });

  /// A monochrome LCD screen: one lit colour and three ink shades.
  const Look.lcd({
    required Color screen,
    required Color ghost,
    required Color ink,
    required Color inkMid,
    required Color inkSoft,
    required Color shadow,
    bool dark = false,
  }) : this(
          background: screen,
          surface: screen,
          line: ink,
          board: screen,
          boardAlt: ghost,
          ink: ink,
          inkMid: inkMid,
          inkSoft: inkSoft,
          accent: ink,
          onAccent: screen,
          snake: ink,
          snakeAlt: inkMid,
          food: ink,
          runner: ink,
          obstacle: ink,
          wall: inkMid,
          shadow: shadow,
          dark: dark,
          retro: true,
        );

  /// Page background.
  final Color background;

  /// Cards, panels and outlined buttons.
  final Color surface;

  /// Hairline borders.
  final Color line;

  /// The playing field, and its grid marks (modern dots / retro ghost
  /// pixels).
  final Color board;
  final Color boardAlt;

  /// Text: primary, secondary, disabled.
  final Color ink;
  final Color inkMid;
  final Color inkSoft;

  /// Primary buttons, meters, selected chips.
  final Color accent;
  final Color onAccent;

  final Color snake;

  /// Pattern colour for snake skins.
  final Color snakeAlt;
  final Color food;
  final Color runner;
  final Color obstacle;
  final Color wall;
  final Color shadow;

  /// Light content on a dark background (status bar icons, etc.).
  final bool dark;

  /// The pixel LCD style: blocky shapes, pixel font, upper-case text.
  final bool retro;
}

/// The active colours, shared by the game renderer and the UI.
/// Original colours. The active look follows the player's theme.
class Palette {
  static const Map<BoardTheme, Look> looks = {
    BoardTheme.paper: Look(
      background: Color(0xFFF5F3EE),
      surface: Color(0xFFFFFFFF),
      line: Color(0xFFE4DFD6),
      board: Color(0xFFFCFBF8),
      boardAlt: Color(0xFFE6E1D7),
      ink: Color(0xFF1F2A2E),
      inkMid: Color(0xFF66737A),
      inkSoft: Color(0xFFAAB2B6),
      accent: Color(0xFF14958C),
      onAccent: Color(0xFFFFFFFF),
      snake: Color(0xFF1AA39A),
      snakeAlt: Color(0xFF117A73),
      food: Color(0xFFF26B5B),
      runner: Color(0xFFF2B13C),
      obstacle: Color(0xFFD9D4CA),
      wall: Color(0xFF9CCFC9),
      shadow: Color(0x241F2A2E),
    ),
    BoardTheme.dusk: Look(
      background: Color(0xFF12161C),
      surface: Color(0xFF1C222B),
      line: Color(0xFF2A323D),
      board: Color(0xFF181D25),
      boardAlt: Color(0xFF29303A),
      ink: Color(0xFFEDF1F4),
      inkMid: Color(0xFF9AA5AF),
      inkSoft: Color(0xFF5B6672),
      accent: Color(0xFF2BC2B5),
      onAccent: Color(0xFF0D1F1D),
      snake: Color(0xFF2BC2B5),
      snakeAlt: Color(0xFF1C8A81),
      food: Color(0xFFFF7A6B),
      runner: Color(0xFFFFC857),
      obstacle: Color(0xFF2E3742),
      wall: Color(0xFF2F6A66),
      shadow: Color(0x66000000),
      dark: true,
    ),
    BoardTheme.sage: Look(
      background: Color(0xFFEDF1E8),
      surface: Color(0xFFFAFBF7),
      line: Color(0xFFD8DFD0),
      board: Color(0xFFF8FAF4),
      boardAlt: Color(0xFFDDE4D5),
      ink: Color(0xFF243127),
      inkMid: Color(0xFF66756A),
      inkSoft: Color(0xFFA8B3A9),
      accent: Color(0xFF4C7A57),
      onAccent: Color(0xFFFFFFFF),
      snake: Color(0xFF4C7A57),
      snakeAlt: Color(0xFF345A3D),
      food: Color(0xFFE07A5F),
      runner: Color(0xFFE5B045),
      obstacle: Color(0xFFD2DACB),
      wall: Color(0xFFA9C2AC),
      shadow: Color(0x22243127),
    ),
    BoardTheme.sand: Look(
      background: Color(0xFFF5ECE0),
      surface: Color(0xFFFFFAF3),
      line: Color(0xFFE6D9C7),
      board: Color(0xFFFFF9F1),
      boardAlt: Color(0xFFEDDFCC),
      ink: Color(0xFF33261C),
      inkMid: Color(0xFF7D6B5C),
      inkSoft: Color(0xFFBCAE9F),
      accent: Color(0xFFC0693A),
      onAccent: Color(0xFFFFFFFF),
      snake: Color(0xFFC0693A),
      snakeAlt: Color(0xFF8F4A25),
      food: Color(0xFF2E8A8F),
      runner: Color(0xFFE2A32E),
      obstacle: Color(0xFFE3D6C3),
      wall: Color(0xFFE2B9A0),
      shadow: Color(0x2233261C),
    ),
    BoardTheme.ink: Look(
      background: Color(0xFF0B0B0D),
      surface: Color(0xFF17171A),
      line: Color(0xFF26262B),
      board: Color(0xFF111114),
      boardAlt: Color(0xFF26262B),
      ink: Color(0xFFF4F4F5),
      inkMid: Color(0xFFA1A1AA),
      inkSoft: Color(0xFF55555C),
      accent: Color(0xFFF4F4F5),
      onAccent: Color(0xFF0B0B0D),
      snake: Color(0xFFF4F4F5),
      snakeAlt: Color(0xFFB4B4BC),
      food: Color(0xFFFF5C5C),
      runner: Color(0xFFFFD23F),
      obstacle: Color(0xFF27272C),
      wall: Color(0xFF4A4A52),
      shadow: Color(0x80000000),
      dark: true,
    ),
    BoardTheme.lime: Look.lcd(
      screen: Color(0xFFB2C69A),
      ghost: Color(0x12203018),
      ink: Color(0xFF1E2A1B),
      inkMid: Color(0xFF4A5F3F),
      inkSoft: Color(0xFF7D9468),
      shadow: Color(0x2E1E2A1B),
    ),
    BoardTheme.amber: Look.lcd(
      screen: Color(0xFFE6C17E),
      ghost: Color(0x14402808),
      ink: Color(0xFF3A2208),
      inkMid: Color(0xFF7A4E1E),
      inkSoft: Color(0xFFA98048),
      shadow: Color(0x2E3A2208),
    ),
    BoardTheme.ice: Look.lcd(
      screen: Color(0xFFAFCCD6),
      ghost: Color(0x12102A36),
      ink: Color(0xFF102A36),
      inkMid: Color(0xFF3C6476),
      inkSoft: Color(0xFF6F94A3),
      shadow: Color(0x2E102A36),
    ),
    BoardTheme.mono: Look.lcd(
      screen: Color(0xFFC6C8C1),
      ghost: Color(0x121C1D1B),
      ink: Color(0xFF1C1D1B),
      inkMid: Color(0xFF555852),
      inkSoft: Color(0xFF888B84),
      shadow: Color(0x2E1C1D1B),
    ),
    // Inverted: bright pixels on a dark screen.
    BoardTheme.night: Look.lcd(
      screen: Color(0xFF162113),
      ghost: Color(0x10B6E07E),
      ink: Color(0xFFB6E07E),
      inkMid: Color(0xFF6E9450),
      inkSoft: Color(0xFF4C663A),
      shadow: Color(0x40000000),
      dark: true,
    ),
  };

  /// The theme in use, already resolved (never [BoardTheme.auto]).
  static BoardTheme theme = BoardTheme.paper;
  static Look active = looks[BoardTheme.paper]!;

  /// Switches the look. [systemDark] decides what [BoardTheme.auto] means.
  /// Returns whether anything changed.
  static bool apply(BoardTheme choice, {bool systemDark = false}) {
    final resolved = choice.resolve(systemDark: systemDark);
    if (resolved == theme) return false;
    theme = resolved;
    active = looks[resolved]!;
    return true;
  }

  static bool get retro => active.retro;
  static bool get dark => active.dark;

  static Color get background => active.background;
  static Color get surface => active.surface;
  static Color get line => active.line;
  static Color get board => active.board;
  static Color get boardAlt => active.boardAlt;
  static Color get ink => active.ink;
  static Color get inkMid => active.inkMid;
  static Color get inkSoft => active.inkSoft;
  static Color get accent => active.accent;
  static Color get onAccent => active.onAccent;
  static Color get snake => active.snake;
  static Color get snakeAlt => active.snakeAlt;
  static Color get food => active.food;
  static Color get runner => active.runner;
  static Color get obstacle => active.obstacle;
  static Color get wall => active.wall;
  static Color get shadow => active.shadow;
}

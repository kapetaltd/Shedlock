import 'dart:ui';

/// The monochrome LCD palette shared by the game renderer and the UI.
/// Original colours: a warm green-grey "lit" screen with dark ink pixels.
class LcdPalette {
  /// The lit screen background.
  static const screen = Color(0xFFB2C69A);

  /// Slightly darker screen, for panels.
  static const screenDim = Color(0xFFA3B98B);

  /// "Unlit" pixel ghosting drawn on every empty cell.
  static const ghost = Color(0x12203018);

  /// Fully dark pixels.
  static const ink = Color(0xFF1E2A1B);

  /// Mid-tone pixels (shed walls, secondary text).
  static const inkMid = Color(0xFF4A5F3F);

  /// Light-tone pixels (hints, disabled).
  static const inkSoft = Color(0xFF7D9468);

  /// LCD drop shadow under dark pixels.
  static const shadow = Color(0x2E1E2A1B);

  /// Device body around the screen.
  static const bezel = Color(0xFF262C23);
  static const bezelLight = Color(0xFF3A4235);
}

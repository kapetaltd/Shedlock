import 'package:flutter/material.dart';

import '../../game/palette.dart';

export '../../game/palette.dart';

const String pixelFont = 'PressStart2P';
const String modernFont = 'Nunito';

/// What a piece of text is for. Each look picks its own font, size and
/// weight per role, so screens never hard-code type sizes.
enum TextRole {
  /// The big number on result screens (score, daily number).
  display,

  /// The app name on the home and splash screens.
  hero,

  /// Screen titles.
  title,

  /// Section headings and card titles.
  heading,

  /// Running text.
  body,

  /// Small secondary text (labels over values, hints, footnotes).
  caption,

  /// Main button labels.
  button,

  /// Smaller button labels and inline emphasis.
  label,

  /// The in-game score.
  score,
}

typedef _Spec = (double size, FontWeight weight, double height);

const Map<TextRole, _Spec> _retro = {
  TextRole.display: (36, FontWeight.w400, 1.4),
  TextRole.hero: (32, FontWeight.w400, 1.4),
  TextRole.title: (20, FontWeight.w400, 1.4),
  TextRole.heading: (12, FontWeight.w400, 1.5),
  TextRole.body: (8, FontWeight.w400, 1.9),
  TextRole.caption: (8, FontWeight.w400, 1.6),
  TextRole.button: (14, FontWeight.w400, 1.4),
  TextRole.label: (10, FontWeight.w400, 1.4),
  TextRole.score: (18, FontWeight.w400, 1.4),
};

const Map<TextRole, _Spec> _modern = {
  TextRole.display: (52, FontWeight.w800, 1.1),
  TextRole.hero: (44, FontWeight.w800, 1.1),
  TextRole.title: (28, FontWeight.w800, 1.2),
  TextRole.heading: (18, FontWeight.w700, 1.3),
  TextRole.body: (15, FontWeight.w500, 1.45),
  TextRole.caption: (13, FontWeight.w600, 1.35),
  TextRole.button: (18, FontWeight.w800, 1.2),
  TextRole.label: (15, FontWeight.w700, 1.25),
  TextRole.score: (30, FontWeight.w800, 1.1),
};

/// The text style for [role] in the active look. Captions default to the
/// secondary ink colour, everything else to the primary one.
TextStyle textStyle(TextRole role, {Color? color, double? size}) {
  final retro = Palette.retro;
  final (s, w, h) = (retro ? _retro : _modern)[role]!;
  return TextStyle(
    fontFamily: retro ? pixelFont : modernFont,
    fontSize: size ?? s,
    fontWeight: w,
    height: h,
    letterSpacing: retro ? 0 : (s >= 28 ? -0.5 : 0),
    color: color ?? (role == TextRole.caption ? Palette.inkMid : Palette.ink),
    fontFeatures: retro ? null : const [FontFeature.tabularFigures()],
  );
}

/// UI copy is written in sentence case; the retro look shows it in caps.
String say(String text) => Palette.retro ? text.toUpperCase() : text;

/// Text in a [TextRole], cased for the active look.
class Txt extends StatelessWidget {
  const Txt(
    this.text, {
    super.key,
    this.role = TextRole.body,
    this.color,
    this.align,
    this.size,
  });

  final String text;
  final TextRole role;
  final Color? color;
  final TextAlign? align;
  final double? size;

  @override
  Widget build(BuildContext context) =>
      Text(say(text), textAlign: align, style: textStyle(role, color: color, size: size));
}

/// Corner radius for cards and buttons: square in retro, soft in modern.
double get cornerRadius => Palette.retro ? 0 : 18;

/// A soft shadow under cards in modern looks (none in retro, where the
/// widgets draw their own hard offset shadow).
List<BoxShadow> get softShadow => Palette.retro
    ? const []
    : [
        BoxShadow(
          color: Palette.shadow,
          blurRadius: Palette.dark ? 18 : 22,
          offset: const Offset(0, 6),
        ),
      ];

/// Fade plus a short upward slide: calm, and the same on every platform.
class _FadeRise extends PageTransitionsBuilder {
  const _FadeRise();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData buildAppTheme() {
  final font = Palette.retro ? pixelFont : modernFont;
  final base = ThemeData(
    useMaterial3: true,
    brightness: Palette.dark ? Brightness.dark : Brightness.light,
    fontFamily: font,
    scaffoldBackgroundColor: Palette.background,
    colorScheme: (Palette.dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: Palette.accent,
      onPrimary: Palette.onAccent,
      secondary: Palette.inkMid,
      surface: Palette.background,
      onSurface: Palette.ink,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {for (final p in TargetPlatform.values) p: _FadeRise()},
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: font,
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
  );
}

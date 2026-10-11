import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../game/snake_skin_painter.dart';
import '../../services/iap_service.dart';
import '../../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

/// Remove Ads, cosmetic packs, and choosing what to wear.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _packInfo = {
    Pack.removeAds: ('Remove Ads', 'No more break ads between runs.\nRewind ads stay optional.'),
    Pack.skins: ('Skin Pack', 'Striped, spotted and outline snakes.'),
    Pack.trails: ('Trail Pack', 'Ghost and sparkle trails.'),
    Pack.themes: ('Theme Pack', 'Sage, Sand and Ink, plus the full Retro LCD look in five colours.'),
  };

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final iap = services.iap;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([iap.owned, iap.offers, iap.message, services.loadout]),
          builder: (context, _) {
            final owned = iap.owned.value;
            final offers = iap.offers.value;
            final loadout = services.loadout.value;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    const Center(child: Txt('Shop', role: TextRole.title)),
                    const SizedBox(height: 8),
                    const Center(
                      child: Txt('All items are cosmetic.\nNo gameplay advantage.',
                          role: TextRole.caption, align: TextAlign.center),
                    ),
                    // Fixed-height slot so the page doesn't jump when a
                    // store message appears.
                    SizedBox(
                      height: 36,
                      child: Center(child: Txt(iap.message.value ?? '', role: TextRole.caption, color: Palette.ink)),
                    ),
                    for (final pack in Pack.values) ...[
                      _PackCard(
                        title: _packInfo[pack]!.$1,
                        body: _packInfo[pack]!.$2,
                        owned: owned.contains(pack),
                        offer: offers[pack],
                        onBuy: () => iap.buy(pack),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 10),
                    const Center(child: Txt('Customize', role: TextRole.heading)),
                    const SizedBox(height: 14),
                    Center(child: _Preview(loadout: loadout)),
                    const SizedBox(height: 16),
                    _OptionRow<SnakeSkin>(
                      title: 'Snake',
                      values: SnakeSkin.values,
                      selected: loadout.skin,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      onSelect: (v) => services.loadout.value = loadout.copyWith(skin: v),
                    ),
                    _OptionRow<Trail>(
                      title: 'Trail',
                      values: Trail.values,
                      selected: loadout.trail,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      onSelect: (v) => services.loadout.value = loadout.copyWith(trail: v),
                    ),
                    _OptionRow<BoardTheme>(
                      title: 'Theme',
                      values: [for (final t in BoardTheme.values) if (!t.retro) t],
                      selected: loadout.theme,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      swatch: _swatch,
                      onSelect: (v) => services.loadout.value = loadout.copyWith(theme: v),
                    ),
                    _OptionRow<BoardTheme>(
                      title: 'Retro LCD',
                      values: [for (final t in BoardTheme.values) if (t.retro) t],
                      selected: loadout.theme,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      swatch: _swatch,
                      onSelect: (v) => services.loadout.value = loadout.copyWith(theme: v),
                    ),
                    const SizedBox(height: 20),
                    AppButton(label: 'Restore purchases', compact: true, onPressed: iap.restore),
                    const SizedBox(height: 12),
                    AppButton(label: 'Back', compact: true, onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// (background, snake) colours for a theme's chip. Auto shows half of
/// each of its two themes.
(Color, Color, Color?) _swatch(BoardTheme t) {
  final look = Palette.looks[t.resolve(systemDark: false)]!;
  final dark = t == BoardTheme.auto ? Palette.looks[BoardTheme.dusk]!.board : null;
  return (look.board, look.snake, dark);
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.title,
    required this.body,
    required this.owned,
    required this.offer,
    required this.onBuy,
  });

  final String title;
  final String body;
  final bool owned;
  final PackOffer? offer;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final available = offer?.available ?? false;
    final price = offer?.price ?? '';
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Txt(title, role: Palette.retro ? TextRole.heading : TextRole.label),
                SizedBox(height: Palette.retro ? 8 : 4),
                Txt(body, role: TextRole.caption, size: Palette.retro ? 7 : null),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: owned
                ? const Center(child: Txt('Owned', role: TextRole.label))
                : AppButton(
                    label: available ? (price.isEmpty ? 'Buy' : price) : 'N/A',
                    compact: true,
                    filled: true,
                    onPressed: available ? onBuy : null,
                  ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.locked,
    required this.onSelect,
    this.swatch,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final bool Function(T) locked;
  final ValueChanged<T> onSelect;

  /// Optional colour preview for each option (themes).
  final (Color, Color, Color?) Function(T)? swatch;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Txt(title, role: TextRole.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in values)
                  _Chip(
                    label: label(v),
                    selected: v == selected,
                    locked: locked(v),
                    swatch: swatch?.call(v),
                    onTap: () => onSelect(v),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final (Color, Color, Color?)? swatch;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: locked ? '${say(label)}, locked' : say(label),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: locked ? null : onTap,
          child: Palette.retro ? _retro() : _modern(),
        ),
      );

  Widget _modern() {
    final fg = selected ? Palette.onAccent : (locked ? Palette.inkSoft : Palette.ink);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.fromLTRB(swatch == null ? 14 : 8, 8, 14, 8),
      decoration: BoxDecoration(
        color: selected ? Palette.accent : Palette.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? Palette.accent : Palette.line, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch != null) ...[
            CustomPaint(size: const Size.square(20), painter: _SwatchPainter(swatch!)),
            const SizedBox(width: 8),
          ],
          Txt(label, role: TextRole.caption, color: fg),
          if (locked) ...[
            const SizedBox(width: 4),
            Icon(Icons.lock_rounded, size: 14, color: fg),
          ],
        ],
      ),
    );
  }

  Widget _retro() {
    final fg = selected ? Palette.background : (locked ? Palette.inkSoft : Palette.ink);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Palette.ink : null,
        border: Border.all(color: locked ? Palette.inkSoft : Palette.ink, width: 2),
      ),
      child: Text(say(locked ? '$label ×' : label), style: textStyle(TextRole.caption, color: fg)),
    );
  }
}

/// A round chip swatch: the board colour with a dot of snake colour. A
/// third colour splits the circle (Auto: light and dark).
class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.colours);
  final (Color, Color, Color?) colours;

  @override
  void paint(Canvas canvas, Size size) {
    final (board, snake, split) = colours;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final p = Paint()..color = board;
    canvas.drawCircle(c, r, p);
    if (split != null) {
      p.color = split;
      canvas.drawArc(Offset.zero & size, -1.5708, 3.1416, true, p);
    }
    p.color = snake;
    canvas.drawCircle(c, r * 0.42, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x33000000);
    canvas.drawCircle(c, r - 0.5, p);
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.colours != colours;
}

/// A little board showing the current skin, trail and screen.
class _Preview extends StatelessWidget {
  const _Preview({required this.loadout});
  final Loadout loadout;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(9 * 26 + 6, 3 * 26 + 6),
        painter: _PreviewPainter(loadout),
      );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.loadout);
  final Loadout loadout;
  final _skin = SnakeSkinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 26.0;
    final p = Paint();
    if (Palette.retro) {
      p.color = Palette.ink;
      canvas.drawRect(Offset.zero & size, p);
      p.color = Palette.board;
      canvas.drawRect(const Offset(3, 3) & Size(size.width - 6, size.height - 6), p);
    } else {
      final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
      p.color = Palette.board;
      canvas.drawRRect(r, p);
      p
        ..style = PaintingStyle.stroke
        ..color = Palette.line
        ..strokeWidth = 1.5;
      canvas.drawRRect(r, p);
      p.style = PaintingStyle.fill;
    }
    Rect cellRect(int x, int y) => Rect.fromLTWH(3 + x * cell, 3 + y * cell, cell, cell);
    p.color = Palette.boardAlt;
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 9; x++) {
        if (Palette.retro) {
          canvas.drawRect(cellRect(x, y).deflate(2), p);
        } else {
          canvas.drawCircle(cellRect(x, y).center, 1.8, p);
        }
      }
    }
    // Trail behind the tail, then the snake heading right along the middle.
    for (var i = 0; i < 2; i++) {
      _skin.paintTrail(canvas, loadout.trail, cellRect(1 - i, 1), 0.1 + i * 0.2, 0.6);
    }
    _skin.paint(
      canvas,
      cells: [for (var x = 7; x >= 2; x--) cellRect(x, 1)],
      cell: cell,
      skin: loadout.skin,
      heading: Direction.right,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.loadout.skin != loadout.skin ||
      old.loadout.trail != loadout.trail ||
      old.loadout.theme != loadout.theme;
}

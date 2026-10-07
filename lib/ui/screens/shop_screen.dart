import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../game/snake_skin_painter.dart';
import '../../services/iap_service.dart';
import '../../services/services.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';

/// Remove Ads, cosmetic packs, and choosing what to wear.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _packInfo = {
    Pack.removeAds: ('REMOVE ADS', 'NO MORE BREAK ADS BETWEEN RUNS.\nREWIND ADS STAY OPTIONAL.'),
    Pack.skins: ('SKIN PACK', 'STRIPED, DOTTED AND HOLLOW SNAKES.'),
    Pack.trails: ('TRAIL PACK', 'GHOST AND PIXEL DUST TRAILS.'),
    Pack.themes: ('THEME PACK', 'AMBER, ICE, MONO AND NIGHT SCREENS.'),
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
                    Center(child: Text('SHOP', style: pixelStyle(22))),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('ALL ITEMS ARE COSMETIC.\nNO GAMEPLAY ADVANTAGE.',
                          textAlign: TextAlign.center,
                          style: pixelStyle(8, color: LcdPalette.inkMid, height: 1.8)),
                    ),
                    // Fixed-height slot so the page doesn't jump when a
                    // store message appears.
                    SizedBox(
                      height: 36,
                      child: Center(child: Text(iap.message.value ?? '', style: pixelStyle(9))),
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
                    Center(child: Text('CUSTOMIZE', style: pixelStyle(14))),
                    const SizedBox(height: 14),
                    Center(child: _Preview(loadout: loadout)),
                    const SizedBox(height: 16),
                    _OptionRow<SnakeSkin>(
                      title: 'SNAKE',
                      values: SnakeSkin.values,
                      selected: loadout.skin,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      onSelect: (v) => services.loadout.value = loadout.copyWith(skin: v),
                    ),
                    _OptionRow<Trail>(
                      title: 'TRAIL',
                      values: Trail.values,
                      selected: loadout.trail,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      onSelect: (v) => services.loadout.value = loadout.copyWith(trail: v),
                    ),
                    _OptionRow<BoardTheme>(
                      title: 'SCREEN',
                      values: BoardTheme.values,
                      selected: loadout.theme,
                      label: (v) => v.label,
                      locked: (v) => v.pack != null && !owned.contains(v.pack),
                      onSelect: (v) => services.loadout.value = loadout.copyWith(theme: v),
                    ),
                    const SizedBox(height: 20),
                    LcdButton(label: 'RESTORE PURCHASES', fontSize: 10, onPressed: iap.restore),
                    const SizedBox(height: 12),
                    LcdButton(label: 'BACK', fontSize: 12, onPressed: () => Navigator.of(context).pop()),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: LcdPalette.ink, width: 3)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: pixelStyle(12)),
                const SizedBox(height: 8),
                Text(body, style: pixelStyle(7, color: LcdPalette.inkMid, height: 1.7)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: owned
                ? Center(child: Text('OWNED', style: pixelStyle(10)))
                : LcdButton(
                    label: available ? (price.isEmpty ? 'BUY' : price) : 'N/A',
                    fontSize: 10,
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
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final bool Function(T) locked;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: pixelStyle(8, color: LcdPalette.inkMid)),
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
                    onTap: () => onSelect(v),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.locked, required this.onTap});

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? LcdPalette.screen : (locked ? LcdPalette.inkSoft : LcdPalette.ink);
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '$label, locked' : label,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? LcdPalette.ink : null,
            border: Border.all(color: locked ? LcdPalette.inkSoft : LcdPalette.ink, width: 2),
          ),
          child: Text(locked ? '$label ×' : label, style: pixelStyle(8, color: fg)),
        ),
      ),
    );
  }
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
    final p = Paint()..color = LcdPalette.ink;
    canvas.drawRect(Offset.zero & size, p);
    final board = const Offset(3, 3) & Size(size.width - 6, size.height - 6);
    p.color = LcdPalette.screen;
    canvas.drawRect(board, p);
    p.color = LcdPalette.ghost;
    Rect cellRect(int x, int y) => Rect.fromLTWH(3 + x * cell, 3 + y * cell, cell, cell);
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 9; x++) {
        canvas.drawRect(cellRect(x, y).deflate(2), p);
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
      ink: LcdPalette.ink,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.loadout.skin != loadout.skin ||
      old.loadout.trail != loadout.trail ||
      old.loadout.theme != loadout.theme;
}

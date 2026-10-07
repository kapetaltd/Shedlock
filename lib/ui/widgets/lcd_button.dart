import 'package:flutter/material.dart';

import '../theme/lcd_theme.dart';

/// Chunky pixel button: thick ink border, hard drop shadow, presses down.
class LcdButton extends StatefulWidget {
  const LcdButton({
    super.key,
    required this.label,
    this.sublabel,
    this.onPressed,
    this.filled = false,
    this.fontSize = 14,
  });

  final String label;
  final String? sublabel;
  final VoidCallback? onPressed;

  /// Inverted colours for the primary action.
  final bool filled;
  final double fontSize;

  @override
  State<LcdButton> createState() => _LcdButtonState();
}

class _LcdButtonState extends State<LcdButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final ink = enabled ? LcdPalette.ink : LcdPalette.inkSoft;
    final bg = widget.filled && enabled ? LcdPalette.ink : LcdPalette.screen;
    final fg = widget.filled && enabled ? LcdPalette.screen : ink;
    const shadow = 4.0;
    final offset = _down ? shadow : 0.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.only(right: shadow, bottom: shadow),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                left: shadow,
                top: shadow,
                right: -shadow,
                bottom: -shadow,
                child: ColoredBox(color: enabled ? LcdPalette.shadow : const Color(0x00000000)),
              ),
              Transform.translate(
                offset: Offset(offset, offset),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: ink, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label,
                          textAlign: TextAlign.center,
                          style: pixelStyle(widget.fontSize, color: fg)),
                      if (widget.sublabel != null) ...[
                        const SizedBox(height: 6),
                        Text(widget.sublabel!,
                            textAlign: TextAlign.center,
                            style: pixelStyle(8, color: fg.withValues(alpha: 0.75))),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

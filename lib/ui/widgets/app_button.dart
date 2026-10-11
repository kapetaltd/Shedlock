import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's button. Modern looks: a rounded card that eases down when
/// pressed. Retro: a chunky pixel block with a hard drop shadow.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.sublabel,
    this.onPressed,
    this.filled = false,
    this.compact = false,
  });

  final String label;
  final String? sublabel;
  final VoidCallback? onPressed;

  /// Accent-coloured, for the primary action on a screen.
  final bool filled;

  /// Smaller text and padding, for secondary actions.
  final bool compact;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: [widget.label, ?widget.sublabel].map(say).join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled
            ? (_) {
                _set(false);
                widget.onPressed!();
              }
            : null,
        child: Palette.retro ? _retro(enabled) : _modern(enabled),
      ),
    );
  }

  Widget _labels(Color fg) {
    final role = widget.compact ? TextRole.label : TextRole.button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Txt(widget.label, role: role, color: fg, align: TextAlign.center),
        if (widget.sublabel != null) ...[
          SizedBox(height: Palette.retro ? 6 : 2),
          Txt(
            widget.sublabel!,
            role: TextRole.caption,
            color: fg.withValues(alpha: 0.75),
            align: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _modern(bool enabled) {
    final filled = widget.filled;
    final bg = filled ? Palette.accent : Palette.surface;
    final fg = filled ? Palette.onAccent : Palette.ink;
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: widget.compact ? 50 : 60),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.compact ? 10 : 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(cornerRadius),
            border: filled ? null : Border.all(color: Palette.line, width: 1.5),
            boxShadow: enabled && !_down
                ? [
                    BoxShadow(
                      color: filled ? Palette.accent.withValues(alpha: 0.28) : Palette.shadow,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: _labels(fg),
        ),
      ),
    );
  }

  Widget _retro(bool enabled) {
    final ink = enabled ? Palette.ink : Palette.inkSoft;
    final bg = widget.filled && enabled ? Palette.ink : Palette.background;
    final fg = widget.filled && enabled ? Palette.background : ink;
    const shadow = 4.0;
    final offset = _down ? shadow : 0.0;
    return Padding(
      padding: const EdgeInsets.only(right: shadow, bottom: shadow),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: shadow,
            top: shadow,
            right: -shadow,
            bottom: -shadow,
            child: ColoredBox(color: enabled ? Palette.shadow : const Color(0x00000000)),
          ),
          Transform.translate(
            offset: Offset(offset, offset),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: widget.compact ? 12 : 14),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: ink, width: 3),
              ),
              child: _labels(fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// A raised surface for grouping content: rounded card in modern looks,
/// thick-bordered box with a hard shadow in retro.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: Palette.retro
            ? BoxDecoration(
                color: Palette.background,
                border: Border.all(color: Palette.ink, width: 3),
                boxShadow: [BoxShadow(color: Palette.shadow, offset: const Offset(4, 4))],
              )
            : BoxDecoration(
                color: Palette.surface,
                borderRadius: BorderRadius.circular(cornerRadius + 4),
                border: Border.all(color: Palette.line),
                boxShadow: softShadow,
              ),
        child: child,
      );
}

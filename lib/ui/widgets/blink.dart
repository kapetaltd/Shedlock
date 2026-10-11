import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../game/palette.dart';

/// Draws attention to a prompt: a hard on/off blink like an LCD (retro),
/// or a gentle fade in and out (modern).
class Blink extends StatefulWidget {
  const Blink({super.key, required this.child, this.period = const Duration(milliseconds: 500)});

  final Widget child;
  final Duration period;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> {
  late final Timer _timer;
  bool _on = true;

  // Modern: each fade takes most of the period, with a short rest between,
  // so frames stop between fades.
  Duration get _modernPeriod => widget.period * 2;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      Palette.retro ? widget.period : _modernPeriod,
      (_) => setState(() => _on = !_on),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Palette.retro) return Opacity(opacity: _on ? 1 : 0, child: widget.child);
    return AnimatedOpacity(
      opacity: _on ? 1 : 0.45,
      duration: _modernPeriod * 0.8,
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}

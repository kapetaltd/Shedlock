import 'dart:async';

import 'package:flutter/widgets.dart';

/// Hard on/off blink, like an LCD prompt. No easing.
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.period, (_) => setState(() => _on = !_on));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Opacity(opacity: _on ? 1 : 0, child: widget.child);
}

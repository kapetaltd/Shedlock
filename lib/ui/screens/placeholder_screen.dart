import 'package:flutter/material.dart';

import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';

/// Stand-in for Shop (Phase 5) and Settings (Phase 6).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(title, style: pixelStyle(20)),
                const Spacer(),
                Text('COMING SOON', style: pixelStyle(12, color: LcdPalette.inkMid)),
                const Spacer(),
                LcdButton(label: 'BACK', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      );
}

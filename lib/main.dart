import 'package:flutter/material.dart';

import 'config/app_config.dart';

// Placeholder until the Flame game lands in Phase 3.
void main() => runApp(const ShedlockApp());

class ShedlockApp extends StatelessWidget {
  const ShedlockApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: AppConfig.appName,
        home: Scaffold(
          body: Center(
            child: Text('${AppConfig.appName}\n${AppConfig.tagline}',
                textAlign: TextAlign.center),
          ),
        ),
      );
}

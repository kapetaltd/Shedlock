import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../services/settings.dart';
import '../theme/lcd_theme.dart';
import '../widgets/lcd_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _privacyRequired = false;
  String _version = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = Services.of(context);
    services.ads.privacyOptionsRequired().then((v) {
      if (mounted) setState(() => _privacyRequired = v);
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    }).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<GameSettings>(
          valueListenable: services.settings,
          builder: (context, s, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                children: [
                  Center(child: Text('SETTINGS', style: pixelStyle(20))),
                  const SizedBox(height: 24),
                  _Toggle(
                    label: 'SOUND',
                    value: s.sound,
                    onChanged: (v) => services.settings.value = s.copyWith(sound: v),
                  ),
                  _Toggle(
                    label: 'HAPTICS',
                    value: s.haptics,
                    onChanged: (v) => services.settings.value = s.copyWith(haptics: v),
                  ),
                  _Toggle(
                    label: 'SCREEN SHAKE',
                    value: s.screenShake,
                    onChanged: (v) => services.settings.value = s.copyWith(screenShake: v),
                  ),
                  const SizedBox(height: 18),
                  if (_privacyRequired) ...[
                    LcdButton(
                      label: 'PRIVACY OPTIONS',
                      fontSize: 10,
                      onPressed: services.ads.showPrivacyOptions,
                    ),
                    const SizedBox(height: 12),
                  ],
                  LcdButton(label: 'RESTORE PURCHASES', fontSize: 10, onPressed: services.iap.restore),
                  const SizedBox(height: 28),
                  Text('HOW TO PLAY', style: pixelStyle(12)),
                  const SizedBox(height: 12),
                  Text(
                    'SWIPE TO TURN. EAT TO GROW: LONGER SNAKE, BIGGER MULTIPLIER.\n\n'
                    'TAP TO SHED: EVERYTHING BEHIND YOUR FIRST 3 SEGMENTS BECOMES '
                    'WALLS FOR 10 SECONDS. YOUR MULTIPLIER RESETS.\n\n'
                    'RUNNERS MOVE. TRAP ONE SO IT HAS NO WAY OUT TO LOCK IT FOR A BIG BONUS.\n\n'
                    'CRASHED? REWIND 3 SECONDS AND TRY AGAIN.',
                    style: pixelStyle(8, color: LcdPalette.inkMid, height: 1.9),
                  ),
                  const SizedBox(height: 28),
                  Text('ABOUT', style: pixelStyle(12)),
                  const SizedBox(height: 12),
                  Text(
                    '${AppConfig.appName.toUpperCase()} ${_version.isEmpty ? '' : 'V$_version'}\n'
                    '${AppConfig.tagline.toUpperCase()}\n\n'
                    'FONT: PRESS START 2P (SIL OPEN FONT LICENSE)\n'
                    'SOUNDS AND ART: ORIGINAL',
                    style: pixelStyle(8, color: LcdPalette.inkMid, height: 1.9),
                  ),
                  const SizedBox(height: 24),
                  LcdButton(label: 'BACK', fontSize: 12, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(label, style: pixelStyle(12))),
                Container(
                  width: 74,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: value ? LcdPalette.ink : null,
                    border: Border.all(color: LcdPalette.ink, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      value ? 'ON' : 'OFF',
                      style: pixelStyle(10, color: value ? LcdPalette.screen : LcdPalette.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

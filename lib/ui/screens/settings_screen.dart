import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../services/settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';

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
                  const Center(child: Txt('Settings', role: TextRole.title)),
                  const SizedBox(height: 24),
                  _Toggle(
                    label: 'Sound',
                    value: s.sound,
                    onChanged: (v) => services.settings.value = s.copyWith(sound: v),
                  ),
                  _Toggle(
                    label: 'Haptics',
                    value: s.haptics,
                    onChanged: (v) => services.settings.value = s.copyWith(haptics: v),
                  ),
                  _Toggle(
                    label: 'Screen shake',
                    value: s.screenShake,
                    onChanged: (v) => services.settings.value = s.copyWith(screenShake: v),
                  ),
                  const SizedBox(height: 18),
                  if (_privacyRequired) ...[
                    AppButton(
                      label: 'Privacy options',
                      compact: true,
                      onPressed: services.ads.showPrivacyOptions,
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppButton(label: 'Restore purchases', compact: true, onPressed: services.iap.restore),
                  const SizedBox(height: 28),
                  const Txt('How to play', role: TextRole.heading),
                  const SizedBox(height: 12),
                  const Txt(
                    'Swipe to turn. Eat to grow: a longer snake means a bigger multiplier.\n\n'
                    'Tap to shed: everything behind your first 3 segments becomes '
                    'walls for 10 seconds. Your multiplier resets.\n\n'
                    'Runners move. Trap one so it has no way out to lock it for a big bonus.\n\n'
                    'Crashed? Rewind 3 seconds and try again.',
                  ),
                  const SizedBox(height: 28),
                  const Txt('About', role: TextRole.heading),
                  const SizedBox(height: 12),
                  Txt(
                    '${AppConfig.appName} ${_version.isEmpty ? '' : 'v$_version'}\n'
                    '${AppConfig.tagline}\n\n'
                    'Fonts: Nunito and Press Start 2P (SIL Open Font License)\n'
                    'Sounds and art: original',
                    role: TextRole.caption,
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Back', compact: true, onPressed: () => Navigator.of(context).pop()),
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
        label: say(label),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Palette.retro ? 10 : 8),
            child: Row(
              children: [
                Expanded(
                  child: Txt(label, role: Palette.retro ? TextRole.heading : TextRole.label),
                ),
                if (Palette.retro) _retroSwitch() else _modernSwitch(),
              ],
            ),
          ),
        ),
      );

  Widget _modernSwitch() => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? Palette.accent : Palette.line,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: value ? Palette.onAccent : Palette.surface,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Palette.shadow, blurRadius: 4, offset: const Offset(0, 1))],
            ),
          ),
        ),
      );

  Widget _retroSwitch() => Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: value ? Palette.ink : null,
          border: Border.all(color: Palette.ink, width: 3),
        ),
        child: Center(
          child: Txt(
            value ? 'On' : 'Off',
            role: TextRole.label,
            color: value ? Palette.background : Palette.ink,
          ),
        ),
      );
}

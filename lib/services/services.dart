import 'package:flutter/widgets.dart';

import 'ads_service.dart';
import 'share_service.dart';
import 'storage_service.dart';

DateTime _systemNow() => DateTime.now();

/// Gives every screen access to the app's services.
class Services extends InheritedWidget {
  const Services({
    super.key,
    required this.storage,
    required this.ads,
    required this.share,
    this.clock = _systemNow,
    required super.child,
  });

  final StorageService storage;
  final AdsService ads;
  final ShareService share;

  /// Current time. Injected so tests can pin the daily date.
  final DateTime Function() clock;

  static Services of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Services>();
    assert(s != null, 'No Services above this context');
    return s!;
  }

  @override
  bool updateShouldNotify(Services oldWidget) =>
      storage != oldWidget.storage ||
      ads != oldWidget.ads ||
      share != oldWidget.share ||
      clock != oldWidget.clock;
}

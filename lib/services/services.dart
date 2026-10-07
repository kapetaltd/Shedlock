import 'package:flutter/widgets.dart';

import 'ads_service.dart';
import 'storage_service.dart';

/// Gives every screen access to the app's services.
class Services extends InheritedWidget {
  const Services({
    super.key,
    required this.storage,
    required this.ads,
    required super.child,
  });

  final StorageService storage;
  final AdsService ads;

  static Services of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Services>();
    assert(s != null, 'No Services above this context');
    return s!;
  }

  @override
  bool updateShouldNotify(Services oldWidget) =>
      storage != oldWidget.storage || ads != oldWidget.ads;
}

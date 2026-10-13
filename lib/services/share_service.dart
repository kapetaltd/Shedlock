import 'package:share_plus/share_plus.dart';

/// Opens the native share sheet.
abstract class ShareService {
  Future<void> shareText(String text);
}

class NativeShareService implements ShareService {
  const NativeShareService();

  @override
  Future<void> shareText(String text) => SharePlus.instance.share(ShareParams(text: text));
}

/// Records what would have been shared. For tests.
class FakeShareService implements ShareService {
  final List<String> shared = [];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}

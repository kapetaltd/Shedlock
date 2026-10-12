import 'package:flutter_test/flutter_test.dart';
import 'package:shedlock/config/firebase_config.dart';

void main() {
  test('Android Firebase options belong to one project and app', () {
    const o = FirebaseConfig.android;
    expect(o.apiKey, startsWith('AIza'));
    expect(o.appId, matches(RegExp(r'^1:\d+:android:[0-9a-f]+$')));
    expect(o.appId.split(':')[1], o.messagingSenderId, reason: 'appId embeds the project number');
    expect(o.storageBucket, startsWith(o.projectId));
  });
}

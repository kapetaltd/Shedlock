import 'dart:io';

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

  test('Android resources (read by Firebase Analytics) match the Dart options', () {
    const o = FirebaseConfig.android;
    final xml = File('android/app/src/main/res/values/firebase.xml').readAsStringSync();
    String res(String name) =>
        RegExp('<string name="$name"[^>]*>([^<]*)</string>').firstMatch(xml)!.group(1)!;
    expect(res('google_app_id'), o.appId);
    expect(res('gcm_defaultSenderId'), o.messagingSenderId);
    expect(res('google_api_key'), o.apiKey);
    expect(res('project_id'), o.projectId);
    expect(res('google_storage_bucket'), o.storageBucket);
  });
}

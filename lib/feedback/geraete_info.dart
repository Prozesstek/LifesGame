import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'feedback_bericht.dart';

/// Liest App-Version, Gerät und System für das Feedback. **Scheitert
/// nie**: Fehlt eine Angabe, steht „unbekannt“ da — ein Bericht ohne
/// Gerätemodell ist besser als keiner.
Future<FeedbackUmgebung> leseUmgebung() async {
  var version = '?';
  var build = '?';
  try {
    final p = await PackageInfo.fromPlatform();
    version = p.version;
    build = p.buildNumber;
  } on Exception {
    // bleibt „?“
  }

  var geraet = 'unbekannt';
  var system = 'unbekannt';
  try {
    final info = DeviceInfoPlugin();
    if (kIsWeb) {
      final w = await info.webBrowserInfo;
      geraet = 'Browser: ${w.browserName.name}';
      system = w.platform ?? 'Web';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final a = await info.androidInfo;
      geraet = '${a.manufacturer} ${a.model}';
      system = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final i = await info.iosInfo;
      geraet = i.utsname.machine;
      system = '${i.systemName} ${i.systemVersion}';
    } else {
      system = defaultTargetPlatform.name;
    }
  } on Exception {
    // bleibt „unbekannt“
  }

  return FeedbackUmgebung(
    appVersion: version,
    build: build,
    geraet: geraet,
    system: system,
  );
}

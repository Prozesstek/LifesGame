import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ladebildschirm.dart';

/// Stellschrauben von [oeffneGeladen].
abstract final class SpaeterLaden {
  /// Erst wenn das Laden länger dauert, kommt der Ladebildschirm — auf
  /// dem Handy ist fast alles sofort da, und ein Bildschirm, der nur
  /// aufblitzt, wirkt wie ein Fehler.
  static const Duration ladebildschirmAb = Duration(milliseconds: 180);

  /// Steht der Ladebildschirm, bleibt er wenigstens so lange, damit der
  /// Balken sichtbar voll wird.
  static const Duration mindestens = Duration(milliseconds: 450);

  /// Läuft `vorbereiten` länger, geht es trotzdem weiter — der Dungeon
  /// spielt zur Not mit Würfeln statt Bildern.
  static const Duration hoechstens = Duration(seconds: 15);

  /// In Widget-Tests werden Bilder nie fertig entpackt; dort wird
  /// `vorbereiten` übersprungen (`test/flutter_test_config.dart`).
  static bool vorbereiten = true;
}

/// Öffnet einen Bildschirm, dessen Code erst beim ersten Öffnen geladen
/// wird (`import … deferred as …`).
///
/// **Wozu:** Im Browser lädt die App sonst beim Start auch die Grube samt
/// Flame und die Statistik samt fl_chart, obwohl am Anfang niemand dort
/// ist. Mit `deferred` liegen sie in eigenen Teilen und kommen erst beim
/// ersten Tipp. Auf dem Handy (AOT) ist [laden] sofort fertig.
///
/// [vorbereiten] läuft danach und wird abgewartet — beim Dungeon die
/// Bilder (`grubeVorladen`), sonst stünden Würfel da, bis sie kommen.
/// [fortschritt] sagt, wie weit es ist. Dauert beides länger als
/// [SpaeterLaden.ladebildschirmAb], steht so lange der [Ladebildschirm].
///
/// Scheitert das Nachladen — im Browser ohne Netz —, bleibt der Spieler
/// stehen, wo er war, und erfährt es kurz.
Future<T?> oeffneGeladen<T>(
  BuildContext context, {
  required Future<void> Function() laden,
  required Widget Function() bauen,
  Future<void> Function()? vorbereiten,
  ValueListenable<double> Function()? fortschritt,
}) async {
  final navigator = Navigator.of(context);
  final meldung = ScaffoldMessenger.maybeOf(context);
  final stand = ValueNotifier<double>(0.05);
  Route<void>? ladeRoute;
  DateTime? seit;
  final zeigen = Timer(SpaeterLaden.ladebildschirmAb, () {
    if (!navigator.mounted) return;
    seit = DateTime.now();
    final route = PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          Ladebildschirm(stand: stand, tipp: LadeTipps.zufaellig()),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    ladeRoute = route;
    unawaited(navigator.push(route));
  });

  try {
    await laden();
  } on DeferredLoadException catch (fehler) {
    debugPrint('Nachladen gescheitert: $fehler');
    zeigen.cancel();
    final route = ladeRoute;
    if (route != null && navigator.mounted) navigator.removeRoute(route);
    stand.dispose();
    meldung?.showSnackBar(
      const SnackBar(content: Text('Konnte nicht laden. Verbindung?')),
    );
    return null;
  }
  stand.value = 0.3;

  if (vorbereiten != null && SpaeterLaden.vorbereiten) {
    await _vorbereiten(vorbereiten, fortschritt?.call(), stand);
  }
  zeigen.cancel();
  stand.value = 1;
  if (!navigator.mounted) return null;

  final route = ladeRoute;
  if (route == null) {
    stand.dispose();
    return navigator.push<T>(MaterialPageRoute<T>(builder: (_) => bauen()));
  }
  // Der Balken soll voll zu sehen sein, bevor es weitergeht.
  final gezeigt = DateTime.now().difference(seit ?? DateTime.now());
  if (gezeigt < SpaeterLaden.mindestens) {
    await Future<void>.delayed(SpaeterLaden.mindestens - gezeigt);
  }
  if (!navigator.mounted) return null;
  final ergebnis = navigator.pushReplacement<T, void>(
    MaterialPageRoute<T>(builder: (_) => bauen()),
  );
  unawaited(ergebnis.whenComplete(stand.dispose));
  return ergebnis;
}

/// Wartet auf [vorbereiten] und überträgt [fortschritt] auf die
/// letzten 70 % des Balkens. Scheitert es oder dauert es zu lange, geht
/// es trotzdem weiter: Der Dungeon spielt dann mit Würfeln.
Future<void> _vorbereiten(
  Future<void> Function() vorbereiten,
  ValueListenable<double>? fortschritt,
  ValueNotifier<double> stand,
) async {
  void mitziehen() => stand.value = 0.3 + 0.7 * (fortschritt?.value ?? 0);
  fortschritt?.addListener(mitziehen);
  mitziehen();
  try {
    await vorbereiten().timeout(SpaeterLaden.hoechstens)
    // Ein fehlendes Bild ist ein `FlutterError`, kein `Exception` —
    // der Lauf soll trotzdem beginnen.
    .catchError((Object fehler) {
      debugPrint('Vorbereiten gescheitert: $fehler');
    });
  } finally {
    fortschritt?.removeListener(mitziehen);
  }
}

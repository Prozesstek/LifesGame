import 'dart:async';

import 'package:flutter/material.dart';

/// Öffnet einen Bildschirm, dessen Code erst beim ersten Öffnen geladen
/// wird (`import … deferred as …`).
///
/// **Wozu:** Im Browser lädt die App sonst beim Start auch die Grube samt
/// Flame und die Statistik samt fl_chart, obwohl am Anfang niemand dort
/// ist. Mit `deferred` liegen sie in eigenen Teilen und kommen erst beim
/// ersten Tipp. Auf dem Handy (AOT) ist [laden] sofort fertig.
///
/// Scheitert das Nachladen — im Browser ohne Netz —, bleibt der Spieler
/// stehen, wo er war, und erfährt es kurz.
Future<T?> oeffneGeladen<T>(
  BuildContext context, {
  required Future<void> Function() laden,
  required Widget Function() bauen,
}) async {
  final navigator = Navigator.of(context);
  final meldung = ScaffoldMessenger.maybeOf(context);
  try {
    await laden();
  } on DeferredLoadException catch (fehler) {
    debugPrint('Nachladen gescheitert: $fehler');
    meldung?.showSnackBar(
      const SnackBar(content: Text('Konnte nicht laden. Verbindung?')),
    );
    return null;
  }
  if (!navigator.mounted) return null;
  return navigator.push<T>(MaterialPageRoute<T>(builder: (_) => bauen()));
}

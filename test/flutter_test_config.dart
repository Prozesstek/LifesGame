import 'dart:async';

import 'package:lifes_game/combat/widgets/eingangs_glut.dart';
import 'package:lifes_game/haustier/widgets/haustier_bild.dart';
import 'package:lifes_game/lagerfeuer/widgets/feuer_bild.dart';

/// Läuft vor jeder Testdatei unter `test/`.
///
/// **Der Schlund im Eingang atmet in Tests nicht.** Eine Animation ohne
/// Ende lässt `pumpAndSettle` nie zur Ruhe kommen — jeder Test, der den
/// Eingang der Grube zeigt, liefe sonst in die Zeitgrenze. **Dasselbe
/// gilt für das Lagerfeuer** (ADR-0076) **und das Haustier**, das sonst
/// endlos atmet.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  EingangsGlut.atmet = false;
  FeuerBild.flackert = false;
  HaustierBild.lebt = false;
  await testMain();
}

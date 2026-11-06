import 'dart:async';

import 'package:lifes_game/combat/widgets/eingangs_glut.dart';
import 'package:lifes_game/haustier/widgets/haustier_bild.dart';
import 'package:lifes_game/lagerfeuer/widgets/feuer_bild.dart';
import 'package:lifes_game/ui/pulsieren.dart';

/// Läuft vor jeder Testdatei unter `test/`.
///
/// **Der Schlund im Eingang atmet in Tests nicht.** Eine Animation ohne
/// Ende lässt `pumpAndSettle` nie zur Ruhe kommen — jeder Test, der den
/// Eingang der Grube zeigt, liefe sonst in die Zeitgrenze. **Dasselbe
/// gilt für das Lagerfeuer** (ADR-0076), **das Haustier**, das sonst
/// endlos atmet, **und was im Tutorial pulsiert** (`Pulsieren`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  EingangsGlut.atmet = false;
  FeuerBild.flackert = false;
  HaustierBild.lebt = false;
  Pulsieren.pulsiert = false;
  await testMain();
}

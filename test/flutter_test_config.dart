import 'dart:async';

import 'package:lifes_game/combat/widgets/eingangs_glut.dart';
import 'package:lifes_game/haustier/widgets/haustier_bild.dart';
import 'package:lifes_game/home/widgets/berg_himmel.dart';
import 'package:lifes_game/lagerfeuer/widgets/feuer_bild.dart';
import 'package:lifes_game/ui/ladebildschirm.dart';
import 'package:lifes_game/ui/pulsieren.dart';
import 'package:lifes_game/ui/schild_leiste.dart';
import 'package:lifes_game/ui/spaeter_laden.dart';
import 'package:lifes_game/ui/tafel_wind.dart';

/// Läuft vor jeder Testdatei unter `test/`.
///
/// **Der Schlund im Eingang atmet in Tests nicht.** Eine Animation ohne
/// Ende lässt `pumpAndSettle` nie zur Ruhe kommen — jeder Test, der den
/// Eingang der Grube zeigt, liefe sonst in die Zeitgrenze. **Dasselbe
/// gilt für das Lagerfeuer** (ADR-0076), **das Haustier**, das sonst
/// endlos atmet, **was im Tutorial pulsiert** (`Pulsieren`) **und die Figur des
/// Ladebildschirms**.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  EingangsGlut.atmet = false;
  FeuerBild.flackert = false;
  HaustierBild.lebt = false;
  // Wolken und Schnee hinter der Startseite ziehen ohne Ende.
  BergHimmel.lebt = false;
  Pulsieren.pulsiert = false;
  // Das Schild der Kopfzeile schwingt beim Öffnen ein.
  SchildLeiste.schwingt = false;
  // Der Wind über der Anschlagtafel käme alle paar Sekunden wieder.
  TafelWind.weht = false;
  // Bilder werden in Widget-Tests nie fertig entpackt; der Ladebildschirm
  // wartete sonst bis zu seiner Grenze, und die Figur liefe endlos.
  SpaeterLaden.vorbereiten = false;
  Ladebildschirm.laeuft = false;
  await testMain();
}

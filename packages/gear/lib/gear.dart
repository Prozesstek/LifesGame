/// Ausrüstung, Preise und Inventar für Lifes Game.
///
/// Reines Dart: kein Flutter, keine Dependencies. Die Preiskurve lässt sich
/// gegen den Gold-Zufluss durchrechnen, ohne die App zu starten (ADR-0011).
///
/// Dieses Package kennt weder `package:habits` (woher die Charakterwerte
/// kommen) noch `package:combat` (wo sie wirken). Es liefert nur einen
/// [GearBonus]; die App legt ihn auf die Werte aus den Gewohnheiten.
library;

export 'src/catalog.dart';
export 'src/item.dart';
export 'src/loadout.dart';
export 'src/prices.dart';

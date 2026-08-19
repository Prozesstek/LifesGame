/// Name und verdiente Titel für Lifes Game.
///
/// Reines Dart: kein Flutter, keine Dependencies. Die Titelbedingungen
/// lassen sich gegen den Fortschritt durchrechnen, ohne die App zu starten
/// (ADR-0013).
///
/// Dieses Package kennt weder `package:habits` (woher Streaks und Häkchen
/// kommen) noch `package:theory` (woher die Lektionen kommen). Es bekommt
/// drei Zahlen als [TitleStats]; die App setzt sie zusammen.
library;

export 'src/identity.dart';
export 'src/title.dart';
export 'src/title_catalog.dart';

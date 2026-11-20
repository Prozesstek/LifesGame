import 'package:flutter/material.dart';

import 'palette.dart';

/// **Die Schrift der Titel** (19.11.2026, Frederik: „neue Schriftart“):
/// Cormorant Garamond, dieselbe wie die Überschriften im Lernbuch.
///
/// Die Pergamentleiste mit Holzbalken vom 19.11. ist seit dem 20.11. ein
/// Holzschild an Ketten (`SchildLeiste`); von ihr bleibt die Schrift.
abstract final class MenueLeiste {
  /// Die Schrift der Titel.
  static const String schrift = 'CormorantGaramond';

  /// Wie der Titel einer Leiste steht.
  static const TextStyle titel = TextStyle(
    fontFamily: schrift,
    fontSize: 27,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: Palette.text,
  );
}

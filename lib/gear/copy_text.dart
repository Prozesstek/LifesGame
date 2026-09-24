import 'package:gear/gear.dart';

/// Wie ein Exemplar sich beschreibt — **eine Stelle** für Laden,
/// Inventar und Charakter (ADR-0048).
abstract final class CopyText {
  /// „108 %": wie gut der Wurf ist, gemessen am Katalogwert.
  static String quality(GearCopy copy) => '${(copy.quality * 100).round()} %';

  /// „+11 Angriff · +3 Verteidigung · 108 %".
  static String line(GearCopy copy) {
    return <String>[...copy.bonus.labels, quality(copy)].join(' · ');
  }

  /// Ob der Wurf über dem Durchschnitt liegt — dann darf er auffallen.
  static bool isGoodRoll(GearCopy copy) => copy.quality >= 1.05;
}

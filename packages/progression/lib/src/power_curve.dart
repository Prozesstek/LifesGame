import 'dart:math' as math;

import 'level_curve.dart';

/// Wie stark ein Level im Kampf macht — **vervielfachend** (ADR-0042).
///
/// Bis dahin tat ein Level im Kampf nichts: Die Werte kamen aus den
/// Gewohnheiten und der Ausrüstung, beide addiert und gedeckelt
/// (ADR-0008), und über ein Spielerleben stieg der Angriff von 13 auf
/// etwa 30. Jeder Fortschritt fühlte sich wie „+1" an.
///
/// Jetzt multipliziert jedes Level Angriff, Leben und Verteidigung mit
/// [perLevel]. Die Häkchen bleiben dabei, was sie waren — ein Punkt
/// Stärke ist ein Punkt Stärke —, aber das Level, das sie über die
/// Erfahrung heben, vervielfacht ihn.
abstract final class PowerCurve {
  /// Der Faktor je Level. 1,04 ergibt auf Level 15 (etwa Tag 30) ×1,7,
  /// auf Level 22 ×2,3 und auf Level 50 ×6,8.
  static const double perLevel = 1.04;

  /// Der Faktor auf Level [level], 1 auf Level 1.
  static double factorFor(int level) {
    final l = level.clamp(LevelCurve.minLevel, LevelCurve.maxLevel);
    return math.pow(perLevel, l - LevelCurve.minLevel).toDouble();
  }
}

import 'dart:math' as math;

import 'balance.dart';

/// Wie hart eine Stufe der Grube ist (ADR-0039).
///
/// **Dreissig Stufen, eine Grube.** Die Karte wird bei jedem Lauf neu
/// zusammengesteckt (`LevelBuilder`), die Stufe entscheidet nur, wie stark
/// die Gegner sind und wie viele Räume vor dem Wächter liegen. So bleibt
/// die Zahl „17 / 30" erhalten, an der die Sperren im Laden (ADR-0034),
/// die Errungenschaften (ADR-0033) und die einmalige Belohnung
/// (ADR-0032) hängen — sie heisst nur nicht mehr Sprosse, sondern Stufe.
///
/// Die Zahlen selbst stehen in [ActionBalance]; hier steht, wie aus einer
/// Stufe ein Faktor wird.
class PitStage {
  const PitStage._(this.number);

  /// Die Stufe [number], gezählt ab 1. Alles ausserhalb wird auf den
  /// Rand gezogen, statt zu werfen — eine Stufe kommt aus dem
  /// Spielstand, und ein Spielstand darf nie einen Lauf verhindern.
  factory PitStage(int number) {
    return PitStage._(number.clamp(1, count));
  }

  /// Wie viele Stufen es gibt. Dieselbe Zahl wie die Sprossen der alten
  /// Reihe — mit Absicht, siehe oben.
  static const int count = 30;

  final int number;

  /// Wo die Stufe zwischen der ersten und der letzten liegt, 0 bis 1.
  double get progress => (number - 1) / (count - 1);

  /// Faktor auf die Lebenspunkte aller Gegner — mit [powerFactor].
  double get hpFactor =>
      _geometric(
        ActionBalance.stageHpFactorFirst,
        ActionBalance.stageHpFactorLast,
      ) *
      powerFactor;

  /// Faktor auf den Angriff aller Gegner — mit [powerFactor].
  double get attackFactor =>
      _geometric(
        ActionBalance.stageAttackFactorFirst,
        ActionBalance.stageAttackFactorLast,
      ) *
      powerFactor;

  /// Was die Gegner zusätzlich vervielfacht, weil der Held vervielfacht
  /// (ADR-0042): ×1 auf Stufe 1, [ActionBalance.stagePowerLast] auf 30.
  /// Wirkt auf Leben, Angriff **und** Verteidigung.
  double get powerFactor => _geometric(1, ActionBalance.stagePowerLast);

  /// Was zur Verteidigung aller Gegner **dazukommt**.
  ///
  /// Addiert, nicht vervielfacht: Das Fussvolk hat 1 Verteidigung, ein
  /// Faktor bewegte dort nichts, beim Wächter dagegen alles.
  int get defenseBonus =>
      (ActionBalance.stageDefenseBonusLast * progress).round();

  /// Wie viele Räume vor dem Wächter liegen.
  int get roomCount {
    final extra = (ActionBalance.stageExtraRooms * progress).round();
    return ActionBalance.stageBaseRooms + extra;
  }

  /// Wie viele Sekunden ein Lauf auf dieser Stufe hat.
  double get timeLimitSeconds =>
      ActionBalance.timeBaseSeconds +
      ActionBalance.timePerRoomSeconds * roomCount;

  /// Geometrisch statt linear: Jede Stufe ist um denselben **Anteil**
  /// härter als die vorige. Linear wären die ersten Schritte riesig und
  /// die letzten kaum zu spüren.
  double _geometric(double first, double last) {
    return first * math.pow(last / first, progress).toDouble();
  }

  @override
  bool operator ==(Object other) => other is PitStage && other.number == number;

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() => 'PitStage($number)';
}

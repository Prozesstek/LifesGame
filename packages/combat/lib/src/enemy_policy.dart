import 'combatant.dart';
import 'move.dart';
import 'status.dart';

/// Entscheidet, welchen Move der Gegner waehlt.
///
/// Als Interface ausgelegt, damit Tests eine feste Wahl vorgeben koennen und
/// Gegnertypen sich spaeter im Verhalten unterscheiden, ohne die Engine
/// anzufassen.
abstract interface class EnemyPolicy {
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,
  });
}

/// Zweckmaessige Standard-KI: heilt in Not, schlaegt hart wenn moeglich,
/// vergiftet wenn es sich lohnt, sonst Basisangriff.
///
/// Bewusst simpel. Interessante Gegner entstehen im Konzept ueber Stats,
/// Move-Sets und Timing-Muster, nicht ueber schlaue Suche.
class SimpleEnemyPolicy implements EnemyPolicy {
  const SimpleEnemyPolicy({this.healBelowHpRatio = 0.3});

  /// Unterhalb dieses HP-Anteils wird Heilung bevorzugt.
  final double healBelowHpRatio;

  @override
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,
  }) {
    final affordable =
        loadout.where((m) => m.isAffordableBy(self.energy)).toList();
    if (affordable.isEmpty) {
      return _generatingMove(loadout);
    }

    final inTrouble = self.hp / self.maxHp < healBelowHpRatio;
    if (inTrouble) {
      final heal = _firstWithEffect<HealSelf>(affordable);
      if (heal != null) return heal;
    }

    final heavy = _strongestDamaging(affordable);
    if (heavy != null && heavy.power >= 2.0) return heavy;

    if (!_hasStatus(opponent, 'poison')) {
      final poison = _firstWithEffect<ApplyPoison>(affordable);
      if (poison != null) return poison;
    }

    return _strongestDamaging(affordable) ?? _generatingMove(loadout);
  }

  /// Fallback, wenn nichts bezahlbar ist: der Move, der Energie aufbaut.
  Move _generatingMove(List<Move> loadout) {
    for (final move in loadout) {
      if (move.energyDelta > 0) return move;
    }
    return loadout.first;
  }

  Move? _firstWithEffect<T extends MoveEffect>(List<Move> moves) {
    for (final move in moves) {
      if (move.effects.whereType<T>().isNotEmpty) return move;
    }
    return null;
  }

  Move? _strongestDamaging(List<Move> moves) {
    Move? best;
    for (final move in moves) {
      if (!move.dealsDamage) continue;
      if (best == null || move.power > best.power) best = move;
    }
    return best;
  }

  bool _hasStatus(Combatant combatant, String id) {
    return combatant.statuses.any((StatusEffect s) => s.id == id);
  }
}

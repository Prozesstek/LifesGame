import 'combatant.dart';
import 'events.dart';
import 'move.dart';
import 'timed_hit.dart';

/// Vollstaendiger Kampfzustand zu einem Zeitpunkt. Unveraenderlich.
class CombatState {
  const CombatState({
    required this.player,
    required this.enemy,
    this.round = 1,
    this.outcome,
  });

  factory CombatState.start({
    required Combatant player,
    required Combatant enemy,
  }) {
    return CombatState(player: player, enemy: enemy);
  }

  final Combatant player;
  final Combatant enemy;
  final int round;

  /// `null`, solange der Kampf laeuft.
  final CombatOutcome? outcome;

  bool get isOver => outcome != null;

  Combatant combatantOf(Side side) => side == Side.player ? player : enemy;

  CombatState copyWith({
    Combatant? player,
    Combatant? enemy,
    int? round,
    CombatOutcome? outcome,
  }) {
    return CombatState(
      player: player ?? this.player,
      enemy: enemy ?? this.enemy,
      round: round ?? this.round,
      outcome: outcome ?? this.outcome,
    );
  }
}

/// Was der Spieler in dieser Runde tut.
class PlayerAction {
  const PlayerAction({required this.move, this.timedHit = TimedHit.none});

  final Move move;

  /// Ergebnis der Timing-Eingabe. Von der Darstellungsschicht gemessen.
  final TimedHit timedHit;
}

/// Ergebnis einer Runde: neuer Zustand plus was passiert ist.
///
/// Die Reihenfolge der Events ist die Reihenfolge der Darstellung.
class CombatStep {
  CombatStep({required this.state, required List<CombatEvent> events})
      : events = List<CombatEvent>.unmodifiable(events);

  final CombatState state;
  final List<CombatEvent> events;

  /// Bequemer Zugriff fuer Tests und Simulationen.
  Iterable<T> eventsOfType<T extends CombatEvent>() => events.whereType<T>();
}

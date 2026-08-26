import 'combatant.dart';
import 'environment.dart';
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
    this.environment,
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

  /// Die aktive Umgebung, oder `null`.
  ///
  /// **Es ist immer nur eine.** Eine neue ueberschreibt die alte sofort --
  /// so steht es in der Vorlage. Sie sitzt am Zustand und nicht an einem
  /// Kaempfer, weil sie das Feld betrifft und nicht eine Person.
  final Environment? environment;

  bool get isOver => outcome != null;

  Combatant combatantOf(Side side) => side == Side.player ? player : enemy;

  CombatState copyWith({
    Combatant? player,
    Combatant? enemy,
    int? round,
    CombatOutcome? outcome,
    Environment? environment,
    bool clearEnvironment = false,
  }) {
    return CombatState(
      player: player ?? this.player,
      enemy: enemy ?? this.enemy,
      round: round ?? this.round,
      outcome: outcome ?? this.outcome,
      environment: clearEnvironment ? null : (environment ?? this.environment),
    );
  }
}

/// Was der Spieler in dieser Runde tut.
class PlayerAction {
  const PlayerAction({
    required this.move,
    this.timedHit = TimedHit.none,
    this.extraHits = const <TimedHit>[],
  });

  final Move move;

  /// Ergebnis der Timing-Eingabe. Von der Darstellungsschicht gemessen.
  final TimedHit timedHit;

  /// Die Ergebnisse der weiteren Tipps bei einem Mehrfachtreffer.
  ///
  /// Klingenwirbel hat drei Tipps: [timedHit] ist der erste, hier stehen
  /// die uebrigen. Ein eigenes Feld statt einer Liste fuer alles, damit
  /// jeder bestehende Aufruf unveraendert weiterlaeuft.
  final List<TimedHit> extraHits;

  /// Alle Tipps dieser Runde, in der Reihenfolge der Eingabe.
  List<TimedHit> hitsFor(Move move) {
    final all = <TimedHit>[timedHit, ...extraHits];
    if (all.length >= move.hits) return all.take(move.hits).toList();
    return <TimedHit>[
      ...all,
      for (var i = all.length; i < move.hits; i++) TimedHit.none,
    ];
  }
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

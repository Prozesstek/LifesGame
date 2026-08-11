/// Kampflogik fuer Lifes Game.
///
/// Reines Dart. Dieses Package hat bewusst **keine** Abhaengigkeit zu
/// Flutter oder Flame — die Trennung ist damit nicht nur Disziplin, sondern
/// durch die `pubspec.yaml` erzwungen (ADR-0002).
///
/// Benutzung:
/// ```dart
/// final engine = CombatEngine(seed: 42);
/// var state = CombatState.start(player: hero, enemy: slime);
/// final step = engine.resolveRound(
///   state,
///   PlayerAction(move: Moves.basicAttack, timedHit: TimedHit.perfect),
/// );
/// state = step.state;          // neuer Zustand
/// for (final event in step.events) { /* Flame spielt ab */ }
/// ```
library;

export 'src/balance.dart';
export 'src/combatant.dart';
export 'src/enemy_policy.dart';
export 'src/engine.dart';
export 'src/events.dart';
export 'src/move.dart';
export 'src/state.dart';
export 'src/status.dart';
export 'src/timed_hit.dart';

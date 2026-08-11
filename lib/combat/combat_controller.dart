import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Was der Bildschirm über einen laufenden Kampf wissen muss.
class CombatSession {
  const CombatSession({required this.state, required this.log});

  final CombatState state;

  /// Lesbare Zeilen der letzten Runden, neueste zuletzt.
  final List<String> log;

  CombatSession copyWith({CombatState? state, List<String>? log}) {
    return CombatSession(state: state ?? this.state, log: log ?? this.log);
  }
}

/// Bindeglied zwischen der reinen Kampflogik und der Oberfläche.
///
/// Enthält bewusst **keine** Spielregeln — die liegen alle in
/// `package:combat`. Dieser Controller hält nur fest, welcher Kampf gerade
/// läuft, und reicht Züge weiter (ADR-0002).
class CombatController extends Notifier<CombatSession> {
  CombatEngine _engine = CombatEngine(
    seed: DateTime.now().millisecondsSinceEpoch,
  );

  @override
  CombatSession build() => CombatSession(state: _freshFight(), log: const []);

  static CombatState _freshFight() {
    return CombatState.start(
      // Angriff 16: laut Balance-Simulation der einzige Wert, bei dem der
      // Kampf offen ist. Kommt später aus den Habits des Spielers.
      player: Combatant.fresh(
        name: 'Du',
        maxHp: 120,
        attack: 16,
        defense: 10,
        maxEnergy: 10,
      ),
      enemy: Combatant.fresh(
        name: 'Gegner',
        maxHp: 120,
        attack: 18,
        defense: 10,
        maxEnergy: 10,
      ),
    );
  }

  /// Spielt eine Runde und gibt die entstandenen Events zurück, damit die
  /// Darstellungsschicht sie abspielen kann.
  List<CombatEvent> playRound(Move move, TimedHit timedHit) {
    if (state.state.isOver) return const <CombatEvent>[];

    final step = _engine.resolveRound(
      state.state,
      PlayerAction(move: move, timedHit: timedHit),
    );
    state = CombatSession(state: step.state, log: <String>[...state.log]);
    return step.events;
  }

  void appendLog(Iterable<String> lines) {
    if (lines.isEmpty) return;
    // Nur die letzten Zeilen behalten — der Log ist Kontext, kein Archiv.
    final combined = <String>[...state.log, ...lines];
    final trimmed = combined.length > 40
        ? combined.sublist(combined.length - 40)
        : combined;
    state = state.copyWith(log: trimmed);
  }

  void restart() {
    _engine = CombatEngine(seed: DateTime.now().millisecondsSinceEpoch);
    state = CombatSession(state: _freshFight(), log: const <String>[]);
  }
}

final combatControllerProvider =
    NotifierProvider<CombatController, CombatSession>(CombatController.new);

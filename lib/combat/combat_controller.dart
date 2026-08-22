import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/abilities_controller.dart';
import '../gear/gear_controller.dart';

/// Gegen wen der nächste Kampf geht.
///
/// Kein Teil des Speicherstands: Die Wahl gilt für die Sitzung und beginnt
/// jedes Mal beim leichtesten Gegner. Ein Spieler, der die App eine Woche
/// nicht offen hatte, soll nicht sofort vor dem Bergwaechter stehen.
class EnemyChoiceController extends Notifier<EnemyBlueprint> {
  @override
  EnemyBlueprint build() => Enemies.all.first;

  void select(EnemyBlueprint enemy) {
    state = enemy;
  }
}

final selectedEnemyProvider =
    NotifierProvider<EnemyChoiceController, EnemyBlueprint>(
      EnemyChoiceController.new,
    );

/// Was der Bildschirm über einen laufenden Kampf wissen muss.
class CombatSession {
  const CombatSession({
    required this.state,
    required this.log,
    this.moves = const <Move>[],
  });

  final CombatState state;

  /// Lesbare Zeilen der letzten Runden, neueste zuletzt.
  final List<String> log;

  /// Die Knöpfe dieses Kampfes — eingefroren beim Start.
  ///
  /// **Warum eingefroren und nicht laufend gelesen.** Wer mitten im Kampf
  /// die Waffe wechselt, würde sonst die Knöpfe unter dem eigenen Finger
  /// austauschen. Dieselbe Begründung wie bei den Werten in
  /// [CombatController._freshFight]: Neues gilt ab dem nächsten Kampf.
  final List<Move> moves;

  CombatSession copyWith({
    CombatState? state,
    List<String>? log,
    List<Move>? moves,
  }) {
    return CombatSession(
      state: state ?? this.state,
      log: log ?? this.log,
      moves: moves ?? this.moves,
    );
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
  CombatSession build() {
    return CombatSession(
      state: _freshFight(),
      log: const <String>[],
      moves: ref.read(activeMovesProvider),
    );
  }

  /// Die Werte des Spielers kommen aus seinen Gewohnheiten (ADR-0008) und
  /// seiner Ausrüstung (ADR-0011), der Gegner aus `package:combat`.
  ///
  /// Bewusst `read` statt `watch`: Ein Häkchen oder ein Ausrüstungswechsel
  /// während eines laufenden Kampfes soll den Kampf nicht neu aufsetzen.
  /// Neue Werte gelten ab dem nächsten Kampf.
  CombatState _freshFight() {
    final stats = ref.read(equippedStatsProvider);
    final enemy = ref.read(selectedEnemyProvider);

    return CombatState.start(
      player: Combatant.fresh(
        name: 'Du',
        maxHp: stats.maxHp,
        attack: stats.attack,
        defense: stats.defense,
        maxEnergy: stats.maxEnergy,
      ),
      enemy: enemy.spawn(),
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
    state = CombatSession(
      state: step.state,
      log: <String>[...state.log],
      moves: state.moves,
    );
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

import 'package:combat/combat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../character/abilities_controller.dart';
import '../gear/gear_controller.dart';
import '../theory/theory_controller.dart';

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

  /// Setzt den Kampf auf Anfang — mit frischem Gegner **und** frischem
  /// Moveset.
  ///
  /// **Das Moveset muss hier mit.** `CombatSession.moves` hat einen leeren
  /// Standardwert; wer ihn beim Neubauen vergisst, bekommt einen Kampf ohne
  /// einen einzigen Knopf. Genau das ist passiert, als `moves` zu
  /// [CombatSession] dazukam: [build] bekam es, `restart` nicht — und weil
  /// die Gegnerwahl `restart` aufruft, war jeder über den Startbildschirm
  /// begonnene Kampf unbedienbar.
  ///
  /// Neu eingelesen statt übernommen ist dabei Absicht: Ein neuer Kampf
  /// soll die Ausrüstung und die Fähigkeiten von *jetzt* verwenden. Nur
  /// innerhalb eines laufenden Kampfes friert das Moveset ein (ADR-0017).
  void restart() {
    _engine = CombatEngine(seed: DateTime.now().millisecondsSinceEpoch);
    state = CombatSession(
      state: _freshFight(),
      log: const <String>[],
      moves: ref.read(activeMovesProvider),
    );
  }
}

final combatControllerProvider =
    NotifierProvider<CombatController, CombatSession>(CombatController.new);

/// Wie viele Moves ein Kampf mindestens braucht.
///
/// **Gemessen, nicht gesetzt** (ADR-0018): Mit einem einzigen Move
/// richtet der Kurzbogen rund 10,6 Schaden je Runde an, der Wegelagerer
/// 15,3. Das Rennen ist nicht zu gewinnen, egal wie lange es dauert —
/// die Simulation zeigt 0 % gegen 100 % mit zweien.
const int minMovesForCombat = 2;

/// Ob der Kampf offensteht.
///
/// **Zwei Bedingungen, und die zweite ist seit ADR-0020 nötig.** Bis
/// dahin genügte das Handbuch: Es gab genau so viel Erfahrung, dass der
/// zweite Slot aufging, und in den Slot passte immer etwas, weil vier
/// Fähigkeiten von Anfang an offen waren.
///
/// Seit ADR-0019 hängt jede wählbare Fähigkeit an einem Theorieknoten.
/// Damit kann der Slot aufgehen und leer bleiben — und das Handbuch
/// allein wäre wieder die Zusage eines unmöglichen Kampfes.
final combatUnlockedProvider = Provider<bool>((ref) {
  return ref.watch(handbookDoneProvider) &&
      ref.watch(activeMovesProvider).length >= minMovesForCombat;
});

/// Warum der Kampf zu ist — oder null, wenn er offen ist.
///
/// Steht als Satz da und nicht als Fehlerzustand: Eine Kachel, die den
/// Weg nennt, ist besser als eine, die verschwindet (ADR-0018).
final combatBlockReasonProvider = Provider<String?>((ref) {
  final fehlend = ref.watch(handbookRemainingProvider);
  if (fehlend > 0) {
    return fehlend == 1
        ? 'Noch eine Lektion in Gewohnheiten, dann geht es los'
        : 'Erst das Handbuch: noch $fehlend Lektionen in Gewohnheiten';
  }

  if (ref.watch(activeMovesProvider).length >= minMovesForCombat) return null;

  // **Gelernt und angelegt sind zwei verschiedene Dinge.** Wer eine
  // Fähigkeit hat, sie aber auf keinem Platz liegen hat, braucht einen
  // anderen Hinweis als jemand, der noch keine besitzt — sonst schickt
  // die Kachel ihn zurück in die Theorie, wo er nichts mehr zu tun hat.
  final gelernt = ref.watch(unlockedAbilitiesProvider);
  if (gelernt.isEmpty) {
    return 'Erst eine Fähigkeit lernen — ein Knoten unter „Körper"';
  }

  return 'Leg eine Fähigkeit auf einen freien Platz (Charakter)';
});

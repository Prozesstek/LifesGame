// Balance-Simulation über Package-Grenzen: Was passiert im Kampf mit einem
// Charakter, der seit N Tagen Gewohnheiten abhakt?
//
// Warum hier und nicht in packages/combat: Die Frage berührt zwei Packages,
// die einander bewusst nicht kennen. `packages/combat/example/balance_sim.dart`
// variiert deshalb nur den Angriffswert — und genau das war der Fehler im
// alten Befund. Das Spiel bewegt nie einen Wert allein, es bewegt vier
// gleichzeitig. Diese Datei liegt in der App, weil nur sie beide Packages
// sieht, und rechnet mit der echten Stat-Kurve statt mit abgeschriebenen
// Zahlen.
//
// Reines Dart trotz Flutter-Projekt: kein Import zieht Flutter herein.
//
//     dart run tool/balance_sim.dart
//     dart run tool/balance_sim.dart 3000

import 'dart:math';

import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';

/// Spieler und Gegner nutzen dieselbe Policy — sie beschreibt nur
/// „wähle einen Move“ und ist nicht gegnerspezifisch.
const EnemyPolicy _policy = SimpleEnemyPolicy();

/// Wie viele Runden ein Kampf höchstens dauern darf, damit ein Patt die
/// Simulation nicht aufhängt. Ein Kampf, der diesen Deckel erreicht, gilt
/// als nicht gewonnen — genau daran wurde der Heal-Lock sichtbar.
const int _rundenDeckel = 200;

/// Die Punkte des Gewohnheits-Pfads, an denen gemessen wird.
const List<int> _tage = <int>[0, 7, 14, 21, 30, 60];

void main(List<String> args) {
  final fights = args.isEmpty ? 1500 : int.parse(args.first);
  print('$fights Kämpfe je Feld, gemischtes Timing\n');

  _siegquoten(fights);
  _rundenzahlen(fights);
  _timingSpanne(fights);
}

/// Siegquote je Gegner und Tag. Die Diagonale ist das Ziel: Zu jedem
/// Zeitpunkt soll genau ein Gegner knapp sein.
void _siegquoten(int fights) {
  print('--- Siegquote: Gegner gegen Tag auf dem Gewohnheits-Pfad ---');
  print('(fünf Gewohnheiten, jeden Tag abgehakt)\n');

  final kopf = _tage.map((t) => 'Tag $t'.padLeft(8)).join();
  print('  ${'Gegner'.padRight(14)}$kopf');

  for (final gegner in Enemies.all) {
    final felder = _tage.map((tag) {
      final ergebnis = _run(
        fights: fights,
        stats: _statsNach(tag),
        loadout: _loadoutNach(tag),
        gegner: gegner,
        timingSkill: 0.5,
      );
      return '${(ergebnis.winRate * 100).round()} %'.padLeft(8);
    }).join();
    print('  ${gegner.name.padRight(14)}$felder');
  }

  print('\n  Werte des Spielers an diesen Tagen:');
  for (final tag in _tage) {
    final stats = _statsNach(tag);
    print(
      '    Tag ${tag.toString().padLeft(2)}: '
      'ATK ${stats.attack}  HP ${stats.maxHp}  '
      'DEF ${stats.defense}  EN ${stats.maxEnergy}  '
      'Lv ${_levelNach(tag)}  '
      '${_loadoutNach(tag).length} Moves',
    );
  }
}

/// Kampflänge. Sehr hohe Werte bedeuten Kämpfe, die nicht enden.
void _rundenzahlen(int fights) {
  print('\n--- Runden im Schnitt ---');
  final kopf = _tage.map((t) => 'Tag $t'.padLeft(8)).join();
  print('  ${'Gegner'.padRight(14)}$kopf');

  for (final gegner in Enemies.all) {
    final felder = _tage.map((tag) {
      final ergebnis = _run(
        fights: fights,
        stats: _statsNach(tag),
        loadout: _loadoutNach(tag),
        gegner: gegner,
        timingSkill: 0.5,
      );
      return ergebnis.averageRounds.toStringAsFixed(1).padLeft(8);
    }).join();
    print('  ${gegner.name.padRight(14)}$felder');
  }
}

/// Was perfektes Timing gegenüber keinem Timing ausmacht.
///
/// Große Werte sind kein Fehler, solange sie nur dort stehen, wo der Kampf
/// ohnehin knapp ist: Dann entscheiden Gewohnheiten, *ob* ein Kampf knapp
/// wird, und Timing entscheidet den knappen Kampf. Stehen sie überall, ist
/// der Deckel zu hoch.
void _timingSpanne(int fights) {
  print('\n--- Spannweite perfektes gegen kein Timing, in Punkten ---');
  final kopf = _tage.map((t) => 'Tag $t'.padLeft(8)).join();
  print('  ${'Gegner'.padRight(14)}$kopf');

  for (final gegner in Enemies.all) {
    final felder = _tage.map((tag) {
      final stats = _statsNach(tag);
      final loadout = _loadoutNach(tag);
      final ohne = _run(
        fights: fights,
        stats: stats,
        gegner: gegner,
        timingSkill: 0.0,
        loadout: loadout,
      ).winRate;
      final perfekt = _run(
        fights: fights,
        stats: stats,
        gegner: gegner,
        timingSkill: 1.0,
        loadout: loadout,
      ).winRate;
      return ((perfekt - ohne) * 100).round().toString().padLeft(8);
    }).join();
    print('  ${gegner.name.padRight(14)}$felder');
  }
}

/// Die Charakterwerte nach [tage] Tagen, in denen alle fünf Gewohnheiten
/// abgehakt wurden.
///
/// Nutzt denselben Aufbau wie `packages/habits/example/curve_sim.dart`: die
/// ersten fünf Vorlagen des Katalogs. Damit sind beide Simulationen
/// vergleichbar.
HabitTracker _trackerNach(int tage) {
  final gewaehlt = HabitCatalog.all
      .take(HabitRewards.maxActiveHabits)
      .map((t) => t.id)
      .toList();

  var tracker = const HabitTracker.empty();
  for (final id in gewaehlt) {
    tracker = tracker.activate(id);
  }

  var tag = const Day(2026, 1, 1);
  for (var i = 0; i < tage; i++) {
    for (final id in gewaehlt) {
      tracker = tracker.check(id, tag).tracker;
    }
    tag = tag.next;
  }

  return tracker;
}

CharacterStats _statsNach(int tage) => _trackerNach(tage).stats;

/// Das Level, das ein Charakter nach [tage] Tagen erreicht hat.
///
/// **Bewusst nur aus Gewohnheiten.** In der App speist auch die Theorie
/// die Erfahrung (`totalXpProvider`). Das Level faellt hier also eher zu
/// niedrig aus als zu hoch -- die Simulation ist an dieser Stelle
/// pessimistisch, nicht schoenrechnend.
int _levelNach(int tage) {
  return LevelCurve.levelFor(_trackerNach(tage).totalXp).level;
}

/// Die Moves, die an Tag [tage] tatsaechlich zur Verfuegung stehen.
///
/// **Seit ADR-0016/0017 haengt das Moveset am Level.** Auf Level 1 ist nur
/// der Waffenslot offen, die drei freien kommen auf 3, 6 und 10. Vier
/// Moves anzunehmen -- wie diese Simulation es bis dahin tat -- schrieb
/// dem Spieler an Tag 0 drei Knoepfe zu, die er nicht hat.
///
/// Gefuellt wird in Katalogreihenfolge: Der Spieler nimmt, was da ist.
/// Eine klug gewaehlte Zusammenstellung waere eine Annahme ueber sein
/// Verhalten; diese hier ist die anspruchsloseste.
///
/// **Ohne Waffe:** Der Spieler kaempft mit dem Rueckfall aus
/// `AbilityCatalog`, also dem Kurzbogen. Eine gekaufte Waffe wuerde den
/// Rhythmus aendern -- das zu simulieren braucht erst die drei fehlenden
/// Waffen im Laden.
List<Move> _loadoutNach(int tage) {
  final offen = AbilitySlots.openAt(_levelNach(tage));
  final moves = <Move>[
    Moves.byId(AbilityCatalog.fallbackMoveId) ?? Moves.basicAttack,
  ];

  for (final ability in AbilityCatalog.unlockedBy(
    const AbilityProgress.empty(),
  )) {
    if (moves.length >= offen) break;
    final move = Moves.byId(ability.moveId);
    if (move != null) moves.add(move);
  }

  return moves;
}

class _Ergebnis {
  const _Ergebnis(this.wins, this.fights, this.totalRounds);

  final int wins;
  final int fights;
  final int totalRounds;

  double get winRate => wins / fights;
  double get averageRounds => totalRounds / fights;
}

_Ergebnis _run({
  required int fights,
  required CharacterStats stats,
  required EnemyBlueprint gegner,
  required double timingSkill,
  required List<Move> loadout,
}) {
  // Zwei getrennte Generatoren, und das ist keine Kosmetik: Mit einem
  // einzigen verschiebt die Timing-Spalte alle folgenden Kampf-Seeds, weil
  // längere Kämpfe mehr Würfe verbrauchen. Die Spalten vergleichen dann
  // verschiedene Kämpfe, und das Ergebnis kann sich umkehren — bei
  // gemischtem Timing 37 % Siegquote gegen 80 % ohne Timing, was
  // mechanisch unmöglich ist. So bekommt jede Spalte dieselben Kämpfe.
  final seeds = Random(20260817);
  final timing = Random(4711);
  var wins = 0;
  var rounds = 0;

  for (var i = 0; i < fights; i++) {
    final engine = CombatEngine(seed: seeds.nextInt(1 << 30));
    var state = CombatState.start(
      player: Combatant.fresh(
        name: 'Du',
        maxHp: stats.maxHp,
        attack: stats.attack,
        defense: stats.defense,
        maxEnergy: stats.maxEnergy,
      ),
      enemy: gegner.spawn(),
    );

    for (var round = 0; round < _rundenDeckel && !state.isOver; round++) {
      final move = _policy.chooseMove(
        self: state.player,
        opponent: state.enemy,
        loadout: loadout,
      );
      state = engine
          .resolveRound(
            state,
            PlayerAction(move: move, timedHit: _roll(timing, timingSkill)),
          )
          .state;
      rounds++;
    }

    if (state.outcome == CombatOutcome.victory) wins++;
  }

  return _Ergebnis(wins, fights, rounds);
}

/// Übersetzt eine Fertigkeit von 0..1 in ein Timing-Ergebnis.
TimedHit _roll(Random random, double skill) {
  final value = random.nextDouble();
  if (value < skill * 0.6) return TimedHit.perfect;
  if (value < skill * 0.6 + 0.3) return TimedHit.good;
  return TimedHit.none;
}

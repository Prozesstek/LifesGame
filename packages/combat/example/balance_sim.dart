// Balance-Simulation der Kampflogik: laesst tausende Kaempfe laufen und
// meldet Siegquote und Kampflaenge.
//
// Das ist der eigentliche Grund fuer ADR-0002. Weil die Kampflogik keine
// Engine braucht, kostet ein kompletter Kampf Mikrosekunden statt Frames.
// Damit laesst sich eine Balance-Frage beantworten, statt sie zu erfuehlen.
//
// **Grenze dieser Datei, und sie ist wichtig.** Hier wird ein Wert bewegt
// und die uebrigen festgehalten. Das Spiel tut das nie: Gewohnheiten heben
// Angriff, HP, Verteidigung und Energie gemeinsam. Der erste Balance-Befund
// des Projekts ("das umkaempfte Band ist zwei Angriffspunkte breit") kam
// genau aus dieser Verwechslung. Wer wissen will, ob das *Spiel* im Lot
// ist, nimmt `tool/balance_sim.dart` im Wurzelverzeichnis -- die Datei
// sieht `package:habits` und rechnet mit der echten Werte-Kurve.
//
// Hier bleibt, was diese Schicht allein beantworten kann: Verhaelt sich die
// Engine sauber, und enden Kaempfe ueberhaupt?
//
// Aufruf:
//   dart run example/balance_sim.dart
//   dart run example/balance_sim.dart 5000

import 'dart:math';

import 'package:combat/combat.dart';

/// Spieler und Gegner nutzen dieselbe Policy -- die Schnittstelle ist nicht
/// gegnerspezifisch, sie beschreibt nur "waehle einen Move".
const EnemyPolicy _policy = SimpleEnemyPolicy();

/// Ein Kampf, der so lange dauert, ist kein Kampf mehr. Siehe
/// `docs/context/gotchas.md` zum Heal-Lock.
const int _rundenDeckel = 200;

void main(List<String> args) {
  final fights = args.isEmpty ? 2000 : int.parse(args.first);

  print('Simuliere $fights Kaempfe je Zeile ...\n');

  for (final gegner in Enemies.all) {
    print(
      '--- ${gegner.name}: ${gegner.maxHp} HP, ${gegner.attack} ATK, '
      '${gegner.defense} DEF ---',
    );
    for (var attack = 13; attack <= 21; attack += 2) {
      _report(
        'Held mit $attack ATK',
        _run(fights: fights, playerAttack: attack, gegner: gegner),
      );
    }
    print('');
  }

  print('--- Wirkung des Timed-Hit-Deckels bei gleichem Angriff ---');
  _report(
    'Ohne Timing (immer none)',
    _run(
      fights: fights,
      playerAttack: 15,
      gegner: Enemies.wegelagerer,
      timingSkill: 0.0,
    ),
  );
  _report(
    'Perfektes Timing (immer perfect)',
    _run(
      fights: fights,
      playerAttack: 15,
      gegner: Enemies.wegelagerer,
      timingSkill: 1.0,
    ),
  );

  print(
    '\nHinweis: Eine hohe Spannweite ist nur dort ein Problem, wo der '
    'Kampf\nnicht ohnehin knapp ist. Die Gesamtsicht liefert '
    '`tool/balance_sim.dart`.',
  );
}

class _Result {
  const _Result(this.wins, this.fights, this.totalRounds, this.longest);

  final int wins;
  final int fights;
  final int totalRounds;

  /// Laengster Kampf des Laufs. Erreicht er den Deckel, endet ein Kampf
  /// nicht mehr -- das ist ein Fehler, keine Balance-Frage.
  final int longest;

  double get winRate => wins / fights;
  double get averageRounds => totalRounds / fights;
}

_Result _run({
  required int fights,
  required int playerAttack,
  required EnemyBlueprint gegner,
  double timingSkill = 0.5,
}) {
  // Getrennte Generatoren: Mit einem einzigen verschiebt jede Aenderung der
  // Kampflaenge alle folgenden Seeds, und zwei Laeufe sind nicht mehr
  // vergleichbar.
  final seeds = Random(20260811);
  final timing = Random(4711);
  var wins = 0;
  var rounds = 0;
  var longest = 0;

  for (var i = 0; i < fights; i++) {
    final engine = CombatEngine(
      seed: seeds.nextInt(1 << 30),
      enemyLoadout: gegner.loadout,
      enemyUtilityChance: gegner.utilityChance,
    );
    var state = CombatState.start(
      player: Combatant.fresh(
        name: 'Held',
        maxHp: 180,
        attack: playerAttack,
        defense: 11,
        maxEnergy: 10,
      ),
      enemy: gegner.spawn(),
    );

    var thisFight = 0;
    while (thisFight < _rundenDeckel && !state.isOver) {
      final move = _policy.chooseMove(
        self: state.player,
        opponent: state.enemy,
        loadout: Moves.defaultLoadout,
      );
      state = engine
          .resolveRound(
            state,
            PlayerAction(move: move, timedHit: _roll(timing, timingSkill)),
          )
          .state;
      thisFight++;
      rounds++;
    }

    if (thisFight > longest) longest = thisFight;
    if (state.outcome == CombatOutcome.victory) wins++;
  }

  return _Result(wins, fights, rounds, longest);
}

/// Uebersetzt eine Fertigkeit von 0..1 in ein Timing-Ergebnis.
TimedHit _roll(Random random, double skill) {
  final value = random.nextDouble();
  if (value < skill * 0.6) return TimedHit.perfect;
  if (value < skill * 0.6 + 0.3) return TimedHit.good;
  return TimedHit.none;
}

void _report(String label, _Result result) {
  final rate = (result.winRate * 100).toStringAsFixed(1).padLeft(5);
  final avg = result.averageRounds.toStringAsFixed(1).padLeft(5);
  final warnung = result.longest >= _rundenDeckel
      ? '   ACHTUNG: ein Kampf hat den Rundendeckel erreicht'
      : '';
  print('$rate %  Siegquote   $avg Runden   $label$warnung');
}

// Balance-Simulation: laesst tausende Kaempfe laufen und meldet, wie oft der
// Spieler gewinnt und wie lange es dauert.
//
// Das ist der eigentliche Grund fuer ADR-0002. Weil die Kampflogik keine
// Engine braucht, kostet ein kompletter Kampf Mikrosekunden statt Frames.
// Damit laesst sich eine Balance-Frage beantworten, statt sie zu erfuehlen.
//
// Aufruf:
//   dart run example/balance_sim.dart
//   dart run example/balance_sim.dart 5000

import 'dart:math';

import 'package:combat/combat.dart';

void main(List<String> args) {
  final fights = args.isEmpty ? 2000 : int.parse(args.first);

  print('Simuliere $fights Kaempfe je Zeile ...\n');

  print('--- Siegquote nach Angriffswert (Gegner: 18 ATK / 10 DEF) ---');
  for (var attack = 12; attack <= 24; attack += 2) {
    _report('Held mit $attack ATK', _run(fights: fights, playerAttack: attack));
  }

  print('\n--- Wirkung des Timed-Hit-Deckels bei gleichem Angriff ---');
  _report(
    'Ohne Timing (immer none)',
    _run(fights: fights, playerAttack: 18, timingSkill: 0.0),
  );
  _report(
    'Perfektes Timing (immer perfect)',
    _run(fights: fights, playerAttack: 18, timingSkill: 1.0),
  );
}

class _Result {
  const _Result(this.wins, this.fights, this.totalRounds);

  final int wins;
  final int fights;
  final int totalRounds;

  double get winRate => wins / fights;
  double get averageRounds => totalRounds / fights;
}

/// Spieler und Gegner nutzen dieselbe Policy — die Schnittstelle ist nicht
/// gegnerspezifisch, sie beschreibt nur "waehle einen Move".
const EnemyPolicy _policy = SimpleEnemyPolicy();

_Result _run({
  required int fights,
  required int playerAttack,
  double timingSkill = 0.5,
}) {
  final random = Random(20260811);
  var wins = 0;
  var rounds = 0;

  for (var i = 0; i < fights; i++) {
    final engine = CombatEngine(seed: random.nextInt(1 << 30));
    var state = CombatState.start(
      player: Combatant.fresh(
        name: 'Held',
        maxHp: 120,
        attack: playerAttack,
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

    // Harte Obergrenze, damit ein Patt die Simulation nicht aufhaengt.
    for (var round = 0; round < 100 && !state.isOver; round++) {
      final move = _policy.chooseMove(
        self: state.player,
        opponent: state.enemy,
        loadout: Moves.defaultLoadout,
      );
      state = engine
          .resolveRound(
            state,
            PlayerAction(
              move: move,
              timedHit: _roll(random, timingSkill),
            ),
          )
          .state;
      rounds++;
    }

    if (state.outcome == CombatOutcome.victory) wins++;
  }

  return _Result(wins, fights, rounds);
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
  print('$rate %  Siegquote   $avg Runden im Schnitt   $label');
}

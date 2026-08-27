import 'dart:math';

import 'package:combat/combat.dart';

/// Balance ohne Zufallsstreuung. Fuer Tests, die exakte Zahlen pruefen.
const Balance deterministicBalance = Balance(damageVariance: 0);

Combatant hero({
  int maxHp = 100,
  int? hp,
  int attack = 20,
  int defense = 10,
  int maxEnergy = 10,
  int energy = 0,
}) {
  return Combatant(
    name: 'Held',
    maxHp: maxHp,
    hp: hp ?? maxHp,
    attack: attack,
    defense: defense,
    maxEnergy: maxEnergy,
    energy: energy,
  );
}

Combatant dummy({
  int maxHp = 100,
  int? hp,
  int attack = 10,
  int defense = 0,
  int maxEnergy = 10,
  int energy = 0,
}) {
  return Combatant(
    name: 'Ziel',
    maxHp: maxHp,
    hp: hp ?? maxHp,
    attack: attack,
    defense: defense,
    maxEnergy: maxEnergy,
    energy: energy,
  );
}

/// Gegner, der garantiert nichts tut. Isoliert den Spielerzug im Test.
class PassiveEnemyPolicy implements EnemyPolicy {
  const PassiveEnemyPolicy();

  @override
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,
    Side side = Side.enemy,
    Environment? environment,
    Random? random,
    double utilityChance = 0,
  }) {
    return const Move(
      id: 'idle',
      name: 'Abwarten',
      power: 0,
      energyDelta: 0,
    );
  }
}

CombatEngine engineWith({
  Balance balance = deterministicBalance,
  int seed = 1,
  EnemyPolicy policy = const PassiveEnemyPolicy(),
}) {
  return CombatEngine(seed: seed, balance: balance, enemyPolicy: policy);
}

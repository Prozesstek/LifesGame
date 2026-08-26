import 'dart:math';

import 'package:combat/combat.dart';
import 'package:test/test.dart';

import 'test_fixtures.dart';

const SimpleEnemyPolicy policy = SimpleEnemyPolicy();

/// Was die Policy ueber viele Wuerfe hinweg waehlt.
Set<String> gewaehlt({
  required List<Move> loadout,
  required double utilityChance,
  Combatant? self,
  Environment? environment,
  Side side = Side.enemy,
  int wuerfe = 200,
}) {
  final random = Random(11);
  final ids = <String>{};
  for (var i = 0; i < wuerfe; i++) {
    ids.add(
      policy
          .chooseMove(
            self: self ?? dummy(maxHp: 200, energy: 10, maxEnergy: 10),
            opponent: hero(maxHp: 200),
            loadout: loadout,
            side: side,
            environment: environment,
            random: random,
            utilityChance: utilityChance,
          )
          .id,
    );
  }
  return ids;
}

void main() {
  group('Ohne Staffelung bleibt alles beim Alten', () {
    test('bei utilityChance 0 wird nie etwas anderes gewaehlt', () {
      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.frostnebel],
        utilityChance: 0,
      );

      expect(ids, <String>{'basic_attack'});
    });

    test('ohne Zufallsgeber ebenfalls nicht', () {
      final move = policy.chooseMove(
        self: dummy(energy: 10, maxEnergy: 10),
        opponent: hero(),
        loadout: <Move>[Moves.basicAttack, AbilityMoves.frostnebel],
        utilityChance: 1,
      );

      expect(move.id, 'basic_attack');
    });
  });

  group('Manchmal legt der Gegner eine Umgebung', () {
    test('bei voller Wahrscheinlichkeit immer', () {
      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.frostnebel],
        utilityChance: 1,
      );

      expect(ids, <String>{'frostnebel'});
    });

    test('dazwischen kommt beides vor', () {
      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.frostnebel],
        utilityChance: 0.3,
      );

      expect(ids, <String>{'basic_attack', 'frostnebel'});
    });
  });

  group('Die Sperren gegen offensichtlich verschwendete Runden', () {
    test('bei fast vollen HP wird nicht geheilt', () {
      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, Moves.mend],
        utilityChance: 1,
        self: dummy(maxHp: 200, energy: 10, maxEnergy: 10),
      );

      expect(ids, <String>{'basic_attack'});
    });

    test('angeschlagen schon', () {
      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, Moves.mend],
        utilityChance: 1,
        self: dummy(maxHp: 200, hp: 100, energy: 10, maxEnergy: 10),
      );

      expect(ids, <String>{'mend'});
    });

    test('die eigene Umgebung wird nicht nachgelegt', () {
      final eigenes = Environments.frost.copyWith(owner: Side.enemy);

      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.frostnebel],
        utilityChance: 1,
        environment: eigenes,
      );

      expect(ids, <String>{'basic_attack'});
    });

    test('die des Gegners aber schon -- sie dreht sich damit um', () {
      final fremdes = Environments.frost.copyWith(owner: Side.player);

      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.frostnebel],
        utilityChance: 1,
        environment: fremdes,
      );

      expect(ids, <String>{'frostnebel'});
    });

    test('ein stehender Schutz wird nicht gestapelt', () {
      final geschuetzt = dummy(energy: 10, maxEnergy: 10).withStatus(
        const DamageReduction(factor: 0.6, remainingTurns: 2),
      );

      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.steinhaut],
        utilityChance: 1,
        self: geschuetzt,
      );

      expect(ids, <String>{'basic_attack'});
    });

    test('ein voller Energiebalken macht Aurastrom sinnlos', () {
      final ids = gewaehlt(
        loadout: <Move>[Moves.basicAttack, AbilityMoves.aurastrom],
        utilityChance: 1,
        self: dummy(energy: 10, maxEnergy: 10),
      );

      expect(ids, <String>{'basic_attack'});
    });
  });

  group('Die Staffelung steht an den Gegnern', () {
    test('sie steigt mit der Haerte', () {
      expect(
        Enemies.wegelagerer.utilityChance,
        lessThan(Enemies.soeldner.utilityChance),
      );
      expect(
        Enemies.soeldner.utilityChance,
        lessThan(Enemies.bergwaechter.utilityChance),
      );
    });

    test('jeder Gegner hat mindestens einen Utility-Zug im Set', () {
      for (final gegner in Enemies.all) {
        expect(
          gegner.loadout.any((m) => !m.dealsDamage),
          isTrue,
          reason: '${gegner.name} haette nichts, wofuer die Quote gilt.',
        );
      }
    });
  });
}

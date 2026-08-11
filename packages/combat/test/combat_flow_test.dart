import 'package:combat/combat.dart';
import 'package:test/test.dart';

import 'test_fixtures.dart';

/// Gegner, der stur denselben Move benutzt. Macht Reaktionen des Spielers
/// im Test isoliert pruefbar.
class FixedMovePolicy implements EnemyPolicy {
  const FixedMovePolicy(this.move);

  final Move move;

  @override
  Move chooseMove({
    required Combatant self,
    required Combatant opponent,
    required List<Move> loadout,
  }) =>
      move;
}

void main() {
  group('Statuseffekte', () {
    test('Giftklinge vergiftet und senkt die Verteidigung', () {
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(player: hero(energy: 3), enemy: dummy(defense: 100)),
        const PlayerAction(move: Moves.poisonStrike),
      );

      final applied =
          step.eventsOfType<StatusApplied>().map((e) => e.statusId).toList();
      expect(applied, containsAll(<String>['poison', 'defense_down']));
    });

    test('Gift wirkt am Rundenende und laeuft nach drei Runden aus', () {
      final engine = engineWith();
      var state =
          CombatState.start(player: hero(energy: 10), enemy: dummy(maxHp: 500));

      final first = engine.resolveRound(
        state,
        const PlayerAction(move: Moves.poisonStrike),
      );
      state = first.state;
      expect(first.eventsOfType<StatusTicked>(), hasLength(1));

      // Zwei weitere Runden: Gift tickt, danach ist es weg.
      var expired = false;
      for (var i = 0; i < 3; i++) {
        final step = engine.resolveRound(
          state,
          const PlayerAction(move: Moves.basicAttack),
        );
        state = step.state;
        if (step
            .eventsOfType<StatusExpired>()
            .any((e) => e.statusId == 'poison')) {
          expired = true;
        }
      }

      expect(expired, isTrue);
      expect(state.enemy.statuses.any((s) => s.id == 'poison'), isFalse);
    });

    test('Verteidigungssenkung erhoeht den erlittenen Schaden', () {
      final target = dummy(defense: 100);
      final weakened = target.withStatus(
        const DefenseDown(factor: 0.5, remainingTurns: 5),
      );

      expect(weakened.effectiveDefense, lessThan(target.effectiveDefense));
    });

    test('Gift stapelt nicht, sondern erneuert sich', () {
      final engine = engineWith();
      var state =
          CombatState.start(player: hero(energy: 10), enemy: dummy(maxHp: 500));

      state = engine
          .resolveRound(state, const PlayerAction(move: Moves.poisonStrike))
          .state;
      state = engine
          .resolveRound(state, const PlayerAction(move: Moves.poisonStrike))
          .state;

      final poisons = state.enemy.statuses.where((s) => s.id == 'poison');
      expect(poisons, hasLength(1));
    });
  });

  group('Sammeln (Slot 4)', () {
    test('heilt und gibt einen Schild', () {
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(
          player: hero(hp: 40, energy: 4),
          enemy: dummy(),
        ),
        const PlayerAction(move: Moves.mend),
      );

      expect(step.eventsOfType<Healed>().first.amount, 25);
      expect(step.state.player.hp, 65);
      expect(step.state.player.activeShield, isNotNull);
    });

    test('heilt nicht ueber die maximalen HP hinaus', () {
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(player: hero(hp: 95, energy: 4), enemy: dummy()),
        const PlayerAction(move: Moves.mend),
      );

      expect(step.state.player.hp, 100);
      expect(step.eventsOfType<Healed>().first.amount, 5);
    });

    test('Schild faengt Schaden ab, bevor HP verloren gehen', () {
      final engine =
          engineWith(policy: const FixedMovePolicy(Moves.basicAttack));
      final shielded = hero(hp: 100, energy: 4).withStatus(
        const Shield(absorb: 1000, remainingTurns: 5),
      );

      final step = engine.resolveRound(
        CombatState.start(player: shielded, enemy: dummy(attack: 30)),
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.eventsOfType<DamageAbsorbed>(), isNotEmpty);
      expect(step.state.player.hp, 100);
    });

    test('Schild bricht, wenn er aufgebraucht ist', () {
      final engine =
          engineWith(policy: const FixedMovePolicy(Moves.basicAttack));
      final shielded = hero(hp: 100).withStatus(
        const Shield(absorb: 1, remainingTurns: 5),
      );

      final step = engine.resolveRound(
        CombatState.start(player: shielded, enemy: dummy(attack: 50)),
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.eventsOfType<ShieldBroke>(), hasLength(1));
      expect(step.state.player.hp, lessThan(100));
    });
  });

  group('Kampfende', () {
    test('Sieg, wenn der Gegner faellt', () {
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(player: hero(), enemy: dummy(maxHp: 1)),
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.state.outcome, CombatOutcome.victory);
      expect(step.eventsOfType<CombatEnded>(), hasLength(1));
      expect(step.eventsOfType<CombatantDefeated>().first.side, Side.enemy);
    });

    test('Der Gegner handelt nicht mehr, wenn er vorher faellt', () {
      final engine =
          engineWith(policy: const FixedMovePolicy(Moves.basicAttack));
      final step = engine.resolveRound(
        CombatState.start(player: hero(hp: 100), enemy: dummy(maxHp: 1)),
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.state.player.hp, 100);
    });

    test('Niederlage, wenn der Spieler faellt', () {
      final engine =
          engineWith(policy: const FixedMovePolicy(Moves.basicAttack));
      final step = engine.resolveRound(
        CombatState.start(
          player: hero(hp: 1),
          enemy: dummy(maxHp: 500, attack: 50),
        ),
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.state.outcome, CombatOutcome.defeat);
      expect(step.eventsOfType<CombatantDefeated>().first.side, Side.player);
    });

    test('Ein beendeter Kampf nimmt keine Zuege mehr an', () {
      final engine = engineWith();
      final over = engine.resolveRound(
        CombatState.start(player: hero(), enemy: dummy(maxHp: 1)),
        const PlayerAction(move: Moves.basicAttack),
      );

      final again = engine.resolveRound(
        over.state,
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(
        again.eventsOfType<MoveFailed>().first.reason,
        MoveFailure.combatAlreadyOver,
      );
      expect(again.state.enemy.hp, over.state.enemy.hp);
    });
  });

  group('Determinismus', () {
    test('Gleicher Seed erzeugt identische Kaempfe', () {
      List<int> runFight(int seed) {
        final engine = CombatEngine(
          seed: seed,
          enemyPolicy: const FixedMovePolicy(Moves.basicAttack),
        );
        var state = CombatState.start(
          player: hero(maxHp: 300, energy: 10),
          enemy: dummy(maxHp: 300, attack: 15),
        );
        final trace = <int>[];
        for (var i = 0; i < 10 && !state.isOver; i++) {
          state = engine
              .resolveRound(state, const PlayerAction(move: Moves.basicAttack))
              .state;
          trace.add(state.enemy.hp);
        }
        return trace;
      }

      expect(runFight(1234), equals(runFight(1234)));
    });

    test('Unterschiedliche Seeds erzeugen unterschiedliche Verlaeufe', () {
      List<int> runFight(int seed) {
        final engine = CombatEngine(
          seed: seed,
          enemyPolicy: const PassiveEnemyPolicy(),
        );
        var state = CombatState.start(
          player: hero(maxHp: 300),
          enemy: dummy(maxHp: 300),
        );
        final trace = <int>[];
        for (var i = 0; i < 10; i++) {
          state = engine
              .resolveRound(state, const PlayerAction(move: Moves.basicAttack))
              .state;
          trace.add(state.enemy.hp);
        }
        return trace;
      }

      expect(runFight(1), isNot(equals(runFight(999))));
    });
  });

  group('Unveraenderlichkeit', () {
    test('Eine Runde veraendert den uebergebenen Zustand nicht', () {
      final engine = engineWith();
      final before = CombatState.start(player: hero(), enemy: dummy());
      final enemyHpBefore = before.enemy.hp;

      engine.resolveRound(before, const PlayerAction(move: Moves.basicAttack));

      expect(before.enemy.hp, enemyHpBefore);
    });
  });
}

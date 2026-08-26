import 'dart:math';

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
    Side side = Side.enemy,
    Environment? environment,
    Random? random,
    double utilityChance = 0,
  }) =>
      move;
}

void main() {
  group('Statuseffekte', () {
    test('Zehrung vergiftet, mehr nicht', () {
      // Bis ADR-0017 machte dieser Move beides. Die Schwaechung gehoert
      // seither zum Wuchtstoss -- getrennt, weil zusammen zwei der elf
      // Theorieplaetze ihre Aufgabe verloren haetten.
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(player: hero(energy: 3), enemy: dummy(defense: 100)),
        const PlayerAction(move: Moves.poisonStrike),
      );

      final applied =
          step.eventsOfType<StatusApplied>().map((e) => e.statusId).toList();
      expect(applied, contains('poison'));
      expect(applied, isNot(contains('defense_down')));
    });

    test('Wuchtstoss senkt die Verteidigung und kostet nichts', () {
      // Die andere Haelfte der geteilten Giftklinge. Sie sitzt jetzt auf
      // einer Waffe und *erzeugt* Energie -- Waffenmoves muessen auf
      // Level 1 allein tragen (ADR-0016, ADR-0017).
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(player: hero(energy: 0), enemy: dummy(defense: 100)),
        const PlayerAction(move: Moves.maceBash),
      );

      final applied =
          step.eventsOfType<StatusApplied>().map((e) => e.statusId).toList();
      expect(applied, contains('defense_down'));
      expect(Moves.maceBash.energyCost, 0);
    });

    test('jeder Waffenmove erzeugt Energie, keiner kostet welche', () {
      // Die Regel, an der ADR-0017 haengt: Auf Level 1 ist nur der
      // Waffenslot offen. Ein Waffenmove, der Energie kostet, waere dort
      // unbezahlbar.
      const weaponMoves = <Move>[
        Moves.basicAttack,
        Moves.swordStrike,
        Moves.daggerDouble,
        Moves.maceBash,
        Moves.staffGather,
      ];

      for (final move in weaponMoves) {
        expect(move.energyDelta, greaterThan(0), reason: move.id);
        expect(move.energyCost, 0, reason: move.id);
      }
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

      // Heilung haengt am Angriffswert, nicht an den maximalen HP:
      // hero() hat 20 ATK, healFactorOfAttack ist 1.0.
      expect(step.eventsOfType<Healed>().first.amount, 20);
      expect(step.state.player.hp, 60);
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

    test('Schild bemisst sich am Angriffswert, nicht an den maximalen HP', () {
      // Der Unterschied ist keine Kosmetik: An maxHp gekoppelt wuchs
      // Heilung mit dem HP-Pool mit, waehrend der Schaden gleich blieb --
      // ab einer bestimmten Poolgroesse endete kein Kampf mehr. Siehe
      // `docs/context/gotchas.md`.
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(
          player: hero(maxHp: 1000, hp: 500, attack: 20, energy: 4),
          enemy: dummy(),
        ),
        const PlayerAction(move: Moves.mend),
      );

      // shieldFactorOfAttack ist 0.6 -- unabhaengig von den 1000 maxHp.
      expect(step.state.player.activeShield?.absorb, 12);
      expect(step.eventsOfType<Healed>().first.amount, 20);
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

    test('ein ganz geschluckter Schlag meldet sich als vollstaendig', () {
      // Die Darstellung schreibt „Geblockt" nur, wenn nichts durchkam.
      // Sie soll das nicht aus der Eventliste erraten muessen -- das
      // Event sagt es.
      final engine = engineWith(
        policy: const FixedMovePolicy(Moves.basicAttack),
      );
      final shielded = hero(hp: 100, energy: 4).withStatus(
        const Shield(absorb: 1000, remainingTurns: 5),
      );

      final step = engine.resolveRound(
        CombatState.start(player: shielded, enemy: dummy(attack: 30)),
        const PlayerAction(move: Moves.basicAttack),
      );

      final geschluckt = step.eventsOfType<DamageAbsorbed>().first;
      expect(geschluckt.complete, isTrue);
      expect(
        step.eventsOfType<DamageDealt>().where((e) => e.target == Side.player),
        isEmpty,
      );
    });

    test('ein teilweise geschluckter Schlag meldet sich als unvollstaendig',
        () {
      final engine = engineWith(
        policy: const FixedMovePolicy(Moves.basicAttack),
      );
      final shielded = hero(hp: 100).withStatus(
        const Shield(absorb: 1, remainingTurns: 5),
      );

      final step = engine.resolveRound(
        CombatState.start(player: shielded, enemy: dummy(attack: 50)),
        const PlayerAction(move: Moves.basicAttack),
      );

      final geschluckt = step.eventsOfType<DamageAbsorbed>().first;
      expect(geschluckt.complete, isFalse);
      expect(
        step.eventsOfType<DamageDealt>().where((e) => e.target == Side.player),
        isNotEmpty,
      );
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

import 'package:combat/combat.dart';
import 'package:test/test.dart';

import 'test_fixtures.dart';

void main() {
  group('Schadensberechnung', () {
    test('Basisangriff senkt die HP des Gegners', () {
      // Arrange
      final engine = engineWith();
      final state = CombatState.start(player: hero(), enemy: dummy());

      // Act
      final step = engine.resolveRound(
        state,
        const PlayerAction(move: Moves.basicAttack),
      );

      // Assert
      expect(step.state.enemy.hp, lessThan(dummy().hp));
      expect(step.eventsOfType<DamageDealt>(), hasLength(1));
    });

    test('Verteidigung mindert Schaden, macht ihn aber nie negativ', () {
      final engine = engineWith();
      final weak = hero(attack: 1);
      final tank = dummy(defense: 9999);

      final step = engine.resolveRound(
        CombatState.start(player: weak, enemy: tank),
        const PlayerAction(move: Moves.basicAttack),
      );

      final damage = step.eventsOfType<DamageDealt>().first;
      expect(damage.amount, greaterThanOrEqualTo(1));
    });

    test('Timed Hit erhoeht den Schaden, aber gedeckelt bei plus 50 Prozent',
        () {
      final baseline = engineWith()
          .resolveRound(
            CombatState.start(player: hero(), enemy: dummy()),
            const PlayerAction(move: Moves.basicAttack),
          )
          .eventsOfType<DamageDealt>()
          .first
          .amount;

      final perfect = engineWith()
          .resolveRound(
            CombatState.start(player: hero(), enemy: dummy()),
            const PlayerAction(
              move: Moves.basicAttack,
              timedHit: TimedHit.perfect,
            ),
          )
          .eventsOfType<DamageDealt>()
          .first
          .amount;

      expect(perfect, greaterThan(baseline));
      // Der Deckel ist die Kernaussage des Spiels: Habits schlagen Timing.
      expect(perfect, lessThanOrEqualTo((baseline * 1.5).ceil()));
    });

    test('Perfect trifft haerter als Good', () {
      int damageFor(TimedHit timing) {
        return engineWith()
            .resolveRound(
              CombatState.start(player: hero(), enemy: dummy()),
              PlayerAction(move: Moves.basicAttack, timedHit: timing),
            )
            .eventsOfType<DamageDealt>()
            .first
            .amount;
      }

      expect(
        damageFor(TimedHit.perfect),
        greaterThan(damageFor(TimedHit.good)),
      );
      expect(damageFor(TimedHit.good), greaterThan(damageFor(TimedHit.none)));
    });
  });

  group('Energie', () {
    test('Basisangriff erzeugt Energie', () {
      final engine = engineWith();
      final step = engine.resolveRound(
        CombatState.start(player: hero(energy: 0), enemy: dummy()),
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.state.player.energy, 3);
    });

    test('Wuchtschlag ohne Energie schlaegt fehl und richtet nichts an', () {
      final engine = engineWith();
      final enemyBefore = dummy();

      final step = engine.resolveRound(
        CombatState.start(player: hero(energy: 0), enemy: enemyBefore),
        const PlayerAction(move: Moves.heavyAttack),
      );

      expect(
        step.eventsOfType<MoveFailed>().first.reason,
        MoveFailure.notEnoughEnergy,
      );
      expect(step.eventsOfType<DamageDealt>(), isEmpty);
      expect(step.state.enemy.hp, enemyBefore.hp);
    });

    test('Wuchtschlag verbraucht Energie und schlaegt haerter', () {
      final engine = engineWith();
      final state = CombatState.start(player: hero(energy: 10), enemy: dummy());

      const heavyAction = PlayerAction(move: Moves.heavyAttack);
      const basicAction = PlayerAction(move: Moves.basicAttack);
      final heavy = engine.resolveRound(state, heavyAction);
      final basic = engineWith().resolveRound(state, basicAction);

      expect(heavy.state.player.energy, 4);
      expect(
        heavy.eventsOfType<DamageDealt>().first.amount,
        greaterThan(basic.eventsOfType<DamageDealt>().first.amount),
      );
    });

    test('Energie kann nicht ueber das Maximum steigen', () {
      final engine = engineWith();
      final start = CombatState.start(
        player: hero(maxEnergy: 4, energy: 3),
        enemy: dummy(),
      );
      final step = engine.resolveRound(
        start,
        const PlayerAction(move: Moves.basicAttack),
      );

      expect(step.state.player.energy, 4);
    });
  });
}

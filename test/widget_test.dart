import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/combat_controller.dart';
import 'package:lifes_game/main.dart';

void main() {
  group('CombatController', () {
    test('startet mit vollem Leben und leerem Log', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final session = container.read(combatControllerProvider);
      expect(session.state.player.hp, session.state.player.maxHp);
      expect(session.state.isOver, isFalse);
      expect(session.log, isEmpty);
    });

    test('eine Runde verändert den Zustand und liefert Events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      final events = controller.playRound(Moves.basicAttack, TimedHit.perfect);

      expect(events, isNotEmpty);
      expect(events.whereType<DamageDealt>(), isNotEmpty);
      expect(
        container.read(combatControllerProvider).state.enemy.hp,
        lessThan(120),
      );
    });

    test('restart setzt den Kampf vollständig zurück', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      controller
        ..playRound(Moves.basicAttack, TimedHit.none)
        ..appendLog(<String>['irgendwas'])
        ..restart();

      final session = container.read(combatControllerProvider);
      expect(session.state.enemy.hp, session.state.enemy.maxHp);
      expect(session.log, isEmpty);
      expect(session.state.round, 1);
    });

    test('nach Kampfende werden keine Züge mehr angenommen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(combatControllerProvider.notifier);

      // Lange genug prügeln, bis eine Seite fällt.
      for (var i = 0; i < 200; i++) {
        if (container.read(combatControllerProvider).state.isOver) break;
        controller.playRound(Moves.basicAttack, TimedHit.perfect);
      }

      expect(container.read(combatControllerProvider).state.isOver, isTrue);
      expect(controller.playRound(Moves.basicAttack, TimedHit.none), isEmpty);
    });
  });

  group('CombatScreen', () {
    testWidgets('zeigt die vier Move-Slots', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      for (final move in Moves.defaultLoadout) {
        expect(find.text(move.name), findsOneWidget);
      }
    });

    testWidgets('Moves ohne genug Energie sind deaktiviert', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      // Zu Beginn hat der Spieler 0 Energie: nur Schlag ist bezahlbar.
      final heavy = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(Moves.heavyAttack.name),
          matching: find.byType(FilledButton),
        ),
      );
      expect(heavy.onPressed, isNull);

      final basic = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(Moves.basicAttack.name),
          matching: find.byType(FilledButton),
        ),
      );
      expect(basic.onPressed, isNotNull);
    });
  });
}

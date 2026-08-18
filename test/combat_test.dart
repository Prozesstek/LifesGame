import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/combat_controller.dart';
import 'package:lifes_game/combat/combat_screen.dart';
import 'package:lifes_game/combat/enemy_picker_screen.dart';

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
        lessThan(Enemies.all.first.maxHp),
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
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CombatScreen())),
      );
      await tester.pump();
    }

    testWidgets('zeigt die vier Move-Slots', (tester) async {
      await pumpScreen(tester);

      for (final move in Moves.defaultLoadout) {
        expect(find.text(move.name), findsOneWidget);
      }
    });

    testWidgets('Moves ohne genug Energie sind deaktiviert', (tester) async {
      await pumpScreen(tester);

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

  group('Gegnerwahl', () {
    test('beginnt beim leichtesten Gegner', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedEnemyProvider).id, Enemies.all.first.id);
      expect(
        container.read(combatControllerProvider).state.enemy.name,
        Enemies.all.first.name,
      );
    });

    test('ein anderer Gegner gilt ab dem nächsten Kampf', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(selectedEnemyProvider.notifier)
          .select(Enemies.bergwaechter);
      container.read(combatControllerProvider.notifier).restart();

      final gegner = container.read(combatControllerProvider).state.enemy;
      expect(gegner.name, Enemies.bergwaechter.name);
      expect(gegner.maxHp, Enemies.bergwaechter.maxHp);
    });

    test('die Gegner werden nach oben hin härter', () {
      // Die Reihenfolge ist kein Zufall: Der Bildschirm zeigt sie so an,
      // und die Einschätzung darunter setzt sie voraus.
      for (var i = 1; i < Enemies.all.length; i++) {
        final leichter = Enemies.all[i - 1];
        final schwerer = Enemies.all[i];
        expect(schwerer.maxHp, greaterThan(leichter.maxHp));
        expect(
          schwerer.attack + schwerer.defense,
          greaterThanOrEqualTo(leichter.attack + leichter.defense),
        );
      }
    });
  });

  group('EnemyPickerScreen', () {
    testWidgets('zeigt alle Gegner mit einer Einschaetzung', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: EnemyPickerScreen())),
      );
      await tester.pumpAndSettle();

      for (final gegner in Enemies.all) {
        expect(find.text(gegner.name), findsOneWidget, reason: gegner.name);
      }
      // Ein frischer Charakter schafft den ersten knapp und die anderen
      // nicht -- genau das soll der Bildschirm vorher sagen.
      expect(find.text('wird knapp'), findsOneWidget);
      expect(find.text('vermutlich noch zu stark'), findsNWidgets(2));
    });
  });
}

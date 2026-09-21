import 'package:action_combat/action_combat.dart';
import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/combat/ladder_screen.dart';

/// Die Grube als Kampf des Spiels (ADR-0039).
void main() {
  group('Die Naht zur Reihe', () {
    test('die Grube hat genau so viele Stufen wie die Reihe Sprossen', () {
      // An dieser Zahl hängen die Sperren im Laden (ADR-0034), die
      // Errungenschaften (ADR-0033) und die einmalige Belohnung (ADR-0032).
      // Zählten beide verschieden, gäbe es Stufen ohne Belohnung oder
      // Belohnungen ohne Stufe.
      expect(PitStage.count, Enemies.rungs);
    });

    test('eine geräumte Stufe zahlt einmal, eine zweite Räumung nichts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ladder = container.read(ladderProvider.notifier);

      final erste = ladder.recordRun(1, won: true);
      final zweite = ladder.recordRun(1, won: true);

      expect(erste.xp, LadderRewards.xpFor(1));
      expect(erste.gold, LadderRewards.goldFor(1));
      expect(zweite.xp, 0);
      expect(zweite.gold, 0);
      expect(container.read(ladderProvider).highestDefeated, 1);
    });

    test('ein gescheiterter Lauf zahlt nichts, wird aber festgehalten', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ertrag = container
          .read(ladderProvider.notifier)
          .recordRun(1, won: false);

      expect(ertrag.xp, 0);
      expect(ertrag.gold, 0);
      final stand = container.read(ladderProvider);
      expect(stand.highestDefeated, 0);
      expect(stand.defeats[1], 1);
    });

    test('Stufen lassen sich nicht überspringen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ertrag = container
          .read(ladderProvider.notifier)
          .recordRun(5, won: true);

      expect(ertrag.xp, 0);
      expect(container.read(ladderProvider).highestDefeated, 0);
    });
  });

  group('Der Eingang', () {
    testWidgets('zeigt Fortschritt, Stufe und Belohnung', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LadderScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 / ${PitStage.count}'), findsOneWidget);
      expect(find.text('Stufe 1'), findsOneWidget);
      expect(
        find.textContaining('+${LadderRewards.xpFor(1)} Erfahrung'),
        findsOneWidget,
      );
    });

    testWidgets('kein Gegner der alten Reihe steht mehr da', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LadderScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text(Enemies.atRung(1).name), findsNothing);
    });

    testWidgets('„Hinab" führt in die Grube der nächsten Stufe', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LadderScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hinab'));
      // Kein pumpAndSettle: Flame zeichnet dauerhaft (`gotchas.md`).
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final grube = tester.widget<PitScreen>(find.byType(PitScreen));
      expect(grube.stage.number, 1);
      expect(find.text('Die Grube · Stufe 1'), findsOneWidget);
    });
  });

  group('Die Fähigkeiten der Grube', () {
    // ADR-0039, Punkt 3: Id, Icon und Freischaltung bleiben. Eine Id, die
    // nur hier stünde, wäre in der Grube wirksam und nirgends zu lernen.
    test('jede hat eine Freischaltung in package:abilities', () {
      for (final ability in PitAbilities.all) {
        expect(
          AbilityCatalog.byMoveId(ability.id),
          isNotNull,
          reason: ability.id,
        );
      }
    });

    test('jede trägt denselben Namen wie im Rundenkampf', () {
      for (final ability in PitAbilities.all) {
        expect(Moves.byId(ability.id)?.name, ability.name, reason: ability.id);
      }
    });

    testWidgets('was auf den Plätzen liegt, wird ein Knopf', (tester) async {
      final plaetze = <Move>[
        Moves.byId('funkenstoss')!,
        Moves.byId('steinhaut')!,
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [activeMovesProvider.overrideWithValue(plaetze)],
          child: MaterialApp(home: PitScreen(stage: PitStage(1))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel('Funkenstoß'), findsOneWidget);
      expect(find.bySemanticsLabel('Steinhaut'), findsOneWidget);
      expect(find.bySemanticsLabel('Blütentau'), findsNothing);
      expect(find.textContaining('Mana'), findsOneWidget);
    });

    testWidgets('ohne Fähigkeit kein Mana-Balken', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [activeMovesProvider.overrideWithValue(<Move>[])],
          child: MaterialApp(home: PitScreen(stage: PitStage(1))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Mana'), findsNothing);
    });
  });
}

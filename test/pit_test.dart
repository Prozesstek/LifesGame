import 'package:action_combat/action_combat.dart';
import 'package:abilities/abilities.dart';
// Der Rundenkampf hat eine eigene Wirkung gleichen Namens.
import 'package:combat/combat.dart' hide HealSelf;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/gear/set_effects.dart';
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

    // Umgekehrt: Jede Fähigkeit, die man lernen kann, tut in der Grube
    // etwas. Sonst läge sie auf einem Platz und bekäme keinen Knopf.
    test('jede lernbare Fähigkeit wirkt in der Grube', () {
      for (final ability in AbilityCatalog.choosable) {
        expect(
          PitAbilities.byId(ability.moveId),
          isNotNull,
          reason: ability.moveId,
        );
      }
    });

    test('jede Waffe im Laden wird ein Grundangriff', () {
      final zuege = <String>{
        ...AbilityCatalog.weaponMoves.values,
        AbilityCatalog.fallbackMoveId,
      };
      for (final zug in zuege) {
        expect(PitWeapons.byMoveId(zug), isNotNull, reason: zug);
      }
    });

    // Sets wirken auf eine Art von Fähigkeit (ADR-0030). Hätte eine
    // Fähigkeit in der Grube eine andere Art als im Rundenkampf, wirkte
    // dasselbe Set auf sie im einen Kampf und im anderen nicht.
    test('jede hat dieselbe Art wie im Rundenkampf', () {
      for (final ability in PitAbilities.all) {
        final zug = Moves.byId(ability.id);
        expect(zug, isNotNull, reason: ability.id);
        expect(ability.kind.name, zug?.kind.name, reason: ability.id);
      }
    });

    test('jedes legendäre Stück trägt eine Kraft, die es gibt', () {
      final legendaer = GearCatalog.all.where(
        (i) => i.rarity == GearRarity.legendary,
      );
      expect(legendaer, isNotEmpty);
      for (final item in legendaer) {
        expect(
          PitLegendaries.byId(item.legendaryPower),
          isNotNull,
          reason: item.name,
        );
      }
    });

    test('keine Kraft liegt auf zwei Stücken, keine auf keinem', () {
      final vergeben = GearCatalog.all
          .map((i) => i.legendaryPower)
          .whereType<String>()
          .toList();
      expect(vergeben.toSet(), hasLength(vergeben.length));
      expect(vergeben.toSet(), PitLegendaries.all.map((l) => l.id).toSet());
    });

    test('ein getragenes Set kommt als Veränderung in der Grube an', () {
      // Ruhiger Stand, vier Teile: Schutz 60 % stärker.
      final set = GearSets.ruhigerStand;
      final teile = GearCatalog.all.where((i) => i.setId == set.id);
      final aktiv = ActiveSet(
        set: set,
        pieces: teile.length,
        perk: set.fourPiece,
      );

      final mods = pitModifiersFor(<ActiveSet>[aktiv], teile);
      final tau = PitModifiers.apply(PitAbilities.bluetentau, mods);

      expect(
        (tau.effects.single as HealSelf).share,
        closeTo(0.25 * set.fourPiece.protectionFactor, 1e-9),
      );
    });

    test('Sturmruf verbilligt Umgebungen um Energie mal Mana-Kurs', () {
      final set = GearSets.sturmruf;
      final aktiv = ActiveSet(set: set, pieces: 2, perk: set.twoPiece);
      final mods = pitModifiersFor(<ActiveSet>[aktiv], const <GearItem>[]);

      expect(
        PitModifiers.apply(PitAbilities.giftmoor, mods).manaCost,
        PitAbilities.giftmoor.manaCost -
            set.twoPiece.energyDiscount * ActionBalance.manaPerEnergy,
      );
      expect(
        PitModifiers.apply(PitAbilities.funkenstoss, mods).manaCost,
        PitAbilities.funkenstoss.manaCost,
      );
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

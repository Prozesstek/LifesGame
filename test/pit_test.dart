import 'package:action_combat/action_combat.dart';
import 'package:abilities/abilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/character/abilities_controller.dart';
import 'package:lifes_game/gear/set_effects.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/combat/ladder_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Die Grube als Kampf des Spiels (ADR-0039).
void main() {
  group('Die Naht zur Reihe', () {
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
    testWidgets('zeigt die Ebene und ihre Belohnung', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LadderScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(LadderScreen.ebeneKey), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      // Seit dem 28.09. als Zeichen und Zahl, ohne Satz (Issue #88).
      expect(find.text('+${LadderRewards.xpFor(1)}'), findsOneWidget);
      // Seit dem 16.10. ohne „0 / 30“ und ohne Fahrstuhl.
      expect(find.text('0 / ${PitStage.count}'), findsNothing);
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('nach drei geschafften Ebenen geht es auf die vierte', (
      tester,
    ) async {
      usePhoneView(tester);
      const stand = LadderProgress(
        highestDefeated: 3,
        bestTimes: <int, double>{2: 42.3},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(const SaveData(ladder: stand)),
          ],
          child: const MaterialApp(home: LadderScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byKey(LadderScreen.hinabKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final grube = tester.widget<PitScreen>(find.byType(PitScreen));
      expect(grube.stage.number, 4);
    });

    testWidgets('„Hinab" führt in die Grube der nächsten Stufe', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LadderScreen())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(LadderScreen.hinabKey));
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

    test('jedes legendäre Stück trägt eine Kraft, die es gibt', () {
      final legendaer = GearCatalog.all.where(
        (i) => i.rarity == GearRarity.legendary,
      );
      expect(legendaer, isNotEmpty);
      for (final item in legendaer) {
        expect(PitGearPowers.byId(item.power), isNotNull, reason: item.name);
      }
    });

    test('jede Kraft an einem Stück oder Set gibt es in der Grube', () {
      // Seit ADR-0077 tragen auch andere Seltenheiten und Sets eine.
      for (final item in GearCatalog.all) {
        if (item.power == null) continue;
        expect(PitGearPowers.byId(item.power), isNotNull, reason: item.name);
      }
      for (final set in GearSets.all) {
        for (final id in <String>[
          ...set.twoPiece.powers,
          ...set.fourPiece.powers,
        ]) {
          expect(PitGearPowers.byId(id), isNotNull, reason: '${set.name}: $id');
        }
      }
    });

    test('keine Kraft liegt auf zwei Stücken, keine auf keinem', () {
      // Eine Kraft hängt an genau einem Stück oder an einer Stufe eines
      // Sets (ADR-0077), nie an zweien und nie an keinem.
      final vergeben = <String>[
        ...GearCatalog.all.map((i) => i.power).whereType<String>(),
        for (final set in GearSets.all) ...<String>[
          ...set.twoPiece.powers,
          ...set.fourPiece.powers,
        ],
      ];
      expect(vergeben.toSet(), hasLength(vergeben.length));
      expect(vergeben.toSet(), PitGearPowers.all.map((l) => l.id).toSet());
    });

    test('ein volles Vampirset blutet in der Grube', () {
      final teile = GearCatalog.piecesOf(GearSets.vampir.id);
      final welt = ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.gereift,
        modifiers: pitModifiersFor(<ActiveSet>[
          ActiveSet(
            set: GearSets.vampir,
            pieces: teile.length,
            perk: GearSets.vampir.fourPiece,
          ),
        ], teile),
      );
      expect(welt.isBloodPact, isTrue);
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

    testWidgets('was auf den Plätzen liegt, wird ein Knopf', (tester) async {
      // Der erste Platz ist immer der Waffenzug.
      const plaetze = <String>['basic_attack', 'funkenstoss', 'steinhaut'];

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
          overrides: [activeMovesProvider.overrideWithValue(<String>[])],
          child: MaterialApp(home: PitScreen(stage: PitStage(1))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Mana'), findsNothing);
    });
  });
}

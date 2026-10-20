import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:identity/identity.dart';
import 'package:lifes_game/achievements/achievements_card.dart';
import 'package:lifes_game/achievements/achievements_screen.dart';
import 'package:lifes_game/character/abilities_screen.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/gear/equipment_screen.dart';
import 'package:lifes_game/sammlung/sammlung.dart';
import 'package:lifes_game/sammlung/sammlung_knopf.dart';
import 'package:lifes_game/sammlung/sammlung_provider.dart';
import 'package:lifes_game/sammlung/sammlung_screen.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Sammlung (Issues #137, #138): was dort steht, woher es kommt, und
/// dass die Wege hinein führen.
void main() {
  group('was drinsteht', () {
    test('alle Stücke, gesammelt ist, was je besessen war', () {
      final erstes = GearCatalog.all.first;
      final eintraege = Sammlung.ausruestung(<String>{erstes.id});

      expect(eintraege, hasLength(GearCatalog.all.length));
      expect(eintraege.where((e) => e.gesammelt).map((e) => e.id), <String>[
        erstes.id,
      ]);
    });

    test('ein Stück sagt, ab welcher Ebene und zu welchem Set', () {
      final episch = GearCatalog.all.firstWhere(
        (i) => i.rarity == GearRarity.epic,
      );
      final setTeil = GearCatalog.all.firstWhere((i) => i.isSetPiece);

      expect(
        Sammlung.woherStueck(episch),
        contains('ab Ebene ${GearGates.epicRung}'),
      );
      expect(
        Sammlung.woherStueck(setTeil),
        contains(GearSets.byId(setTeil.setId)!.name),
      );
    });

    test('alle Fähigkeiten und Ultimates, mit ihrer Bedingung', () {
      final eintraege = Sammlung.faehigkeiten(<String>{'funkenstoss'});

      expect(
        eintraege,
        hasLength(
          AbilityCatalog.choosable.length + AbilityCatalog.ultimates.length,
        ),
      );
      final funke = eintraege.firstWhere((e) => e.id == 'funkenstoss');
      expect(funke.gesammelt, isTrue);
      expect(funke.woher, contains('Seite'));
    });

    test('zehn Arten und vier Wächter, in Stufen', () {
      final b = const Bestiarium.leer()
          .mit(gegner: <EnemyKind, int>{EnemyKind.fussvolk: 12})
          .mit(waechter: BossKind.zyklop);
      final eintraege = Sammlung.gegner(b);

      expect(eintraege, hasLength(Bestiarium.arten.length + 4));
      final fussvolk = eintraege.firstWhere((e) => e.id == 'fussvolk');
      expect(fussvolk.stufe, 2);
      expect(fussvolk.stufen, 3);
      expect(fussvolk.anzahl, 12);
      expect(Sammlung.naechsteSchwelle(fussvolk), 100);

      final zyklop = eintraege.firstWhere((e) => e.id == 'waechter-zyklop');
      expect(zyklop.gesammelt, isTrue);
      expect(Sammlung.naechsteSchwelle(zyklop), 5);
    });

    test('die Stufen zählen in die Prozente, nicht nur der erste Sieg', () {
      final einmal = SammelStand.aus(
        Sammlung.gegner(
          const Bestiarium.leer().mit(
            gegner: <EnemyKind, int>{EnemyKind.fussvolk: 1},
          ),
        ),
      );
      final hundertmal = SammelStand.aus(
        Sammlung.gegner(
          const Bestiarium.leer().mit(
            gegner: <EnemyKind, int>{EnemyKind.fussvolk: 100},
          ),
        ),
      );

      expect(hundertmal.erreicht, einmal.erreicht + 2);
    });

    test('100 % erst, wenn wirklich alles da ist', () {
      expect(const SammelStand(99, 100).prozent, 99);
      expect(const SammelStand(199, 200).prozent, 99);
      expect(const SammelStand(200, 200).prozent, 100);
      expect(const SammelStand(0, 0).prozent, 0);
    });

    test('die dreizehn Titel — eine Entdeckung verrät sich nicht', () {
      final eintraege = Sammlung.titel(const <String>{});

      expect(eintraege, hasLength(TitleCatalog.all.length));
      final moench = eintraege.firstWhere((e) => e.id == 'moench');
      expect(moench.woher, contains('verrät sich nicht'));
      final entschlossen = eintraege.firstWhere((e) => e.id == 'entschlossen');
      expect(entschlossen.woher, contains('3 Tage'));
    });

    test('alle Seiten, mit dem Weg im Baum', () {
      final eintraege = Sammlung.seiten(
        theoryGraph,
        const TheoryProgress.empty(),
      );

      expect(eintraege, hasLength(theoryGraph.nodeCount));
      final bewegung = eintraege.firstWhere((e) => e.id == 'koerper-bewegung');
      expect(bewegung.woher, contains('Körper › Kraft'));
      expect(eintraege.any((e) => e.gesammelt), isFalse);
    });
  });

  group('der Bildschirm', () {
    Future<ProviderContainer> zeige(
      WidgetTester tester, {
      SaveData stand = const SaveData.empty(),
      Widget home = const SammlungScreen(),
    }) async {
      useTallView(tester);
      final c = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(stand)],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: home),
        ),
      );
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('ein leerer Stand: sechs Reiter, alles Fragezeichen', (
      tester,
    ) async {
      await zeige(tester);

      for (final art in SammelArt.values) {
        expect(find.text(art.label), findsOneWidget);
      }
      expect(find.text('0 / ${GearCatalog.all.length}'), findsOneWidget);
      expect(find.text('???'), findsWidgets);
    });

    testWidgets('ein Tipp auf ein Fragezeichen sagt, woher', (tester) async {
      await zeige(tester);

      await tester.tap(find.byType(SammelKachel).first);
      await tester.pumpAndSettle();

      final erstes = GearCatalog.all.first;
      expect(find.text(Sammlung.woherStueck(erstes)), findsOneWidget);
      // Der Name bleibt verdeckt.
      expect(find.text(erstes.name), findsNothing);
    });

    testWidgets('die Gegner zeigen Sterne und wie oft', (tester) async {
      await zeige(
        tester,
        stand: SaveData(
          ladder: const LadderProgress.empty().recordKills(<EnemyKind, int>{
            EnemyKind.flink: 3,
          }),
        ),
      );

      await tester.tap(find.text(SammelArt.gegner.label));
      await tester.pumpAndSettle();
      expect(find.text('Kobold'), findsOneWidget);

      await tester.tap(find.text('Kobold'));
      await tester.pumpAndSettle();
      expect(find.text('3× besiegt — nächster Stern bei 10'), findsOneWidget);
    });

    testWidgets('die Errungenschaften stehen als eigener Reiter da', (
      tester,
    ) async {
      await zeige(tester);

      await tester.tap(find.text(SammelArt.errungenschaften.label));
      await tester.pumpAndSettle();

      expect(find.byType(ErrungenschaftenAnsicht), findsOneWidget);
    });
  });

  group('die Wege hinein', () {
    Future<void> zeige(WidgetTester tester, Widget home) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(const SaveData.empty()),
          ],
          child: MaterialApp(home: Scaffold(body: home)),
        ),
      );
      await tester.pumpAndSettle();
    }

    SammelArt offen(WidgetTester tester) {
      final screen = tester.widget<SammlungScreen>(find.byType(SammlungScreen));
      return screen.anfang;
    }

    testWidgets('aus der Ausrüstung beim Reiter Ausrüstung', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(const SaveData.empty()),
          ],
          child: const MaterialApp(home: EquipmentScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(SammlungKnopf.knopfKey));
      await tester.pumpAndSettle();

      expect(offen(tester), SammelArt.ausruestung);
    });

    testWidgets('aus den Fähigkeiten beim Reiter Fähigkeiten', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(const SaveData.empty()),
          ],
          child: const MaterialApp(home: AbilitiesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(SammlungKnopf.knopfKey));
      await tester.pumpAndSettle();

      expect(offen(tester), SammelArt.faehigkeiten);
    });

    testWidgets('die Karte im Charakter führt zu den Errungenschaften', (
      tester,
    ) async {
      await zeige(tester, const AchievementsCard());

      await tester.tap(find.byType(AchievementsCard));
      await tester.pumpAndSettle();

      expect(offen(tester), SammelArt.errungenschaften);
      expect(find.byType(ErrungenschaftenAnsicht), findsOneWidget);
    });
  });

  test('ein Lauf durch die Grube landet im Bestiarium', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final stage = PitStage(1);
    final welt = ActionWorld(
      level: LevelBuilder.build(stage: stage, seed: 7),
      heroStats: ActionStats.gereift,
      stage: stage,
      weaponMoveId: 'sword_strike',
      seed: 7,
    );
    PitBot.play(welt);

    c.read(ladderProvider.notifier).recordKills(welt);

    final gefallen = welt.killsJeArt.values.fold<int>(0, (a, b) => a + b);
    final gezaehlt = Bestiarium.arten.fold<int>(
      0,
      (summe, art) => summe + c.read(ladderProvider).bestiarium.besiegt(art),
    );
    expect(gezaehlt, gefallen);
    expect(c.read(sammelStandProvider(SammelArt.gegner)).erreicht, isPositive);
  });
}

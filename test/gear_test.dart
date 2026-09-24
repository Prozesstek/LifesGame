import 'package:abilities/abilities.dart';
import 'package:achievements/achievements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/weapon_ability_line.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';
import 'gear_helpers.dart';

void main() {
  const kappe = 'gear-lederkappe';
  const klinge = 'gear-uebungsklinge';

  /// Ein Stand mit genug Gold, um im Laden etwas ausrichten zu können.
  SaveData mitGold() {
    var progress = const TheoryProgress.empty();
    for (final branch in theoryTree.branches) {
      for (final lesson in branch.lessons) {
        progress = progress.submit(lesson, <int?>[
          for (final question in lesson.questions) question.correctIndex,
        ]).progress;
      }
    }
    return SaveData(theory: progress);
  }

  Widget appMit(SaveData saved, Widget screen) {
    return ProviderScope(
      overrides: [savedGameProvider.overrideWithValue(saved)],
      child: MaterialApp(home: screen),
    );
  }

  group('Gold', () {
    // **Seit ADR-0033 zieht der erste Kauf nicht nur ab.** „Erster Kauf"
    // ist ein Meilenstein und zahlt 10 Gold zurück — der Zufluss wächst
    // also mit. Das ist Absicht und keine Rundungsluecke: Vier
    // Errungenschaften haengen am Laden, zusammen 85 Gold ueber ein
    // Spielerleben, und jede zahlt genau einmal.
    test('ein Kauf zieht den Preis ab und zahlt den Meilenstein aus', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final vorher = container.read(goldProvider);
      final preis = GearCatalog.byId(kappe)?.price ?? 0;
      final ersterKauf = AchievementCatalog.byId('erster-kauf')!.tier.gold;

      container.read(loadoutProvider.notifier).buy(angebot(kappe));

      expect(container.read(goldProvider), vorher - preis + ersterKauf);
      // Der Zufluss waechst um genau den Meilenstein, der Abfluss um den
      // Preis.
      expect(container.read(goldEarnedProvider), vorher + ersterKauf);
      expect(container.read(loadoutProvider).spentGold, preis);
    });

    test('ein zweiter Kauf zieht nur noch ab', () {
      // Der Meilenstein zahlt genau einmal -- dieselbe Regel wie bei
      // einer Sprosse der Reihe (ADR-0032).
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      container.read(loadoutProvider.notifier).buy(angebot(kappe));
      final nachErstem = container.read(goldProvider);

      final zweites = GearCatalog.all.firstWhere(
        (i) => i.id != kappe && i.price <= nachErstem,
      );
      container.read(loadoutProvider.notifier).buy(angebot(zweites.id));

      expect(container.read(goldProvider), nachErstem - zweites.price);
    });

    test('ohne Gold geht kein Kauf, und der Grund ist benannt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(goldProvider), 0);
      expect(
        container.read(loadoutProvider.notifier).buy(angebot(kappe)),
        PurchaseBlock.zuWenigGold,
      );
      expect(container.read(loadoutProvider).ownedCopies, isEmpty);
    });

    test('Gold kann nie unter null fallen', () {
      // Der Grund, warum der Stand nur den Besitz speichert und keinen
      // Kontostand: Was nicht bezahlbar war, wurde nie gekauft.
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      for (final item in GearCatalog.all) {
        container.read(loadoutProvider.notifier).buy(angebot(item.id));
      }

      expect(container.read(goldProvider), greaterThanOrEqualTo(0));
    });
  });

  group('Verkaufen (ADR-0048)', () {
    test('ein Verkauf gibt ein Viertel zurück, nicht den ganzen Preis', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final zufluss = container.read(goldProvider);
      final preis = GearCatalog.byId(klinge)!.price;
      final erloes = Loadout.refundFor(GearCatalog.byId(klinge)!);

      // Der erste Kauf zahlt seinen Meilenstein aus (ADR-0033); er
      // steckt in beiden Zeilen darunter und aendert an der Aussage des
      // Tests nichts -- drei Viertel bleiben versenkt.
      final ersterKauf = AchievementCatalog.byId('erster-kauf')!.tier.gold;

      container.read(loadoutProvider.notifier).buy(angebot(klinge));
      expect(container.read(goldProvider), zufluss - preis + ersterKauf);

      expect(
        container.read(loadoutProvider.notifier).sell(angebot(klinge).uid),
        erloes,
      );

      // **Nicht zurück auf den Anfang.** Die Differenz ist versenkt.
      expect(
        container.read(goldProvider),
        zufluss - preis + erloes + ersterKauf,
      );
      // „Kein Blick zurueck" ist eine Entdeckung und zahlt kein Gold --
      // der Zufluss waechst durch einen Verkauf also nicht.
      expect(container.read(goldEarnedProvider), zufluss + ersterKauf);
    });

    test('verkaufte Ausrüstung wirkt nicht mehr', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final vorher = container.read(equippedStatsProvider).attack;
      container.read(loadoutProvider.notifier).buy(angebot(klinge));
      expect(container.read(equippedStatsProvider).attack, greaterThan(vorher));

      container.read(loadoutProvider.notifier).sell(angebot(klinge).uid);

      expect(container.read(equippedStatsProvider).attack, vorher);
      expect(container.read(loadoutProvider).ownsItem(klinge), isFalse);
    });

    test('ein verkauftes Set-Teil zählt nicht mehr zum Set', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final teile = GearCatalog.piecesOf(GearSets.ruhigerStand.id).take(2);
      for (final teil in teile) {
        container.read(loadoutProvider.notifier).buy(angebot(teil.id));
      }
      expect(container.read(activeSetsProvider), hasLength(1));

      container
          .read(loadoutProvider.notifier)
          .sell(angebot(teile.first.id).uid);

      expect(container.read(activeSetsProvider), isEmpty);
    });

    test('was man nicht besitzt, bringt nichts ein', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(loadoutProvider.notifier).sell(klinge), isNull);
      expect(container.read(goldProvider), 0);
    });
  });

  group('Ausrüstung wirkt im Kampf', () {
    test('ein getragenes Stück erhöht die Kampfwerte', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final vorher = container.read(equippedStatsProvider).attack;
      container.read(loadoutProvider.notifier).buy(angebot(klinge));
      final nachher = container.read(equippedStatsProvider);

      // Im Kampfmassstab (ADR-0048): ein Angebot mit genau 100 %.
      final bonus = GearCatalog.byId(klinge)!.bonus.scaled.attack;
      expect(nachher.attack, vorher + bonus);
      // Der Anteil aus dem Alltag bleibt sichtbar getrennt.
      expect(nachher.baseFor(HabitStat.staerke), vorher);
      expect(nachher.bonusFor(HabitStat.staerke), bonus);
    });

    test('abgelegt wirkt es nicht mehr', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      container.read(loadoutProvider.notifier).buy(angebot(klinge));
      final mitKlinge = container.read(equippedStatsProvider).attack;

      container.read(loadoutProvider.notifier).unequip(GearSlot.waffe);

      expect(container.read(equippedStatsProvider).attack, lessThan(mitKlinge));
      // Besitz bleibt, nur die Wirkung ist weg.
      expect(container.read(loadoutProvider).ownsItem(klinge), isTrue);
    });
  });

  group('Die Zeile zur Waffenfähigkeit', () {
    test('nur Waffen haben eine', () {
      for (final item in GearCatalog.all) {
        final zeile = weaponAbilityLine(item);

        if (item.slot == GearSlot.waffe) {
          expect(zeile, isNotNull, reason: item.name);
        } else {
          expect(zeile, isNull, reason: item.name);
        }
      }
    });

    test('sie nennt den Grundangriff in der Grube und seine Zahl', () {
      final zeile = weaponAbilityLine(GearCatalog.byId(klinge)!);

      // Die Übungsklinge schlägt in der Grube den Hieb mit ×1,25
      // (`PitWeapons`, ADR-0039). Steht die Zahl hier falsch, steht sie
      // im Laden falsch.
      expect(zeile, 'Grundangriff: Hieb — ×1,25 Schaden');
    });

    test('ein Bogen sagt, dass er schiesst', () {
      final bogen = GearCatalog.forSlot(
        GearSlot.waffe,
      ).firstWhere((w) => AbilityCatalog.weaponMoveFor(w.id) == 'basic_attack');
      expect(weaponAbilityLine(bogen), contains('schießt'));
    });

    test('nur legendäre Stücke nennen eine legendäre Kraft', () {
      for (final item in GearCatalog.all) {
        final zeile = legendaryPowerLine(item);
        if (item.rarity == GearRarity.legendary) {
          expect(zeile, startsWith('Legendär: '), reason: item.name);
        } else {
          expect(zeile, isNull, reason: item.name);
        }
      }
    });

    test('keine zwei Waffen bekommen dieselbe Zeile', () {
      // Der sichtbare Teil der Zusage aus `abilities_seam_test.dart`:
      // Zwei gleich beschriebene Waffen wären im Laden nicht zu
      // unterscheiden, auch wenn der Katalog es wäre.
      final zeilen = <String?>[
        for (final waffe in GearCatalog.forSlot(GearSlot.waffe))
          weaponAbilityLine(waffe),
      ];

      expect(zeilen.toSet(), hasLength(zeilen.length));
    });
  });

  group('Sets im Bild', () {
    /// Ein Stand, der die [anzahl] billigsten Teile eines Sets trägt.
    SaveData mitTeilenVon(GearSet set, int anzahl) {
      var loadout = const Loadout.empty();
      for (final item in GearCatalog.piecesOf(set.id).take(anzahl)) {
        loadout = loadout.buy(angebot(item.id), availableGold: 100000);
      }
      return SaveData(loadout: loadout);
    }

    testWidgets('ohne Set-Teile zeigt der Charakter keine Set-Karte', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const CharacterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sets'), findsNothing);
    });

    testWidgets('ein einzelnes Teil steht da, wirkt aber noch nicht', (
      tester,
    ) async {
      // **Ein Anfang soll sichtbar sein.** Wer ein Teil trägt, ohne es zu
      // wissen, hat kein Ziel — er hat Zufall.
      useTallView(tester);
      await tester.pumpWidget(
        appMit(mitTeilenVon(GearSets.sturmruf, 1), const CharacterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('1 / ${GearSet.fullSize}'), findsOneWidget);
      expect(
        find.textContaining('Noch ein Teil bis zur nächsten Stufe'),
        findsOneWidget,
      );
    });

    testWidgets('zwei Teile nennen die Wirkung mit echten Zahlen', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(mitTeilenVon(GearSets.sturmruf, 2), const CharacterScreen()),
      );
      await tester.pumpAndSettle();

      // Der Text baut sich aus dem Katalog — wer die Zahl dort ändert,
      // muss hier nichts nachziehen.
      final erwartet =
          '${GearSets.sturmruf.twoPiece.labels.join(' · ')} auf '
          '${GearSets.sturmruf.target.label}';

      expect(find.text('2 / ${GearSet.fullSize}'), findsOneWidget);
      expect(find.text(erwartet), findsOneWidget);
    });
  });

  group('CharacterScreen', () {
    testWidgets('zeigt alle vier Werte und alle sechs Plätze', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const CharacterScreen()),
      );
      await tester.pumpAndSettle();

      for (final stat in HabitStat.values) {
        expect(find.text(stat.label), findsOneWidget, reason: stat.label);
      }
      for (final slot in GearSlot.values) {
        expect(find.text(slot.label), findsOneWidget, reason: slot.label);
      }
      // Ohne einen einzigen Kauf sagt jede Kachel, *warum* sie leer ist.
      // „leer" heißt gekauft, aber nicht angelegt -- das ist ein anderer
      // Zustand und steht seit dem Umbau aufs Raster auch anders da.
      expect(
        find.text('nichts gekauft'),
        findsNWidgets(GearSlot.values.length),
      );
      expect(find.text('leer'), findsNothing);
    });

    testWidgets('trennt Alltag von Ausrüstung', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitGold(), const CharacterScreen()));
      await tester.pumpAndSettle();

      // Ohne Ausrüstung kommt jeder Wert aus dem Alltag.
      expect(find.text('Alltag'), findsNWidgets(HabitStat.values.length));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CharacterScreen)),
      );
      container.read(loadoutProvider.notifier).buy(angebot(klinge));
      await tester.pumpAndSettle();

      // Die Zahl kommt aus dem Katalog, nicht aus diesem Test — sonst
      // fällt er bei jeder Preisrunde um, ohne dass etwas kaputt ist.
      final bonus = GearCatalog.byId(klinge)!.bonus.scaled.attack;
      expect(find.textContaining('+$bonus Ausrüstung'), findsOneWidget);
    });
  });
}

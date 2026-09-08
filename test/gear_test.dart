import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/gear/weapon_ability_line.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

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
    test('ein Kauf zieht genau den Preis ab', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final vorher = container.read(goldProvider);
      final preis = GearCatalog.byId(kappe)?.price ?? 0;

      container.read(loadoutProvider.notifier).buy(kappe);

      expect(container.read(goldProvider), vorher - preis);
      // Der Zufluss bleibt unberührt — nur der Abfluss ist gewachsen.
      expect(container.read(goldEarnedProvider), vorher);
    });

    test('ohne Gold geht kein Kauf, und der Grund ist benannt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(goldProvider), 0);
      expect(
        container.read(loadoutProvider.notifier).buy(kappe),
        PurchaseBlock.zuWenigGold,
      );
      expect(container.read(loadoutProvider).owned, isEmpty);
    });

    test('Gold kann nie unter null fallen', () {
      // Der Grund, warum der Stand nur den Besitz speichert und keinen
      // Kontostand: Was nicht bezahlbar war, wurde nie gekauft.
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      for (final item in GearCatalog.all) {
        container.read(loadoutProvider.notifier).buy(item.id);
      }

      expect(container.read(goldProvider), greaterThanOrEqualTo(0));
    });
  });

  group('Ausrüstung wirkt im Kampf', () {
    test('ein getragenes Stück erhöht die Kampfwerte', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      final vorher = container.read(equippedStatsProvider).attack;
      container.read(loadoutProvider.notifier).buy(klinge);
      final nachher = container.read(equippedStatsProvider);

      final bonus = GearCatalog.byId(klinge)?.bonus.attack ?? 0;
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

      container.read(loadoutProvider.notifier).buy(klinge);
      final mitKlinge = container.read(equippedStatsProvider).attack;

      container.read(loadoutProvider.notifier).unequip(GearSlot.waffe);

      expect(container.read(equippedStatsProvider).attack, lessThan(mitKlinge));
      // Besitz bleibt, nur die Wirkung ist weg.
      expect(container.read(loadoutProvider).isOwned(klinge), isTrue);
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

    test('sie nennt Zug, Schadensfaktor und Energie', () {
      final zeile = weaponAbilityLine(GearCatalog.byId(klinge)!);

      // Die Übungsklinge trägt den Hieb: ×1,3 Schaden, +2 Energie
      // (ADR-0017, Punkt 2). Steht die Zahl hier falsch, steht sie im
      // Laden falsch.
      expect(zeile, 'Bringt Hieb mit — ×1,3 Schaden, +2 Energie je Runde');
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

  group('ShopScreen', () {
    testWidgets('zeigt jeden Platz und jedes Stück', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      // **Durchscrollen, sonst prüft der Test nur die obere Hälfte.** Der
      // Laden führt fünf Stücke je Platz; was in der `ListView` weiter
      // unten steht, wird gar nicht erst gebaut — und was nicht gebaut
      // wird, findet `find.text` nicht (`docs/context/gotchas.md`).
      final gefunden = <String>{};
      for (var i = 0; i < 12; i++) {
        for (final slot in GearSlot.values) {
          if (find.text(slot.label).evaluate().isNotEmpty) {
            gefunden.add(slot.label);
          }
        }
        await tester.drag(find.byType(Scaffold), const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      for (final slot in GearSlot.values) {
        expect(gefunden, contains(slot.label), reason: slot.label);
      }
    });

    testWidgets('nennt bei jeder Waffe, welchen Zug sie mitbringt', (
      tester,
    ) async {
      // **Fünf Waffen mit fünf Rhythmen sind nur dann eine
      // Entscheidung, wenn man vor dem Kauf sieht, welchen man
      // bekommt** (Ziel 3). Die Waffen stehen zuoberst im Laden, also
      // ohne Scrollen erreichbar.
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      for (final waffe in GearCatalog.forSlot(GearSlot.waffe)) {
        final zeile = weaponAbilityLine(waffe);

        expect(zeile, isNotNull, reason: waffe.name);
        expect(find.text(zeile!), findsOneWidget, reason: waffe.name);
      }
    });

    testWidgets('zeigt das erste Stück mit Namen und Seltenheit', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Übungsklinge'), findsOneWidget);
      expect(find.text(GearRarity.common.label), findsWidgets);
    });

    testWidgets('ohne Gold ist Kaufen aus', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<FilledButton>(
        find.widgetWithText(FilledButton, 'Kaufen'),
      );

      expect(buttons, isNotEmpty);
      expect(buttons.every((b) => b.onPressed == null), isTrue);
    });

    testWidgets('sagt, wie viel noch fehlt', (tester) async {
      // „Geht nicht" ohne Grund ist die häufigste Art, jemanden zu
      // verlieren.
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tage Gewohnheiten'), findsWidgets);
    });

    testWidgets('mit Gold lässt sich kaufen und es wird angelegt', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitGold(), const ShopScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Kaufen').first);
      await tester.pumpAndSettle();

      expect(find.text('getragen'), findsWidgets);
    });
  });

  group('Sets im Bild', () {
    /// Ein Stand, der die [anzahl] billigsten Teile eines Sets trägt.
    SaveData mitTeilenVon(GearSet set, int anzahl) {
      var loadout = const Loadout.empty();
      for (final item in GearCatalog.piecesOf(set.id).take(anzahl)) {
        loadout = loadout.buy(item.id, availableGold: 100000);
      }
      return SaveData(loadout: loadout);
    }

    testWidgets('der Laden nennt die Set-Zugehörigkeit', (tester) async {
      // Wer nach einem Set kauft, sucht im Laden — nicht auf einem
      // zweiten Bildschirm.
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      final waffe = GearCatalog.piecesOf(
        GearSets.eisernerWille.id,
      ).firstWhere((i) => i.slot == GearSlot.waffe);

      expect(find.text(waffe.name), findsOneWidget);
      expect(
        find.textContaining('Teil von „${GearSets.eisernerWille.name}"'),
        findsWidgets,
      );
    });

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
      container.read(loadoutProvider.notifier).buy(klinge);
      await tester.pumpAndSettle();

      // Die Zahl kommt aus dem Katalog, nicht aus diesem Test — sonst
      // fällt er bei jeder Preisrunde um, ohne dass etwas kaputt ist.
      final bonus = GearCatalog.byId(klinge)!.bonus.attack;
      expect(find.textContaining('+$bonus Ausrüstung'), findsOneWidget);
    });
  });
}

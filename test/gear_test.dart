import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/shop_screen.dart';
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

  group('ShopScreen', () {
    testWidgets('zeigt jeden Platz und jedes Stück', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(
        appMit(const SaveData.empty(), const ShopScreen()),
      );
      await tester.pumpAndSettle();

      for (final slot in GearSlot.values) {
        expect(find.text(slot.label), findsWidgets, reason: slot.label);
      }
      expect(find.text('Übungsklinge'), findsOneWidget);
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
      expect(find.text('leer'), findsNWidgets(GearSlot.values.length));
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

      expect(find.textContaining('+1 Ausrüstung'), findsOneWidget);
    });
  });
}

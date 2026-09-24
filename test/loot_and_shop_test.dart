import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/action/hero_power.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/gear/copy_text.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/gear/widgets/shop_item_cell.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'gear_helpers.dart';
import 'test_view.dart';

/// Exemplare, Tagesladen, Beute, Schlüssel und Bestzeiten in der App
/// (ADR-0048). Die Regeln selbst prüft `packages/gear`; hier geht es um
/// die Nähte: was die App hereinreicht und was der Bildschirm zeigt.
void main() {
  const heute = Day(2026, 9, 24);

  /// Ein Stand mit Gold: alle Lektionen bestanden und [tage] Tage lang
  /// fünf Gewohnheiten abgehakt — das gibt auch Schlüssel.
  SaveData stand({int tage = 20, int rung = 0, Loadout? loadout}) {
    var progress = const TheoryProgress.empty();
    for (final branch in theoryTree.branches) {
      for (final lesson in branch.lessons) {
        progress = progress.submit(lesson, <int?>[
          for (final q in lesson.questions) q.correctIndex,
        ]).progress;
      }
    }
    final ids = HabitCatalog.all
        .take(HabitRewards.maxActiveHabits)
        .map((t) => t.id)
        .toList();
    var tracker = const HabitTracker.empty();
    for (final id in ids) {
      tracker = tracker.activate(id);
    }
    var tag = const Day(2026, 8, 1);
    for (var i = 0; i < tage; i++) {
      for (final id in ids) {
        tracker = tracker.check(id, tag).tracker;
      }
      tag = tag.next;
    }
    var ladder = const LadderProgress.empty();
    for (var r = 1; r <= rung; r++) {
      ladder = ladder.defeat(r);
    }
    return SaveData(
      theory: progress,
      habits: tracker,
      ladder: ladder,
      loadout: loadout ?? const Loadout.empty(),
    );
  }

  ProviderContainer mit(SaveData saved) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        todayProvider.overrideWithValue(heute),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Der Massstab', () {
    test('die Ausrüstung rechnet so gross wie der Kampf', () {
      // Zwei Packages kennen einander nicht und müssen dieselbe Zahl
      // haben — sonst stünde „+11" im Laden und „+110" im Kampf.
      expect(GearBonus.combatScale, ActionBalance.powerScale);
    });

    test('ein gewürfelter Wert kommt im Kampf an, nicht gerundet', () {
      final klinge = GearCatalog.byId('gear-streitkolben')!;
      final schwach = GearCopy(
        uid: 'a',
        itemId: klinge.id,
        bonus: GearBonus(attack: klinge.bonus.scaled.attack - 1),
        paid: 0,
      );
      final stark = GearCopy(
        uid: 'b',
        itemId: klinge.id,
        bonus: GearBonus(attack: klinge.bonus.scaled.attack + 1),
        paid: 0,
      );
      int angriff(GearCopy c) => mit(
        stand(loadout: const Loadout.empty().addFree(c)),
      ).read(heroPowerProvider).stats.combatAttack;
      expect(angriff(stark), greaterThan(angriff(schwach)));
    });
  });

  group('Schlüssel', () {
    test('jedes Häkchen ist einer — höchstens zehn auf Vorrat', () {
      final c = mit(stand(tage: 1));
      expect(
        c.read(earnedKeysProvider),
        greaterThanOrEqualTo(HabitRewards.maxActiveHabits),
      );
      expect(c.read(availableKeysProvider), GearKeys.cap);
    });

    test('ohne irgendetwas gibt es keinen', () {
      final c = mit(const SaveData());
      expect(c.read(availableKeysProvider), 0);
    });
  });

  group('Die Beute des Wächters', () {
    test('der erste Sieg bringt ein Stück, ohne Schlüssel', () {
      final c = mit(const SaveData());
      final beute = c
          .read(loadoutProvider.notifier)
          .takeLoot(stage: 1, useKey: false);
      expect(beute, isNotNull);
      expect(c.read(loadoutProvider).owns(beute!.uid), isTrue);
      expect(c.read(loadoutProvider).keysConsumed, 0);
    });

    test('ohne Schlüssel bleibt die Beute liegen', () {
      final c = mit(const SaveData());
      expect(
        c.read(loadoutProvider.notifier).takeLoot(stage: 3, useKey: true),
        isNull,
      );
      expect(c.read(loadoutProvider).ownedCopies, isEmpty);
    });

    test('mit Schlüssel: ein Stück, ein Schlüssel weniger', () {
      final c = mit(stand(tage: 1));
      final vorher = c.read(availableKeysProvider);
      final beute = c
          .read(loadoutProvider.notifier)
          .takeLoot(stage: 3, useKey: true);
      expect(beute, isNotNull);
      expect(c.read(availableKeysProvider), vorher - 1);
    });

    test('zwei Beuten sind zwei Exemplare', () {
      final c = mit(stand(tage: 1));
      final a = c
          .read(loadoutProvider.notifier)
          .takeLoot(stage: 3, useKey: true);
      final b = c
          .read(loadoutProvider.notifier)
          .takeLoot(stage: 3, useKey: true);
      expect(a!.uid, isNot(b!.uid));
      expect(c.read(loadoutProvider).ownedCopies, hasLength(2));
    });

    test('Beute kostet kein Gold', () {
      final c = mit(stand(tage: 1));
      final vorher = c.read(goldProvider);
      c.read(loadoutProvider.notifier).takeLoot(stage: 3, useKey: true);
      expect(c.read(goldProvider), greaterThanOrEqualTo(vorher));
    });
  });

  group('Bestzeiten', () {
    test('ein Sieg hält seine Zeit fest, nur eine schnellere ersetzt sie', () {
      final c = mit(const SaveData());
      final reihe = c.read(ladderProvider.notifier);
      reihe.recordRun(1, won: true, seconds: 64.23);
      expect(c.read(ladderProvider).bestTimes[1], 64.2);
      reihe.recordRun(1, won: true, seconds: 80);
      expect(c.read(ladderProvider).bestTimes[1], 64.2);
      reihe.recordRun(1, won: true, seconds: 51);
      expect(c.read(ladderProvider).bestTimes[1], 51);
    });

    test('eine Niederlage hat keine Zeit', () {
      final c = mit(const SaveData());
      c.read(ladderProvider.notifier).recordRun(1, won: false, seconds: 12);
      expect(c.read(ladderProvider).bestTimes, isEmpty);
    });

    test('Bestzeiten überleben Speichern und Laden', () {
      final l = const LadderProgress.empty().defeat(1).recordTime(1, 42.5);
      final gelesen = LadderProgress.fromJson(l.toJson());
      expect(gelesen.bestTimes[1], 42.5);
      expect(gelesen, l);
    });
  });

  group('Der Laden auf dem Bildschirm', () {
    Widget app(SaveData saved) => ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        todayProvider.overrideWithValue(heute),
      ],
      child: const MaterialApp(home: ShopScreen()),
    );

    testWidgets('heute: sechs Angebote, eins je Platz', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(app(stand()));
      await tester.pumpAndSettle();

      final zellen = tester.widgetList<ShopItemCell>(find.byType(ShopItemCell));
      expect(zellen, hasLength(GearSlot.values.length));
      expect(
        zellen.map((z) => z.copy.item!.slot).toSet(),
        GearSlot.values.toSet(),
      );
    });

    testWidgets('die Detailfläche zeigt den Wurf, nicht den Katalog', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(app(stand()));
      await tester.pumpAndSettle();

      final erstes = tester
          .widgetList<ShopItemCell>(find.byType(ShopItemCell))
          .first
          .copy;
      expect(find.text(CopyText.line(erstes)), findsOneWidget);
    });

    testWidgets('ohne Gold ist jedes Angebot ausgegraut und Kaufen aus', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(app(const SaveData()));
      await tester.pumpAndSettle();

      for (final zelle in tester.widgetList<ShopItemCell>(
        find.byType(ShopItemCell),
      )) {
        expect(zelle.isOutOfReach, isTrue);
      }
      final kaufen = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Kaufen'),
      );
      expect(kaufen.onPressed, isNull);
    });

    testWidgets('kaufen legt das Angebot ins Inventar, einmal', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(app(stand()));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShopScreen)),
      );
      final angebot = container.read(dailyOffersProvider).first;
      await tester.tap(find.widgetWithText(FilledButton, 'Kaufen'));
      await tester.pumpAndSettle();
      while (find
          .widgetWithText(FilledButton, 'Weiter')
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.widgetWithText(FilledButton, 'Weiter').last);
        await tester.pumpAndSettle();
      }

      expect(container.read(loadoutProvider).owns(angebot.uid), isTrue);
      expect(find.text('gekauft'), findsWidgets);
    });

    testWidgets('im Inventar: verkaufen nach Rückfrage, ein Viertel zurück', (
      tester,
    ) async {
      useTallView(tester);
      final klinge = GearCatalog.byId('gear-uebungsklinge')!;
      final saved = stand(
        loadout: const Loadout.empty().addFree(angebot(klinge.id)),
      );
      await tester.pumpWidget(app(saved));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Inventar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Verkaufen'));
      await tester.pumpAndSettle();

      final erloes = Loadout.refundFor(klinge);
      expect(find.textContaining('Das bringt $erloes Gold'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Verkaufen'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShopScreen)),
      );
      expect(container.read(loadoutProvider).ownsItem(klinge.id), isFalse);
    });

    testWidgets('alles Schlechtere verkaufen räumt den Ausschuss', (
      tester,
    ) async {
      useTallView(tester);
      const stark = GearCopy(
        uid: 's',
        itemId: 'gear-streitkolben',
        bonus: GearBonus(attack: 40),
        paid: 0,
      );
      const schwach = GearCopy(
        uid: 'w',
        itemId: 'gear-streitkolben',
        bonus: GearBonus(attack: 30),
        paid: 0,
      );
      await tester.pumpWidget(
        app(
          stand(loadout: const Loadout.empty().addFree(stark).addFree(schwach)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inventar'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Alles Schlechtere verkaufen'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Verkaufen'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ShopScreen)),
      );
      expect(container.read(loadoutProvider).owns('w'), isFalse);
      expect(container.read(loadoutProvider).owns('s'), isTrue);
      expect(find.textContaining('Alles Schlechtere'), findsNothing);
    });
  });
}

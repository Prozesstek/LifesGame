import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Naht zwischen `package:gear` und `package:combat` für die Sperre
/// auf Episch und Legendär (ADR-0034).
///
/// `gear` hält nur zwei Zahlen — „ab Sprosse 10", „ab Sprosse 20" — und
/// weiß nicht, ob es diese Sprossen gibt. `combat` hält die Reihe und weiß
/// nichts vom Laden. Gleiche Bauform wie `test/gear_sets_seam_test.dart`.
void main() {
  /// Ein Stand mit genug Gold für jedes Stück im Laden — auch die
  /// verdienten. Die Theorie allein gibt rund 485; die 1150 des ersten
  /// epischen Stücks brauchen dazu zwei Monate Häkchen.
  SaveData mitGold({int rung = 0}) {
    var progress = const TheoryProgress.empty();
    for (final branch in theoryTree.branches) {
      for (final lesson in branch.lessons) {
        progress = progress.submit(lesson, <int?>[
          for (final question in lesson.questions) question.correctIndex,
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
    var tag = const Day(2026, 1, 1);
    for (var i = 0; i < 80; i++) {
      for (final id in ids) {
        tracker = tracker.check(id, tag).tracker;
      }
      tag = tag.next;
    }

    var ladder = const LadderProgress.empty();
    for (var r = 1; r <= rung; r++) {
      ladder = ladder.defeat(r);
    }
    return SaveData(theory: progress, habits: tracker, ladder: ladder);
  }

  group('Die Sprossen gibt es', () {
    test('beide Sperren liegen innerhalb der Reihe', () {
      // **Die Richtung, die leicht auseinanderläuft.** Würde die Reihe
      // auf zwanzig gekürzt, stünde Legendär hinter dem letzten Gegner —
      // sichtbar im Laden, für immer gesperrt, und niemand merkt es.
      expect(GearGates.epicRung, inInclusiveRange(1, PitStage.count));
      expect(GearGates.legendaryRung, inInclusiveRange(1, PitStage.count));
    });

    test('nach Legendär bleibt noch etwas zu kämpfen', () {
      // Sonst schaltete der letzte Sieg Ausrüstung frei, die gegen nichts
      // mehr getragen werden kann.
      expect(GearGates.legendaryRung, lessThan(PitStage.count));
    });
  });

  group('Der Kauf fragt die Reihe', () {
    final episch = GearCatalog.all.firstWhere(
      (i) => i.rarity == GearRarity.epic,
    );
    final legendaer = GearCatalog.all.firstWhere(
      (i) => i.rarity == GearRarity.legendary,
    );

    test('ohne Siege ist Episches gesperrt, mit Gold in der Tasche', () {
      final container = ProviderContainer(
        overrides: [savedGameProvider.overrideWithValue(mitGold())],
      );
      addTearDown(container.dispose);

      expect(container.read(goldProvider), greaterThanOrEqualTo(episch.price));
      expect(
        container.read(loadoutProvider.notifier).buy(episch.id),
        PurchaseBlock.gesperrt,
      );
      expect(container.read(loadoutProvider).isOwned(episch.id), isFalse);
    });

    test('ein Sieg auf der Sprosse schließt Episches auf', () {
      // **Der ganze Weg**: Reihe → Controller → Laden. Beide Enden getrennt
      // zu prüfen hat schon einmal einen Fehler durchgelassen.
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(
            mitGold(rung: GearGates.epicRung - 1),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(loadoutProvider.notifier).buy(episch.id),
        PurchaseBlock.gesperrt,
      );

      container.read(ladderProvider.notifier).defeat(GearGates.epicRung);

      expect(container.read(loadoutProvider.notifier).buy(episch.id), isNull);
      expect(container.read(loadoutProvider).isOwned(episch.id), isTrue);
    });

    test('Episch reicht nicht für Legendär', () {
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(
            mitGold(rung: GearGates.epicRung),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(loadoutProvider.notifier).buy(legendaer.id),
        PurchaseBlock.gesperrt,
      );
    });

    test('der Entwicklermodus schenkt auch Gesperrtes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loadoutProvider.notifier).grant(legendaer.id);

      expect(container.read(loadoutProvider).isOwned(legendaer.id), isTrue);
    });
  });

  group('Der Laden zeigt die Sperre', () {
    Widget appMit(SaveData saved) {
      return ProviderScope(
        overrides: [savedGameProvider.overrideWithValue(saved)],
        child: const MaterialApp(home: ShopScreen()),
      );
    }

    testWidgets('ein gesperrtes Stück nennt die Sprosse', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitGold()));
      await tester.pumpAndSettle();

      // Die Waffen liegen auf dem ersten Reiter; der Zweihänder ist das
      // erste epische Stück im Raster.
      final episch = GearCatalog.forSlot(
        GearSlot.waffe,
      ).firstWhere((i) => i.rarity == GearRarity.epic);
      await tester.tap(find.text(episch.name));
      await tester.pumpAndSettle();

      expect(
        find.text('Verdient ab Gegner ${GearGates.epicRung} der Reihe.'),
        findsOneWidget,
      );
      expect(find.text('gesperrt'), findsWidgets);
      final kaufen = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Kaufen'),
      );
      expect(kaufen.onPressed, isNull);
    });

    testWidgets('mit der Sprosse ist es ein Kauf wie jeder andere', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitGold(rung: GearGates.epicRung)));
      await tester.pumpAndSettle();

      final episch = GearCatalog.forSlot(
        GearSlot.waffe,
      ).firstWhere((i) => i.rarity == GearRarity.epic);
      await tester.tap(find.text(episch.name));
      await tester.pumpAndSettle();

      expect(find.textContaining('Verdient ab Gegner'), findsNothing);
      final kaufen = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Kaufen'),
      );
      expect(kaufen.onPressed, isNotNull);
    });
  });
}

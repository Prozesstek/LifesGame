import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/widgets/daily_chest_card.dart';
import 'package:lifes_game/habits/widgets/truhe_oeffnen.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// **Die Tagestruhe kommt von selbst** (ADR-0102): nach dem letzten
/// Häkchen groß in der Mitte, drei Tipps, dann springt sie in der Farbe
/// ihrer Seltenheit auf.
void main() {
  const heute = Day(2026, 10, 20);

  group('TruheOeffnen', () {
    Future<(List<int>, List<bool>)> zeige(
      WidgetTester tester,
      ChestContent inhalt,
    ) async {
      final tipps = <int>[];
      final auf = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: TruheOeffnen(
            inhalt: inhalt,
            onTipp: tipps.add,
            onAuf: () => auf.add(true),
            onFertig: () {},
          ),
        ),
      );
      return (tipps, auf);
    }

    testWidgets('erst der dritte Tipp öffnet, vorher keine Seltenheit', (
      tester,
    ) async {
      final inhalt = DailyChest.forDay(heute);
      final (tipps, auf) = await zeige(tester, inhalt);

      for (var i = 0; i < TruheOeffnen.tipps - 1; i++) {
        await tester.tap(find.byKey(TruheOeffnen.truheKey));
        await tester.pumpAndSettle();
      }
      expect(auf, isEmpty);
      expect(find.byKey(TruheOeffnen.stufeKey), findsNothing);
      expect(find.byKey(DailyChestCard.einsackenKey), findsNothing);

      await tester.tap(find.byKey(TruheOeffnen.truheKey));
      await tester.pumpAndSettle();
      expect(auf, hasLength(1));
      expect(find.text(inhalt.tier.label), findsOneWidget);
      expect(find.text('+${inhalt.gold}'), findsOneWidget);

      // Offen ist offen: Ein weiterer Tipp bucht nicht zweimal.
      await tester.tap(find.byKey(TruheOeffnen.truheKey));
      await tester.pumpAndSettle();
      expect(auf, hasLength(1));
      expect(tipps, <int>[1, 2, 3]);
    });

    testWidgets('das Eis springt nur aus einer epischen Truhe', (tester) async {
      const episch = ChestContent(tier: ChestTier.eis, gold: 5, freezes: 1);
      await zeige(tester, episch);
      for (var i = 0; i < TruheOeffnen.tipps; i++) {
        await tester.tap(find.byKey(TruheOeffnen.truheKey));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.pumpAndSettle();

      expect(find.text('Episch'), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    test('jede Stufe trägt eine eigene Seltenheit', () {
      final seltenheiten = ChestTier.values.map(TruhenSeltenheit.von).toSet();
      expect(seltenheiten, hasLength(ChestTier.values.length));
      expect(
        TruhenSeltenheit.von(ChestTier.schatz),
        GearRarity.legendary,
        reason: 'Der Schatz ist die seltenste Truhe.',
      );
      for (final stufe in ChestTier.values) {
        expect(stufe.label, TruhenSeltenheit.von(stufe).label);
      }
    });
  });

  group('nach dem letzten Häkchen', () {
    final habit = HabitCatalog.all.firstWhere(
      (t) => t.id != HabitCatalog.starter.id && t.goal == null,
    );

    // Gestern erledigt, damit die Feiern des Anfangs zurückliegen.
    HabitTracker offen() {
      final t = const HabitTracker.empty().activate(habit.id);
      return t.check(habit.id, heute.previous).tracker;
    }

    Future<ProviderContainer> startseite(
      WidgetTester tester, {
      required bool feuerOffen,
    }) async {
      useTallView(tester);
      final c = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(SaveData(habits: offen())),
          todayProvider.overrideWithValue(heute),
          if (feuerOffen)
            ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      return c;
    }

    Future<void> hakeAb(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.text(habit.name),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('kommt sie von selbst und bucht erst beim Aufgehen', (
      tester,
    ) async {
      final c = await startseite(tester, feuerOffen: true);
      await hakeAb(tester);

      expect(find.byType(TruheOeffnen), findsOneWidget);
      expect(c.read(habitTrackerProvider).canOpenChest(heute), isTrue);

      for (var i = 0; i < TruheOeffnen.tipps; i++) {
        await tester.tap(find.byKey(TruheOeffnen.truheKey));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.pumpAndSettle();
      expect(c.read(habitTrackerProvider).hasOpenedChest(heute), isTrue);

      await tester.tap(find.byKey(DailyChestCard.einsackenKey));
      await tester.pumpAndSettle();
      expect(find.byType(TruheOeffnen), findsNothing);
    });

    testWidgets('das Kreuz schließt, und sie wartet am Feuer', (tester) async {
      final c = await startseite(tester, feuerOffen: true);
      await hakeAb(tester);
      await tester.tap(find.byKey(TruheOeffnen.truheKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(TruheOeffnen.spaeterKey));
      await tester.pumpAndSettle();

      expect(find.byType(TruheOeffnen), findsNothing);
      expect(c.read(habitTrackerProvider).canOpenChest(heute), isTrue);
    });

    testWidgets('vor dem Lagerfeuer kommt sie nicht', (tester) async {
      final c = await startseite(tester, feuerOffen: false);
      expect(c.read(ersterStartProvider).zeigtTagesaufgaben, isFalse);

      await hakeAb(tester);
      expect(find.byType(TruheOeffnen), findsNothing);
    });
  });
}

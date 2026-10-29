import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/lagerfeuer/morgen_zuerst_frage.dart';
import 'package:lifes_game/lagerfeuer/widgets/morgen_zuerst.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// **„Morgen zuerst“ nach dem geschafften Tag** (29.10.2026): Wer die
/// letzte Gewohnheit abhakt, wird gefeiert und dann gefragt, was morgen
/// zuerst drankommt — wie am Lagerfeuer.
void main() {
  const heute = Day(2026, 10, 20);
  final zwei = HabitCatalog.all
      .where((t) => t.id != HabitCatalog.starter.id)
      .take(2)
      .toList(growable: false);
  final a = zwei[0];
  final b = zwei[1];

  // Gestern beide erledigt, heute schon die erste: Die zweite schafft
  // den Tag, und die Feiern des Anfangs liegen zurück.
  HabitTracker fastGeschafft() {
    var tracker = const HabitTracker.empty().activate(a.id).activate(b.id);
    tracker = tracker.check(a.id, heute.previous).tracker;
    tracker = tracker.check(b.id, heute.previous).tracker;
    return tracker.check(a.id, heute).tracker;
  }

  Future<ProviderContainer> startseite(
    WidgetTester tester,
    HabitTracker tracker,
  ) async {
    useTallView(tester);
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        todayProvider.overrideWithValue(heute),
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

  Future<void> hakeAb(WidgetTester tester, Habit habit) async {
    await tester.tap(
      find.descendant(
        of: find.byType(TodayCard),
        matching: find.text(habit.name),
      ),
    );
    await tester.pumpAndSettle();
  }

  final frage = find.byType(MorgenZuerstFrage);

  testWidgets('die letzte Gewohnheit fragt nach morgen, ein Tipp wählt', (
    tester,
  ) async {
    final c = await startseite(tester, fastGeschafft());

    await hakeAb(tester, b);
    expect(frage, findsOneWidget);

    await tester.tap(find.byKey(MorgenZuerst.knopfKey(b.id)));
    await tester.pump();
    await tester.pump(
      MorgenZuerstFrage.nachhall + const Duration(milliseconds: 50),
    );
    await tester.pumpAndSettle();
    expect(frage, findsNothing, reason: 'nach der Wahl geht sie zu');
    expect(c.read(habitTrackerProvider).firstUpOn(heute.next), b.id);
  });

  testWidgets('„Später“ schließt, ohne zu wählen', (tester) async {
    final c = await startseite(tester, fastGeschafft());
    await hakeAb(tester, b);

    await tester.tap(find.byKey(MorgenZuerstFrage.spaeterKey));
    await tester.pumpAndSettle();
    expect(frage, findsNothing);
    expect(c.read(habitTrackerProvider).firstUpOn(heute.next), isNull);
  });

  testWidgets('wer am Feuer schon gewählt hat, wird nicht gefragt', (
    tester,
  ) async {
    await startseite(tester, fastGeschafft().setFirstUp(heute.next, a.id));
    await hakeAb(tester, b);
    expect(frage, findsNothing);
  });

  testWidgets('ist morgen nur eine fällig, gibt es nichts zu fragen', (
    tester,
  ) async {
    final tracker = const HabitTracker.empty()
        .activate(a.id)
        .check(a.id, heute.previous)
        .tracker;
    await startseite(tester, tracker);
    await hakeAb(tester, a);
    expect(frage, findsNothing);
  });

  testWidgets('ein Häkchen, das den Tag nicht schafft, fragt nicht', (
    tester,
  ) async {
    var tracker = const HabitTracker.empty().activate(a.id).activate(b.id);
    tracker = tracker.check(a.id, heute.previous).tracker;
    await startseite(tester, tracker);
    await hakeAb(tester, a);
    expect(frage, findsNothing);
  });
}

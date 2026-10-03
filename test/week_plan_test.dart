import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/daily_chest_card.dart';
import 'package:lifes_game/habits/widgets/habit_check_tile.dart';
import 'package:lifes_game/habits/widgets/weekday_picker.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Der Wochenplan in der App (ADR-0064): vom Kreis im Dialog bis zur
/// Tagesliste.
///
/// Der 07.10.2026 ist ein Mittwoch.
void main() {
  const mittwoch = Day(2026, 10, 7);
  final starter = HabitCatalog.starter;
  final zweite = HabitCatalog.all.firstWhere((t) => t.id != starter.id);

  ProviderContainer container(HabitTracker tracker, {Day heute = mittwoch}) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        todayProvider.overrideWithValue(heute),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> zeige(
    WidgetTester tester,
    ProviderContainer c,
    Widget screen,
  ) async {
    useTallView(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump();
  }

  HabitTracker laeuft() =>
      const HabitTracker.empty().activate(starter.id, today: mittwoch);

  Future<void> oeffneDialog(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(HabitCheckTile),
        matching: find.byIcon(Icons.add_alarm_outlined),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('der 07.10.2026 ist ein Mittwoch', () {
    expect(mittwoch.weekday, 3);
  });

  group('Der Dialog', () {
    testWidgets('zeigt sieben Kreise, alle gewählt', (tester) async {
      await zeige(tester, container(laeuft()), const HabitsScreen());
      await oeffneDialog(tester);

      for (final tag in Wochentage.alle) {
        expect(find.byKey(WeekdayPicker.keyFor(tag)), findsOneWidget);
        expect(find.text(Wochentage.kurz(tag)), findsOneWidget);
      }
    });

    testWidgets('abgewählte Tage landen im Plan', (tester) async {
      final c = container(laeuft());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester);

      for (final tag in <int>[2, 4, 6, 7]) {
        await tester.tap(find.byKey(WeekdayPicker.keyFor(tag)));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.weekdaysFor(starter.id), const <int>{1, 3, 5});
      // Noch nichts abgehakt: Der Plan gilt sofort.
      expect(tracker.isDueOn(starter.id, mittwoch.next), isFalse);
      // Und die Kachel sagt, an welchen Tagen.
      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.text('Mo Mi Fr'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('der letzte Tag lässt sich nicht abwählen', (tester) async {
      final c = container(laeuft());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester);

      for (final tag in Wochentage.alle) {
        await tester.tap(find.byKey(WeekdayPicker.keyFor(tag)));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      // Sonntag wurde zuletzt getippt und blieb stehen.
      expect(c.read(habitTrackerProvider).weekdaysFor(starter.id), const <int>{
        7,
      });
    });

    testWidgets('„Später“ ändert die Tage nicht', (tester) async {
      final c = container(laeuft());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester);

      await tester.tap(find.byKey(WeekdayPicker.keyFor(3)));
      await tester.pump();
      await tester.tap(find.text('Später'));
      await tester.pumpAndSettle();

      expect(
        c.read(habitTrackerProvider).weekdaysFor(starter.id),
        HabitPlan.everyDay,
      );
    });

    testWidgets('nach dem ersten Häkchen gelten neue Tage ab morgen', (
      tester,
    ) async {
      final gestern = mittwoch.previous;
      final tracker = const HabitTracker.empty()
          .activate(starter.id, today: gestern)
          .check(starter.id, gestern)
          .tracker;
      final c = container(tracker);
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester);

      expect(find.textContaining('gelten ab morgen'), findsNothing);
      await tester.tap(find.byKey(WeekdayPicker.keyFor(3)));
      await tester.pump();
      expect(find.textContaining('gelten ab morgen'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      final danach = c.read(habitTrackerProvider);
      // Heute ist Mittwoch und bleibt fällig, obwohl er abgewählt ist.
      expect(danach.isDueOn(starter.id, mittwoch), isTrue);
      expect(find.byType(HabitCheckTile), findsOneWidget);
      var naechsterMittwoch = mittwoch;
      for (var i = 0; i < 7; i++) {
        naechsterMittwoch = naechsterMittwoch.next;
      }
      expect(danach.isDueOn(starter.id, naechsterMittwoch), isFalse);
    });
  });

  group('Heute nicht fällig', () {
    /// Die Startvorlage nur donnerstags, die zweite jeden Tag.
    HabitTracker gemischt() => laeuft()
        .activate(zweite.id, today: mittwoch)
        .setWeekdays(starter.id, const <int>{4}, today: mittwoch);

    testWidgets('steht nicht zum Abhaken da, aber mit ihren Tagen', (
      tester,
    ) async {
      await zeige(tester, container(gemischt()), const HabitsScreen());

      expect(find.byType(HabitCheckTile), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HabitCheckTile),
          matching: find.text(zweite.name),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Heute nicht fällig'), findsOneWidget);
      final ruhend = find.byKey(ValueKey<String>('nicht-heute-${starter.id}'));
      expect(ruhend, findsOneWidget);
      expect(
        find.descendant(of: ruhend, matching: find.text('Do')),
        findsOneWidget,
      );
      // Der Stand oben zählt nur, was heute dran ist — nicht beide.
      // („0 / 1" steht auch am Reiter der eigenen, deshalb die Gegenprobe.)
      expect(find.text('0 / 2'), findsNothing);
      expect(find.text('0 / 1'), findsWidgets);
    });

    testWidgets('lässt sich von dort stoppen', (tester) async {
      final c = container(gemischt());
      await zeige(tester, c, const HabitsScreen());

      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey<String>('nicht-heute-${starter.id}')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).isActive(starter.id), isFalse);
    });

    testWidgets('die Truhe verlangt nur, was heute fällig ist', (tester) async {
      final c = container(gemischt());
      await zeige(tester, c, const HabitsScreen());
      expect(find.byType(DailyChestCard), findsNothing);

      await tester.tap(find.text(zweite.name));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).canOpenChest(mittwoch), isTrue);
      expect(find.byType(DailyChestCard), findsOneWidget);
    });

    testWidgets('die Startseite zählt nur, was heute dran ist', (tester) async {
      await zeige(tester, container(gemischt()), const HomeScreen());

      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.text('0 / 1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.text(starter.name),
        ),
        findsNothing,
      );
    });

    testWidgets('an einem Ruhetag sagt die Startseite das', (tester) async {
      final nurDonnerstag = laeuft().setWeekdays(starter.id, const <int>{
        4,
      }, today: mittwoch);
      await zeige(tester, container(nurDonnerstag), const HomeScreen());

      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.bySemanticsLabel(RegExp('Ruhetag')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.bySemanticsLabel('Erste Gewohnheit starten'),
        ),
        findsNothing,
      );
    });
  });

  group('Stoppen und wieder aufnehmen', () {
    testWidgets('die Kette steht still und läuft danach weiter', (
      tester,
    ) async {
      // Drei Tage abgehakt, am dritten gestoppt, zehn Tage später wieder da.
      var tag = mittwoch;
      var tracker = laeuft();
      for (var i = 0; i < 3; i++) {
        tracker = tracker.check(starter.id, tag).tracker;
        tag = tag.next;
      }
      final letzter = tag.previous;
      tracker = tracker.deactivate(starter.id, today: letzter);
      var spaeter = letzter;
      for (var i = 0; i < 10; i++) {
        spaeter = spaeter.next;
      }

      final c = container(tracker, heute: spaeter);
      await zeige(tester, c, const HabitsScreen());
      c.read(habitTrackerProvider.notifier).activate(starter.id);
      await tester.pumpAndSettle();

      final danach = c.read(habitTrackerProvider);
      expect(danach.currentStreak(starter.id, spaeter), 3);
      expect(danach.check(starter.id, spaeter).streak, 4);
    });
  });
}

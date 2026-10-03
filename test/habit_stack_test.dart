import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/cue_dialog.dart';
import 'package:lifes_game/habits/widgets/habit_check_tile.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Gewohnheiten koppeln in der App (ADR-0065): vom Dialog bis zur
/// Kachel, die aufleuchtet.
void main() {
  const heute = Day(2026, 10, 7);
  final anker = HabitCatalog.all[0];
  final folge = HabitCatalog.all[1];
  final dritte = HabitCatalog.all[2];

  HabitTracker laufen() => const HabitTracker.empty()
      .activate(anker.id, today: heute)
      .activate(dritte.id, today: heute)
      .activate(folge.id, today: heute);

  ProviderContainer container(HabitTracker tracker) {
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

  /// Die Kachel von [habit].
  Finder kachel(HabitTemplate habit) => find.ancestor(
    of: find.text(habit.name),
    matching: find.byType(HabitCheckTile),
  );

  Future<void> oeffneDialog(WidgetTester tester, HabitTemplate habit) async {
    await tester.tap(
      find.descendant(
        of: kachel(habit),
        matching: find.byIcon(Icons.add_alarm_outlined),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Der Dialog', () {
    testWidgets('bietet die anderen laufenden Gewohnheiten an', (tester) async {
      await zeige(tester, container(laufen()), const HabitsScreen());
      await oeffneDialog(tester, folge);

      expect(find.byKey(cueAnchorKey(anker.id)), findsOneWidget);
      expect(find.byKey(cueAnchorKey(dritte.id)), findsOneWidget);
      // Sich selbst nicht.
      expect(find.byKey(cueAnchorKey(folge.id)), findsNothing);
    });

    testWidgets('eine gewählte landet als Anker im Stand und auf der Kachel', (
      tester,
    ) async {
      final c = container(laufen());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, folge);

      await tester.tap(find.byKey(cueAnchorKey(anker.id)));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.anchorFor(folge.id), anker.id);
      expect(tracker.cueFor(folge.id), isNull);
      expect(
        find.descendant(
          of: kachel(folge),
          matching: find.text('Nach: ${anker.name}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('wer danach tippt, löst die Kopplung wieder', (tester) async {
      final c = container(laufen());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, folge);

      await tester.tap(find.byKey(cueAnchorKey(anker.id)));
      await tester.pump();
      await tester.enterText(find.byKey(cueFieldKey), 'Nach dem Kaffee');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.anchorFor(folge.id), isNull);
      expect(tracker.cueFor(folge.id), 'Nach dem Kaffee');
    });

    testWidgets('was einen Kreis schlösse, steht nicht zur Wahl', (
      tester,
    ) async {
      final c = container(laufen().setAnchor(folge.id, anker.id));
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, anker);

      expect(find.byKey(cueAnchorKey(folge.id)), findsNothing);
      expect(find.byKey(cueAnchorKey(dritte.id)), findsOneWidget);
    });

    testWidgets('„Entfernen“ löst die Kopplung', (tester) async {
      final c = container(laufen().setAnchor(folge.id, anker.id));
      await zeige(tester, c, const HabitsScreen());
      await tester.tap(find.text('Nach: ${anker.name}'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entfernen'));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).anchorFor(folge.id), isNull);
    });
  });

  group('Der Stapel', () {
    HabitTracker gekoppelt() => laufen().setAnchor(folge.id, anker.id);

    double links(WidgetTester tester, HabitTemplate habit) =>
        tester.getTopLeft(kachel(habit)).dx;

    double oben(WidgetTester tester, HabitTemplate habit) =>
        tester.getTopLeft(kachel(habit)).dy;

    testWidgets('die Folge steht eingerückt direkt unter ihrem Anker', (
      tester,
    ) async {
      await zeige(tester, container(gekoppelt()), const HabitsScreen());

      // Gestartet wurde in der Reihenfolge Anker, Dritte, Folge — die
      // Kopplung zieht die Folge vor die Dritte.
      expect(oben(tester, anker), lessThan(oben(tester, folge)));
      expect(oben(tester, folge), lessThan(oben(tester, dritte)));
      expect(links(tester, folge), greaterThan(links(tester, anker)));
      expect(links(tester, dritte), links(tester, anker));
    });

    testWidgets('nach dem Häkchen am Anker ist die Folge dran', (tester) async {
      final c = container(gekoppelt());
      await zeige(tester, c, const HabitsScreen());
      expect(find.bySemanticsLabel(RegExp('jetzt dran')), findsNothing);

      await tester.tap(find.text(anker.name));
      await tester.pumpAndSettle();

      // Über das Etikett selbst gesucht, nicht unterhalb der Kachel: Der
      // Knoten gehört der Fläche, die ihn zusammenführt.
      expect(
        find.bySemanticsLabel(RegExp('${folge.name}, jetzt dran')),
        findsOneWidget,
      );
      // Der abgehakte Anker bleibt darüber stehen.
      expect(oben(tester, anker), lessThan(oben(tester, folge)));
    });

    testWidgets('die Folge lässt sich auch zuerst abhaken', (tester) async {
      final c = container(gekoppelt());
      await zeige(tester, c, const HabitsScreen());

      await tester.tap(find.text(folge.name));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).isChecked(folge.id, heute), isTrue);
    });

    testWidgets('die Startseite zeigt denselben Stapel', (tester) async {
      final c = container(gekoppelt());
      await zeige(tester, c, const HomeScreen());

      Finder zeile(HabitTemplate h) => find.descendant(
        of: find.byType(TodayCard),
        matching: find.text(h.name),
      );

      expect(
        tester.getTopLeft(zeile(folge)).dx,
        greaterThan(tester.getTopLeft(zeile(anker)).dx),
      );
      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.text('Nach: ${anker.name}'),
        ),
        findsOneWidget,
      );

      await tester.tap(zeile(anker));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('${folge.name} abhaken, jetzt dran')),
        findsOneWidget,
      );
    });
  });
}

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

/// Das Versuchungsbündel in der App (ADR-0066): vom Dialog über die
/// Kachel bis zu „Jetzt: Kaffee“ beim Abhaken.
void main() {
  const heute = Day(2026, 10, 7);
  final habit = HabitCatalog.all[0];
  final andere = HabitCatalog.all[1];

  HabitTracker laufen() => const HabitTracker.empty()
      .activate(habit.id, today: heute)
      .activate(andere.id, today: heute);

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

  Finder kachel(HabitTemplate h) => find.ancestor(
    of: find.text(h.name),
    matching: find.byType(HabitCheckTile),
  );

  Future<void> oeffneDialog(WidgetTester tester, HabitTemplate h) async {
    await tester.tap(
      find.descendant(
        of: kachel(h),
        matching: find.byIcon(Icons.add_alarm_outlined),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Der Dialog', () {
    testWidgets('eine eingetippte Belohnung landet im Stand', (tester) async {
      final c = container(laufen());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, habit);

      await tester.enterText(find.byKey(cueTreatFieldKey), 'Kaffee');
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.treatFor(habit.id), 'Kaffee');
      // Der Auslöser bleibt, was er war: keiner.
      expect(tracker.cueFor(habit.id), isNull);
      expect(tracker.treatFor(andere.id), isNull);
    });

    testWidgets('ein Vorschlag füllt das Feld', (tester) async {
      final c = container(laufen());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, habit);

      final vorschlag = find.widgetWithText(ActionChip, treatSuggestions.first);
      await tester.ensureVisible(vorschlag);
      await tester.tap(vorschlag);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      expect(
        c.read(habitTrackerProvider).treatFor(habit.id),
        treatSuggestions.first,
      );
    });

    testWidgets('sie steht beim nächsten Öffnen wieder da und lässt sich '
        'leeren', (tester) async {
      final c = container(laufen().setTreat(habit.id, 'Kaffee'));
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, habit);

      expect(
        tester.widget<TextField>(find.byKey(cueTreatFieldKey)).controller!.text,
        'Kaffee',
      );

      await tester.enterText(find.byKey(cueTreatFieldKey), '');
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).treatFor(habit.id), isNull);
    });

    testWidgets('neben einem Anker bleibt sie stehen', (tester) async {
      final c = container(laufen());
      await zeige(tester, c, const HabitsScreen());
      await oeffneDialog(tester, habit);

      await tester.tap(find.byKey(cueAnchorKey(andere.id)));
      await tester.pump();
      await tester.enterText(find.byKey(cueTreatFieldKey), 'Kaffee');
      await tester.tap(find.widgetWithText(FilledButton, 'Festlegen'));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      // Die Belohnung eintippen darf die Kopplung nicht lösen — das tut
      // nur, wer einen Auslöser tippt.
      expect(tracker.anchorFor(habit.id), andere.id);
      expect(tracker.treatFor(habit.id), 'Kaffee');
    });
  });

  group('Vor dem Häkchen', () {
    testWidgets('die Kachel zeigt die Belohnung, solange sie offen ist', (
      tester,
    ) async {
      final c = container(laufen().setTreat(habit.id, 'Kaffee'));
      await zeige(tester, c, const HabitsScreen());

      expect(
        find.descendant(of: kachel(habit), matching: find.text('Kaffee')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: kachel(andere), matching: find.byType(TreatLine)),
        findsNothing,
      );
    });

    testWidgets('erledigt fällt sie von der Kachel', (tester) async {
      final c = container(
        laufen().setTreat(habit.id, 'Kaffee').check(habit.id, heute).tracker,
      );
      await zeige(tester, c, const HabitsScreen());

      expect(
        find.descendant(of: kachel(habit), matching: find.byType(TreatLine)),
        findsNothing,
      );
    });

    testWidgets('die Startseite zeigt sie auch', (tester) async {
      final c = container(laufen().setTreat(habit.id, 'Kaffee'));
      await zeige(tester, c, const HomeScreen());

      expect(
        find.descendant(
          of: find.byType(TodayCard),
          matching: find.text('Kaffee'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Beim Abhaken', () {
    testWidgets('steht „Jetzt: …“ da', (tester) async {
      final c = container(laufen().setTreat(habit.id, 'Kaffee'));
      await zeige(tester, c, const HabitsScreen());

      await tester.tap(find.text(habit.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(c.read(habitTrackerProvider).isChecked(habit.id, heute), isTrue);
      expect(find.text('Jetzt: Kaffee'), findsOneWidget);
    });

    testWidgets('ohne Belohnung steht nichts davon da', (tester) async {
      final c = container(laufen().setTreat(habit.id, 'Kaffee'));
      await zeige(tester, c, const HabitsScreen());

      await tester.tap(find.text(andere.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(c.read(habitTrackerProvider).isChecked(andere.id, heute), isTrue);
      expect(find.textContaining('Jetzt:'), findsNothing);
    });

    testWidgets('das Häkchen zurücknehmen verspricht nichts', (tester) async {
      final c = container(
        laufen().setTreat(habit.id, 'Kaffee').check(habit.id, heute).tracker,
      );
      await zeige(tester, c, const HabitsScreen());

      await tester.tap(find.text(habit.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(c.read(habitTrackerProvider).isChecked(habit.id, heute), isFalse);
      expect(find.textContaining('Jetzt:'), findsNothing);
    });
  });
}

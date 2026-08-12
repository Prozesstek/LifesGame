import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

const Day _heute = Day(2026, 8, 12);

/// Ein Container mit festem „heute", damit Streak-Anzeigen nicht vom
/// Systemdatum abhängen.
ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Spielt Lektionen des Wurzelzweigs durch, damit Vorlagen offen sind.
void _passRootBranch(ProviderContainer container) {
  final controller = container.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    controller.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HabitsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  group('HabitsScreen', () {
    testWidgets('ohne Fortschritt weist der Bildschirm zum Skillbaum', (
      tester,
    ) async {
      final container = _container();
      await _pumpScreen(tester, container);

      expect(find.text('Noch keine Gewohnheit freigeschaltet'), findsOneWidget);
      expect(find.text('Zum Skillbaum'), findsOneWidget);
    });

    testWidgets('bestandene Lektionen bringen ihre Vorlagen mit', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      final erwartet = habitsBranch.lessons
          .map((l) => l.unlocksHabit)
          .whereType<String>();

      expect(erwartet, isNotEmpty);
      for (final name in erwartet) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });

    testWidgets('eine Vorlage lässt sich starten und abhaken', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.activeIds, hasLength(1));

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();

      final habitId = tracker.activeIds.first;
      expect(
        container.read(habitTrackerProvider).isChecked(habitId, _heute),
        isTrue,
      );
    });

    testWidgets('ein Häkchen zahlt sofort auf Erfahrung und Gold ein', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      final xpVorher = container.read(totalXpProvider);
      final goldVorher = container.read(goldProvider);

      await _pumpScreen(tester, container);
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();

      expect(
        container.read(totalXpProvider),
        xpVorher + HabitRewards.xpPerCheck,
      );
      expect(
        container.read(goldProvider),
        goldVorher + HabitRewards.goldPerCheck,
      );
    });

    testWidgets('das Häkchen lässt sich zurücknehmen', (tester) async {
      final container = _container();
      _passRootBranch(container);
      final xpVorher = container.read(totalXpProvider);

      await _pumpScreen(tester, container);
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pump();

      expect(container.read(totalXpProvider), xpVorher);
    });

    testWidgets('die Charakterwerte stehen über der Liste', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      for (final stat in HabitStat.values) {
        expect(find.text(stat.label), findsWidgets, reason: stat.label);
      }

      const frisch = CharacterStats.fresh();
      expect(find.text('${frisch.attack}'), findsWidgets);
    });

    testWidgets('mehr als die Obergrenze lässt sich nicht starten', (
      tester,
    ) async {
      final container = _container();

      // Alles freischalten, damit genug Vorlagen zur Auswahl stehen.
      final controller = container.read(theoryProgressProvider.notifier);
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          controller.submit(
            lesson,
            lesson.questions.map<int?>((q) => q.correctIndex).toList(),
          );
        }
      }

      await _pumpScreen(tester, container);

      for (var i = 0; i < HabitRewards.maxActiveHabits; i++) {
        await tester.tap(find.byIcon(Icons.add_circle_outline).first);
        await tester.pump();
      }

      expect(
        container.read(habitTrackerProvider).activeIds,
        hasLength(HabitRewards.maxActiveHabits),
      );

      // Die verbleibenden Knöpfe sind abgeschaltet, nicht verschwunden —
      // die Grenze soll sichtbar sein.
      final buttons = tester.widgetList<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.add_circle_outline),
          matching: find.byType(IconButton),
        ),
      );
      expect(buttons, isNotEmpty);
      expect(buttons.every((b) => b.onPressed == null), isTrue);
    });
  });
}

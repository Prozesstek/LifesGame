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

  /// Eigene Gewohnheiten (ADR-0028).
  ///
  /// Der Weg, den kein Package allein prüfen kann: Formular ausfüllen →
  /// angelegt → steht auf der Tagesliste → zahlt auf einen Wert ein. Er
  /// geht über drei Schichten, und genau solche Wege sind es, die in
  /// `gotchas.md` stehen, weil beide Enden für sich geprüft waren.
  group('Eigene Gewohnheiten', () {
    /// Füllt das Formular aus und legt an.
    Future<void> anlegen(
      WidgetTester tester, {
      String name = 'Zehn Liegestütze',
      String? menge,
    }) async {
      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Was tust du?'),
        name,
      );
      await tester.pump();

      if (menge != null) {
        await tester.tap(find.text('Menge'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Wie viele?'),
          menge,
        );
        await tester.pump();
      }

      await tester.tap(find.widgetWithText(FilledButton, 'Anlegen'));
      await tester.pumpAndSettle();
    }

    testWidgets('ohne freigeschaltete Vorlage gibt es keinen Platz', (
      tester,
    ) async {
      final container = _container();
      await _pumpScreen(tester, container);

      // Der leere Bildschirm nennt es ausdrücklich mit: Eine Vorlage
      // bringt beides mit, den Eintrag und den Platz.
      expect(container.read(customSlotsProvider), 0);
      expect(find.byIcon(Icons.playlist_add), findsNothing);
    });

    testWidgets('jede freigeschaltete Vorlage gibt einen Platz', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      final vorlagen = container.read(unlockedHabitsProvider).length;
      expect(vorlagen, greaterThan(0));
      expect(container.read(customSlotsProvider), vorlagen);
      expect(container.read(customSlotsLeftProvider), vorlagen);
    });

    testWidgets('anlegen setzt sie sofort auf die Tagesliste', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await anlegen(tester);

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.customHabits, hasLength(1));

      final habit = tracker.customHabits.single;
      expect(habit.name, 'Zehn Liegestütze');
      expect(tracker.isActive(habit.id), isTrue);
      expect(
        container.read(customSlotsLeftProvider),
        lessThan(container.read(customSlotsProvider)),
      );
    });

    testWidgets('sie lässt sich abhaken und zahlt auf ihren Wert ein', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      await anlegen(tester);

      final habit = container.read(habitTrackerProvider).customHabits.single;
      final xpVorher = container.read(totalXpProvider);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.isChecked(habit.id, _heute), isTrue);
      expect(
        container.read(totalXpProvider),
        xpVorher + HabitRewards.xpFor(1, habit.difficulty),
      );
      expect(container.read(characterStatsProvider).checksFor(habit.stat), 1);
    });

    testWidgets('ein Tagesziel füllt sich schrittweise', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);
      await anlegen(tester, name: 'Wasser trinken', menge: '3');

      final habit = container.read(habitTrackerProvider).customHabits.single;
      expect(habit.goal?.target, 3);

      // Das Plus auf der Kachel — nicht der Knopf, der eine Vorlage
      // startet: Die laufende Gewohnheit steht oben, die Vorlagen unten.
      expect(find.text('0 / 3 Mal'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();

      expect(
        container.read(habitTrackerProvider).progressOn(habit.id, _heute),
        1,
      );
      expect(
        container.read(habitTrackerProvider).isChecked(habit.id, _heute),
        isFalse,
        reason: 'halb getan ist nicht getan',
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();

      expect(
        container.read(habitTrackerProvider).isChecked(habit.id, _heute),
        isTrue,
      );
    });

    testWidgets('ohne Namen lässt sich nichts anlegen', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pumpAndSettle();

      final knopf = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Anlegen'),
      );
      expect(knopf.onPressed, isNull);
    });

    testWidgets('ist kein Platz frei, nennt der Knopf den Weg', (tester) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      // Alle Plätze belegen. Mehr als die Tagesliste fasst, ist Absicht:
      // Anlegen und Verfolgen sind zwei verschiedene Grenzen.
      final controller = container.read(habitTrackerProvider.notifier);
      final slots = container.read(customSlotsProvider);
      for (var i = 0; i < slots; i++) {
        controller.addCustom(
          name: 'Eigene $i',
          stat: HabitStat.staerke,
          difficulty: HabitDifficulty.mittel,
        );
      }
      await tester.pump();

      expect(container.read(customSlotsLeftProvider), 0);
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      expect(find.textContaining('Kein Platz frei'), findsOneWidget);
    });

    testWidgets('mehr als die Plätze hergeben, kommt nicht hinzu', (
      tester,
    ) async {
      final container = _container();
      _passRootBranch(container);
      await _pumpScreen(tester, container);

      final controller = container.read(habitTrackerProvider.notifier);
      final slots = container.read(customSlotsProvider);
      for (var i = 0; i < slots + 3; i++) {
        controller.addCustom(
          name: 'Eigene $i',
          stat: HabitStat.klarheit,
          difficulty: HabitDifficulty.mittel,
        );
      }

      expect(
        container.read(habitTrackerProvider).customHabits,
        hasLength(slots),
      );
    });
  });
}

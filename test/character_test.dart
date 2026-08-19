import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Prüft Name und Titel auf dem Charakterbildschirm.
///
/// Der interessante Teil ist nicht die Eingabe, sondern die Bedingung: Ein
/// Titel darf nur wählbar sein, wenn er verdient ist (ADR-0013). Das lässt
/// sich nur hier prüfen, weil erst hier Gewohnheiten, Theorie und Titel
/// zusammenkommen.
void main() {
  const habitId = 'habit-drei-aufgaben';
  const tag = Day(2026, 8, 17);

  /// Ein Stand mit [tage] Tagen ununterbrochener Kette.
  SaveData mitStreak(int tage) {
    var tracker = const HabitTracker.empty().activate(habitId);
    var day = tag;
    for (var i = 0; i < tage; i++) {
      tracker = tracker.check(habitId, day).tracker;
      day = day.next;
    }
    return SaveData(habits: tracker);
  }

  Widget appMit(SaveData saved) {
    return ProviderScope(
      overrides: [
        savedGameProvider.overrideWithValue(saved),
        todayProvider.overrideWithValue(tag),
      ],
      child: const MaterialApp(home: CharacterScreen()),
    );
  }

  group('Der Name', () {
    testWidgets('ohne Eingabe steht der Platzhalter', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      expect(find.text('Namenlos'), findsOneWidget);
      expect(find.text('Name geben'), findsOneWidget);
    });

    testWidgets('eingeben und der Bildschirm zeigt ihn', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Name geben'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Frederik');
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      expect(find.text('Frederik'), findsOneWidget);
      expect(find.text('Namenlos'), findsNothing);
      // Aus „Name geben" wird „Name ändern", sobald einer da ist.
      expect(find.text('Name ändern'), findsOneWidget);
    });

    testWidgets('Abbrechen ändert nichts', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Name geben'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Wirdverworfen');
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.text('Namenlos'), findsOneWidget);
      expect(find.text('Wirdverworfen'), findsNothing);
    });
  });

  group('Der Titel', () {
    testWidgets('ein frischer Charakter hat keinen verdient', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();

      // Gesperrte Titel bleiben sichtbar und nennen ihre Bedingung.
      expect(find.text('der Entschlossene'), findsOneWidget);
      expect(find.textContaining('3 Tage am Stück — noch 3'), findsOneWidget);
    });

    testWidgets('ein gesperrter Titel lässt sich nicht wählen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(const SaveData.empty()));

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();

      // Der Dialog steht noch, es wurde nichts gewählt.
      expect(find.text('Titel wählen'), findsOneWidget);
    });

    testWidgets('ein verdienter Titel steht neben dem Namen', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      await tester.tap(find.text('Name geben'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Brett');
      await tester.tap(find.text('Übernehmen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();

      expect(find.text('Brett'), findsOneWidget);
      expect(find.textContaining('der Entschlossene'), findsOneWidget);
    });

    testWidgets('Titel wieder ablegen geht', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(appMit(mitStreak(3)));

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('der Entschlossene'));
      await tester.pumpAndSettle();
      expect(find.textContaining('der Entschlossene'), findsOneWidget);

      await tester.tap(find.text('Titel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kein Titel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('der Entschlossene'), findsNothing);
    });
  });

  group('Verdient bleibt verdient', () {
    test('eine gerissene Kette nimmt den Titel nicht weg', () {
      // Fünf Tage Kette, dann eine Woche Pause. Die laufende Streak ist 0,
      // der Titel bleibt trotzdem tragbar -- das ist der Grund, warum
      // titleStatsProvider longestStreak hereinreicht (konzept.md 3.7).
      final container = ProviderContainer(
        overrides: [
          savedGameProvider.overrideWithValue(mitStreak(5)),
          todayProvider.overrideWithValue(tag.next.next.next.next.next.next),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(titleStatsProvider);
      final earned = container.read(earnedTitlesProvider);

      expect(
        container
            .read(habitTrackerProvider)
            .currentStreak(habitId, tag.next.next.next.next.next.next),
        0,
      );
      expect(stats.longestStreak, 5);
      expect(earned.map((t) => t.id), contains('entschlossen'));
    });
  });
}

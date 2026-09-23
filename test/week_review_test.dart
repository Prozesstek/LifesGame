import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/week_review_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Der Wochenrückblick: wann er sich meldet und was er zeigt.
const Day _montag = Day(2026, 9, 21);
const Day _mittwoch = Day(2026, 9, 23);
const Day _sonntag = Day(2026, 9, 27);

/// Eine Stärke-Gewohnheit, abgehakt an [tage].
ProviderContainer _container(Day heute, List<Day> tage) {
  final c = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(heute)],
  );
  addTearDown(c.dispose);
  final theorie = c.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }
  final controller = c.read(habitTrackerProvider.notifier);
  final id = controller
      .addCustom(
        name: 'Liegestütze',
        stat: HabitStat.staerke,
        difficulty: HabitDifficulty.mittel,
      )!
      .id;
  for (final tag in tage) {
    controller.toggle(id, tag);
  }
  return c;
}

Future<void> _pump(WidgetTester tester, ProviderContainer c, Widget home) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: home),
    ),
  );
}

void main() {
  group('Wann er sich meldet', () {
    testWidgets('unter der Woche als eine Zeile', (tester) async {
      useTallView(tester);
      await _pump(
        tester,
        _container(_mittwoch, <Day>[_montag, _mittwoch]),
        const HabitsScreen(),
      );
      await tester.pump();

      expect(find.text('Diese Woche: 2 / 7 Tage · Rückblick'), findsOneWidget);
    });

    testWidgets('sonntags gross', (tester) async {
      useTallView(tester);
      await _pump(
        tester,
        _container(_sonntag, <Day>[_montag]),
        const HabitsScreen(),
      );
      await tester.pump();

      expect(find.text('Deine Woche'), findsOneWidget);
    });

    testWidgets('montags mit der Woche, die gerade zu Ende ging', (
      tester,
    ) async {
      useTallView(tester);
      final naechsterMontag = _sonntag.next;
      await _pump(
        tester,
        _container(naechsterMontag, <Day>[_montag, _mittwoch]),
        const HabitsScreen(),
      );
      await tester.pump();

      expect(find.text('Deine letzte Woche'), findsOneWidget);
      await tester.tap(find.text('Deine letzte Woche'));
      await tester.pumpAndSettle();

      expect(find.byType(WeekReviewScreen), findsOneWidget);
      expect(find.text('2 von 7 Tagen'), findsOneWidget);
    });
  });

  group('Was er zeigt', () {
    testWidgets('Tage, Zahlen, gewonnene Punkte, Vergleich — auf dem Handy', (
      tester,
    ) async {
      usePhoneView(tester);
      // Vier Häkchen in der Vorwoche, drei in dieser: Das fünfte fällt am
      // Montag und bringt einen Punkt Stärke.
      final vorwoche = <Day>[_montag.previous];
      var tag = _montag.previous;
      for (var i = 0; i < 3; i++) {
        tag = tag.previous;
        vorwoche.add(tag);
      }
      final diese = <Day>[_montag, _montag.next, _mittwoch];
      final c = _container(_mittwoch, <Day>[...vorwoche, ...diese]);
      final woche = c.read(thisWeekProvider);

      await _pump(tester, c, const WeekReviewScreen(anyDayOfWeek: _mittwoch));
      await tester.pumpAndSettle();

      expect(find.text('3 von 7 Tagen'), findsOneWidget);
      expect(find.text('${woche.checks}'), findsOneWidget);
      expect(find.text('${woche.xp}'), findsOneWidget);
      expect(find.text('+1 Stärke'), findsOneWidget);
      expect(find.text('Ein solides Stück Weg.'), findsOneWidget);
      // Die Vorwoche hatte vier Tage, diese bis Mittwoch drei. Die Woche
      // läuft noch, also kein Urteil, nur der Stand.
      expect(find.textContaining('Letzte Woche waren es'), findsOneWidget);
    });

    testWidgets('eine leere Woche sagt, wie man anfängt', (tester) async {
      usePhoneView(tester);
      final c = _container(_mittwoch, const <Day>[]);
      await _pump(tester, c, const WeekReviewScreen(anyDayOfWeek: _mittwoch));
      await tester.pumpAndSettle();

      expect(find.text('0 von 7 Tagen'), findsOneWidget);
      expect(
        find.text('Noch leer — ein Häkchen reicht für den Anfang.'),
        findsOneWidget,
      );
    });
  });
}

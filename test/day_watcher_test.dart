import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/day_watcher.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Ziel 4 aus `docs/context/ziele.md`: Die App übersteht Mitternacht.
///
/// Wer dreißig Tage täglich spielt, lässt die App garantiert einmal über
/// Mitternacht offen. Ein Häkchen auf dem gestrigen Tag reißt dann eine
/// Streak ohne Grund — und das ist in diesem Spiel der schlimmste denkbare
/// Fehler (`konzept.md` 3.7).
void main() {
  group('DayWatcher.nextCheckAfter', () {
    test('mitten am Tag wird nach einer Minute wieder nachgesehen', () {
      expect(
        DayWatcher.nextCheckAfter(DateTime(2026, 9, 20, 12)),
        DayWatcher.checkInterval,
      );
    });

    test('kurz vor Mitternacht wird genau um Mitternacht nachgesehen', () {
      expect(
        DayWatcher.nextCheckAfter(DateTime(2026, 9, 20, 23, 59, 30)),
        const Duration(seconds: 30),
      );
    });

    test('um Punkt Mitternacht beginnt wieder der Minutentakt', () {
      expect(
        DayWatcher.nextCheckAfter(DateTime(2026, 9, 21)),
        DayWatcher.checkInterval,
      );
    });
  });

  group('DayWatcher', () {
    testWidgets('um Mitternacht zieht die Tagesliste ohne Neustart nach', (
      tester,
    ) async {
      final uhr = _Uhr(DateTime(2026, 9, 20, 23, 59, 30));
      final container = _container(uhr);
      final habitId = _eineGewohnheitLaeuft(container);
      container
          .read(habitTrackerProvider.notifier)
          .toggle(habitId, const Day(2026, 9, 20));

      await _pumpScreen(tester, container);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      uhr.jetzt = DateTime(2026, 9, 21, 0, 0, 1);
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();

      expect(container.read(todayProvider), const Day(2026, 9, 21));
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();

      final tracker = container.read(habitTrackerProvider);
      expect(tracker.isChecked(habitId, const Day(2026, 9, 21)), isTrue);
      expect(
        tracker.isChecked(habitId, const Day(2026, 9, 20)),
        isTrue,
        reason: 'Das Häkchen von gestern bleibt, wo es war.',
      );
      expect(tracker.currentStreak(habitId, const Day(2026, 9, 21)), 2);
    });

    testWidgets(
      'wer die App am Morgen hervorholt, sieht sofort den neuen Tag',
      (tester) async {
        final uhr = _Uhr(DateTime(2026, 9, 20, 22));
        final container = _container(uhr);
        _eineGewohnheitLaeuft(container);

        await _pumpScreen(tester, container);
        expect(container.read(todayProvider), const Day(2026, 9, 20));

        // Das Handy lag über Nacht. Ein Wecker, der nach der Laufzeit der
        // App zählt, hat dabei nicht zwingend geklingelt — deshalb vergeht
        // hier bewusst **keine** Zeit im Test.
        uhr.jetzt = DateTime(2026, 9, 21, 7, 30);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();

        expect(container.read(todayProvider), const Day(2026, 9, 21));
      },
    );

    testWidgets('wird die Uhr umgestellt, zieht der Tag binnen einer Minute '
        'nach', (tester) async {
      final uhr = _Uhr(DateTime(2026, 9, 20, 15));
      final container = _container(uhr);
      _eineGewohnheitLaeuft(container);

      await _pumpScreen(tester, container);

      // Zeitzone gewechselt oder Uhr von Hand gestellt: Ein einzelner
      // Wecker auf Mitternacht wäre dafür nie aufgewacht.
      uhr.jetzt = DateTime(2026, 9, 21, 9);
      await tester.pump(DayWatcher.checkInterval);
      await tester.pump();

      expect(container.read(todayProvider), const Day(2026, 9, 21));
    });
  });
}

/// Eine Uhr, die der Test stellt.
class _Uhr {
  _Uhr(this.jetzt);

  DateTime jetzt;
}

ProviderContainer _container(_Uhr uhr) {
  final container = ProviderContainer(
    overrides: [clockProvider.overrideWithValue(() => uhr.jetzt)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Schaltet über das Handbuch Vorlagen frei und startet die erste.
String _eineGewohnheitLaeuft(ProviderContainer container) {
  final theorie = container.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    theorie.submit(
      lesson,
      lesson.questions.map<int?>((q) => q.correctIndex).toList(),
    );
  }

  final habitId = container.read(unlockedHabitsProvider).first.id;
  container.read(habitTrackerProvider.notifier).activate(habitId);
  return habitId;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const DayWatcher(child: MaterialApp(home: HabitsScreen())),
    ),
  );
  await tester.pump();
}

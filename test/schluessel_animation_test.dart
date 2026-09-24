import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/combat/widgets/loot_reveal.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/gear/gear_icon.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/lesson_result_view.dart';
import 'package:lifes_game/ui/pixel_art.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Die Schlüssel bekommen Bewegung (ADR-0048): Die Beute geht mit einem
/// Schlüssel auf, und wer einen verdient, sieht ihn aufsteigen.
const Day _heute = Day(2026, 9, 24);

/// Fünf bestandene Seiten sind fünf Schlüssel; dazu [haekchen] Häkchen
/// an den Tagen davor auf einer eigenen Gewohnheit.
ProviderContainer _container({required int haekchen}) {
  final c = ProviderContainer(
    overrides: [todayProvider.overrideWithValue(_heute)],
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
  var tag = _heute;
  for (var i = 0; i < haekchen; i++) {
    tag = tag.previous;
    controller.toggle(id, tag);
  }
  return c;
}

Future<void> _pumpHabits(WidgetTester tester, ProviderContainer c) async {
  useTallView(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: HabitsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  group('Ein Schlüssel steigt auf', () {
    testWidgets('beim Häkchen, samt Bild', (tester) async {
      final c = _container(haekchen: 3);
      expect(c.read(availableKeysProvider), lessThan(GearKeys.cap));
      await _pumpHabits(tester, c);

      await tester.tap(find.text('Liegestütze'));
      await tester.pump();

      expect(find.textContaining('+1 Schlüssel'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is PixelArt && w.assetPath == GearIcons.schluessel,
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('+1 Schlüssel'), findsNothing);
    });

    testWidgets('nicht, wenn der Vorrat schon voll ist', (tester) async {
      // Bei zehn verfällt der neue — „+1" wäre gelogen.
      final c = _container(haekchen: 12);
      expect(c.read(availableKeysProvider), GearKeys.cap);
      await _pumpHabits(tester, c);

      await tester.tap(find.text('Liegestütze'));
      await tester.pump();

      expect(find.textContaining('+1 Schlüssel'), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  group('Eine bestandene Seite', () {
    testWidgets('zeigt den Schlüssel, wenn es einen gab', (tester) async {
      final lesson = habitsBranch.lessons.first;
      final result = const TheoryProgress.empty().submit(
        lesson,
        lesson.questions.map<int?>((q) => q.correctIndex).toList(),
      );
      Future<void> zeige({required bool schluessel}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LessonResultView(
                lesson: lesson,
                result: result,
                onRetry: () {},
                onDone: () {},
                keyGained: schluessel,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await zeige(schluessel: true);
      expect(find.text('+1 Schlüssel für die Beute'), findsOneWidget);
      await zeige(schluessel: false);
      expect(find.text('+1 Schlüssel für die Beute'), findsNothing);
    });
  });

  group('Die Truhe geht auf', () {
    Future<int> spiele(
      WidgetTester tester, {
      required bool mitSchluessel,
    }) async {
      var geplatzt = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LootReveal(
                withKey: mitSchluessel,
                glow: Colors.purple,
                onBurst: () => geplatzt++,
                item: const Text('Stück'),
                details: const Text('Werte'),
              ),
            ),
          ),
        ),
      );
      return geplatzt;
    }

    Finder schluessel() => find.byWidgetPredicate(
      (w) => w is PixelArt && w.assetPath == GearIcons.schluessel,
    );

    testWidgets('mit Schlüssel: erst der Schlüssel, dann das Stück', (
      tester,
    ) async {
      var geplatzt = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LootReveal(
                glow: Colors.purple,
                onBurst: () => geplatzt++,
                item: const Text('Stück'),
                details: const Text('Werte'),
              ),
            ),
          ),
        ),
      );
      expect(schluessel(), findsOneWidget);
      expect(find.text('Stück'), findsNothing);
      expect(geplatzt, 0);

      await tester.pumpAndSettle();

      // Einmal aufgeplatzt, der Schlüssel ist weg, das Stück da, die
      // Werte voll zu sehen — und die Animation steht.
      expect(geplatzt, 1);
      expect(schluessel(), findsNothing);
      expect(find.text('Stück'), findsOneWidget);
      final werte = tester.widget<Opacity>(
        find.ancestor(of: find.text('Werte'), matching: find.byType(Opacity)),
      );
      expect(werte.opacity, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('ohne Schlüssel springt sie gleich auf', (tester) async {
      await spiele(tester, mitSchluessel: false);
      expect(schluessel(), findsNothing);
      await tester.pump(LootReveal.withoutKeyDuration ~/ 2);
      expect(find.text('Stück'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}

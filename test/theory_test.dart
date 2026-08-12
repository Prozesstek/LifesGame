import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/branch_screen.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/branch_card.dart';
import 'package:lifes_game/theory/widgets/lesson_tile.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

final Lesson _first = habitsBranch.lessons.first;

/// Ein Container, in dem der Spieler auf [level] steht.
///
/// Das Level ergibt sich sonst aus der gesammelten Erfahrung; für die
/// Anzeige-Tests wird es direkt gesetzt, damit nicht erst ein halber Baum
/// durchgespielt werden muss.
ProviderContainer _containerAtLevel(int level) {
  return ProviderContainer(
    overrides: [
      playerLevelProvider.overrideWithValue(
        LevelCurve.levelFor(LevelCurve.totalXpFor(level)),
      ),
    ],
  );
}

void main() {
  group('TheoryController', () {
    test('startet ohne Fortschritt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final progress = container.read(theoryProgressProvider);
      expect(progress.totalXp, 0);
      expect(progress.passedCountIn(theoryTree), 0);
    });

    test('ein bestandener Versuch landet im Fortschritt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final answers = _first.questions.map((q) => q.correctIndex).toList();
      final result = container
          .read(theoryProgressProvider.notifier)
          .submit(_first, answers);

      expect(result.isPassed, isTrue);
      expect(
        container.read(theoryProgressProvider).isPassed(_first.id),
        isTrue,
      );
      expect(container.read(theoryProgressProvider).totalXp, result.xpGained);
    });
  });

  group('SkillTreeScreen', () {
    Future<void> pump(WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SkillTreeScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('zeigt alle Zweige, auch die gesperrten', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      for (final branch in theoryTree.branches) {
        expect(find.text(branch.name), findsOneWidget, reason: branch.id);
      }
      expect(
        tester.widgetList<BranchCard>(find.byType(BranchCard)).length,
        theoryTree.branchCount,
      );
    });

    testWidgets('auf Level 1 ist nur der Wurzelzweig offen', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      final cards = tester.widgetList<BranchCard>(find.byType(BranchCard));
      final open = cards.where((c) => c.isUnlocked).toList();

      expect(open.length, 1);
      expect(open.first.branch.id, habitsBranch.id);
    });

    testWidgets('gesperrte Zweige nennen ihre Stufe', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      expect(
        find.text('ab Level ${koerperBranch.unlockLevel}'),
        findsOneWidget,
      );
      expect(
        find.text('ab Level ${gesellschaftBranch.unlockLevel}'),
        findsOneWidget,
      );
    });

    testWidgets('der nächste Zweig wird als Ziel genannt', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      expect(
        find.text(
          '„${koerperBranch.name}" öffnet sich auf Level '
          '${koerperBranch.unlockLevel}.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('ab Level 2 ist Körper offen', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(2);
      addTearDown(container.dispose);

      await pump(tester, container);

      final cards = tester.widgetList<BranchCard>(find.byType(BranchCard));
      final koerper = cards.firstWhere((c) => c.branch.id == 'koerper');

      expect(koerper.isUnlocked, isTrue);
      expect(
        cards.firstWhere((c) => c.branch.id == 'geist').isUnlocked,
        isFalse,
      );
    });

    testWidgets('auf hohem Level ist der ganze Baum offen', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(9);
      addTearDown(container.dispose);

      await pump(tester, container);

      final cards = tester.widgetList<BranchCard>(find.byType(BranchCard));
      expect(cards.every((c) => c.isUnlocked), isTrue);
    });

    testWidgets('ein gesperrter Zweig lässt sich nicht öffnen', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      await tester.tap(find.text(koerperBranch.name));
      await tester.pumpAndSettle();

      expect(find.byType(BranchScreen), findsNothing);
      expect(find.byType(SkillTreeScreen), findsOneWidget);
    });

    testWidgets('ein offener Zweig führt zur Lektionsliste', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(2);
      addTearDown(container.dispose);

      await pump(tester, container);

      await tester.tap(find.text(koerperBranch.name));
      await tester.pumpAndSettle();

      expect(find.byType(BranchScreen), findsOneWidget);
      expect(find.text(koerperBranch.lessons.first.title), findsOneWidget);
    });
  });

  group('BranchScreen', () {
    Future<void> pump(WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BranchScreen(branch: habitsBranch)),
        ),
      );
      await tester.pump();
    }

    testWidgets('nur die erste Lektion ist zu Beginn offen', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);

      final tiles = tester.widgetList<LessonTile>(find.byType(LessonTile));
      expect(tiles.length, habitsBranch.lessonCount);
      expect(tiles.where((t) => t.isUnlocked).length, 1);
      expect(tiles.first.isUnlocked, isTrue);
    });

    testWidgets('nach bestandener Lektion öffnet sich die nächste', (
      tester,
    ) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final answers = _first.questions.map((q) => q.correctIndex).toList();
      container.read(theoryProgressProvider.notifier).submit(_first, answers);

      await pump(tester, container);

      final tiles = tester.widgetList<LessonTile>(find.byType(LessonTile));
      expect(tiles.where((t) => t.isUnlocked).length, 2);
      expect(find.text('1 von 5 Lektionen bestanden'), findsOneWidget);
    });

    testWidgets('freigeschaltete Habit-Vorlage wird angezeigt', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final answers = _first.questions.map((q) => q.correctIndex).toList();
      container.read(theoryProgressProvider.notifier).submit(_first, answers);

      await pump(tester, container);

      expect(find.text(_first.unlocksHabit ?? ''), findsOneWidget);
    });
  });

  group('LessonScreen', () {
    Future<void> pump(WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: LessonScreen(lesson: _first)),
        ),
      );
      await tester.pump();
    }

    /// Beantwortet alle Fragen und geht bis zum Ergebnis durch.
    Future<void> answerAll(
      WidgetTester tester, {
      required bool correctly,
    }) async {
      for (var i = 0; i < _first.questionCount; i++) {
        final question = _first.questions[i];
        final option = correctly
            ? question.correctIndex
            : (question.correctIndex + 1) % question.options.length;

        await tester.tap(find.text(question.options[option]));
        await tester.pumpAndSettle();

        final isLast = i == _first.questionCount - 1;
        await tester.tap(find.text(isLast ? 'Auswerten' : 'Weiter'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('zeigt erst den Text, dann die Fragen', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);

      expect(find.text(_first.sections.first.heading), findsOneWidget);
      expect(find.text('Frage 1 von ${_first.questionCount}'), findsNothing);

      await tester.tap(find.text('${_first.questionCount} Fragen beantworten'));
      await tester.pumpAndSettle();

      expect(find.text('Frage 1 von ${_first.questionCount}'), findsOneWidget);
      expect(find.text(_first.questions.first.prompt), findsOneWidget);
    });

    testWidgets('vor der Antwort geht es nicht weiter', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('${_first.questionCount} Fragen beantworten'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Weiter'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('die Erklärung erscheint nach der Antwort', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('${_first.questionCount} Fragen beantworten'));
      await tester.pumpAndSettle();

      final question = _first.questions.first;
      expect(find.text(question.explanation), findsNothing);

      await tester.tap(find.text(question.options[question.correctIndex]));
      await tester.pumpAndSettle();

      expect(find.text(question.explanation), findsOneWidget);
      expect(find.text('Richtig'), findsOneWidget);
    });

    testWidgets('alles richtig: bestanden, mit Erfahrung und Gold', (
      tester,
    ) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('${_first.questionCount} Fragen beantworten'));
      await tester.pumpAndSettle();
      await answerAll(tester, correctly: true);

      expect(find.text('Bestanden'), findsOneWidget);
      expect(
        find.text(
          '${_first.questionCount} von ${_first.questionCount} Fragen richtig',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '+${TheoryRewards.xpForPass + TheoryRewards.xpPerfectBonus} '
          'Erfahrung',
        ),
        findsOneWidget,
      );
      expect(container.read(theoryProgressProvider).isPassed(_first.id), true);
    });

    testWidgets('alles falsch: durchgefallen, kein Fortschritt', (
      tester,
    ) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('${_first.questionCount} Fragen beantworten'));
      await tester.pumpAndSettle();
      await answerAll(tester, correctly: false);

      expect(find.text('Noch nicht bestanden'), findsOneWidget);
      expect(container.read(theoryProgressProvider).totalXp, 0);
      expect(
        container.read(theoryProgressProvider).isPassed(_first.id),
        isFalse,
      );
    });

    testWidgets('„Nochmal" startet die Fragen von vorn', (tester) async {
      useTallView(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('${_first.questionCount} Fragen beantworten'));
      await tester.pumpAndSettle();
      await answerAll(tester, correctly: false);

      await tester.tap(find.text('Nochmal'));
      await tester.pumpAndSettle();

      expect(find.text('Frage 1 von ${_first.questionCount}'), findsOneWidget);
    });
  });
}

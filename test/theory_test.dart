import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/theory/branch_screen.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/node_bubble.dart';
import 'package:lifes_game/theory/widgets/node_card.dart';
import 'package:lifes_game/theory/widgets/node_sheet.dart';
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

  group('SkillTreeScreen — der Graph (ADR-0019)', () {
    Future<void> pump(WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SkillTreeScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('zeigt das Handbuch und die vier Wurzeln', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      expect(find.text('Das Handbuch'), findsOneWidget);
      for (final rootId in theoryRootIds) {
        final root = theoryGraph.nodeById(rootId);
        expect(find.text(root!.name), findsOneWidget, reason: rootId);
      }
    });

    testWidgets('nennt keine Levelsperre mehr — Punkte statt Stufen', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      expect(find.textContaining('ab Level'), findsNothing);
    });

    testWidgets('auf Level 1 gibt es null Punkte', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      expect(container.read(availableTheoryPointsProvider), 0);

      await pump(tester, container);

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('jeder Aufstieg gibt zwei Punkte', (tester) async {
      final container = _containerAtLevel(4);
      addTearDown(container.dispose);

      expect(container.read(availableTheoryPointsProvider), 6);
    });

    testWidgets('eine Wurzel hat fünf Kinder im Bild', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pump(tester, container);

      final kinder = theoryGraph.childrenOf('koerper');
      expect(kinder.length, 5);
      for (final kind in kinder) {
        expect(find.text(kind.name), findsOneWidget, reason: kind.id);
      }
    });

    testWidgets('eine Wurzel antippen zeigt ihre Einführung', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('Körper'));
      await tester.pumpAndSettle();

      expect(find.byType(NodeSheet), findsOneWidget);
      expect(find.text('Seite lesen'), findsOneWidget);
    });

    testWidgets('das Handbuch führt weiter zur Lektionsliste (ADR-0018)', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text('Das Handbuch'));
      await tester.pumpAndSettle();

      expect(find.byType(BranchScreen), findsOneWidget);
    });
  });

  group('Der gezeichnete Baum — Knoten öffnen', () {
    Future<void> pump(WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SkillTreeScreen()),
        ),
      );
      await tester.pump();
    }

    // Band 1 (Körper) liegt sicher im Sichtbereich; tiefere Bänder
    // erreicht man nur durch Verschieben, was ein Widget-Test nicht
    // sinnvoll nachstellt.
    final schlaf = theoryGraph.nodeById('koerper-schlaf')!;

    testWidgets('alle 24 Knoten werden gezeichnet', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      expect(find.byType(NodeBubble), findsNWidgets(24));
    });

    testWidgets('die Wurzeln sind offen, die Kinder nicht', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      final bubbles = tester.widgetList<NodeBubble>(find.byType(NodeBubble));
      final wurzeln = bubbles.where((b) => b.node.isRoot);

      expect(wurzeln.length, 4);
      expect(wurzeln.every((b) => b.state == NodeState.open), isTrue);
    });

    testWidgets('ohne Punkte ist kein Kind kaufbar', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);

      final bubbles = tester.widgetList<NodeBubble>(find.byType(NodeBubble));
      final kinder = bubbles.where((b) => !b.node.isRoot);

      expect(kinder.every((b) => b.state == NodeState.tooExpensive), isTrue);
    });

    testWidgets('mit Punkten sind die Kinder kaufbar', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(2);
      addTearDown(container.dispose);

      await pump(tester, container);

      final bubbles = tester.widgetList<NodeBubble>(find.byType(NodeBubble));
      final kinder = bubbles.where((b) => !b.node.isRoot);

      expect(kinder.every((b) => b.state == NodeState.affordable), isTrue);
    });

    testWidgets('antippen öffnet das Detailblatt', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(2);
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(find.byType(NodeSheet), findsOneWidget);
      expect(find.text('Für einen Punkt öffnen'), findsOneWidget);
    });

    testWidgets('öffnen zieht den Punkt ab', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(2);
      addTearDown(container.dispose);

      await pump(tester, container);
      expect(container.read(availableTheoryPointsProvider), 2);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Für einen Punkt öffnen'));
      await tester.pumpAndSettle();

      expect(container.read(spentTheoryPointsProvider), 1);
      expect(container.read(availableTheoryPointsProvider), 1);
      expect(
        container
            .read(theoryProgressProvider)
            .isNodeOpened(schlaf.id, theoryGraph),
        isTrue,
      );
    });

    testWidgets('das Blatt schließen kostet nichts', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(2);
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(NodeSheet))).pop();
      await tester.pumpAndSettle();

      expect(container.read(spentTheoryPointsProvider), 0);
    });

    testWidgets('ein zu teurer Knoten nennt den Grund statt eines Knopfes', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pump(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(find.textContaining('Du brauchst einen Punkt'), findsOneWidget);
      expect(find.text('Für einen Punkt öffnen'), findsNothing);
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

    /// Welche Frage gerade dasteht.
    ///
    /// Seit ADR-0027 wird die Reihenfolge beim Anzeigen gemischt — die
    /// Position im Katalog sagt nichts mehr darueber aus, was auf dem
    /// Bildschirm steht. Der Bildschirm ist die einzige Quelle dafuer.
    Question shownQuestion() => _first.questions.firstWhere(
      (q) => find.text(q.prompt).evaluate().isNotEmpty,
    );

    /// Beantwortet alle Fragen und geht bis zum Ergebnis durch.
    ///
    /// Getippt wird ueber den **Text** der Antwort, nicht ueber ihre
    /// Stelle. Damit prueft der Test zugleich die Rueckuebersetzung aus
    /// `ShuffledLesson`: Waere sie falsch, kaeme hier „durchgefallen"
    /// heraus, obwohl richtig getippt wurde.
    Future<void> answerAll(
      WidgetTester tester, {
      required bool correctly,
    }) async {
      for (var i = 0; i < _first.questionCount; i++) {
        final question = shownQuestion();
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

      // Welche der Fragen zuerst kommt, entscheidet der Zufall — dass
      // es genau eine ist, entscheidet er nicht.
      final sichtbar = _first.questions.where(
        (q) => find.text(q.prompt).evaluate().isNotEmpty,
      );
      expect(sichtbar, hasLength(1));
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

      final question = shownQuestion();
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

  group('Zählen über Handbuch und Graph', () {
    // Der Umbau auf den Graphen (ADR-0019) hat zwölf von neunundzwanzig
    // Seiten aus `theoryTree` herausgenommen. Wer weiter nur die Zweige
    // zählt, unterschlägt sie — genau das war nach dem Umbau kurz der
    // Fall, bei den Titeln und auf dem Startbildschirm.
    test('die Gesamtzahl umfasst Handbuch und Graph', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(totalPagesProvider), 29);
      expect(
        container.read(totalPagesProvider),
        greaterThan(theoryTree.lessonCount),
        reason: 'Sonst zählt jemand wieder nur die alten Zweige.',
      );
    });

    test('eine bestandene Knotenseite zählt mit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final knoten = theoryGraph.nodes.firstWhere(
        (n) => !theoryTree.branches.any((b) => b.indexOf(n.lesson.id) >= 0),
      );

      expect(container.read(passedPagesProvider), 0);

      container.read(theoryProgressProvider.notifier).submit(knoten.lesson, [
        for (final q in knoten.lesson.questions) q.correctIndex,
      ]);

      expect(container.read(passedPagesProvider), 1);
    });

    test('sie zählt auch für die Titel', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final knoten = theoryGraph.nodes.firstWhere(
        (n) => !theoryTree.branches.any((b) => b.indexOf(n.lesson.id) >= 0),
      );

      container.read(theoryProgressProvider.notifier).submit(knoten.lesson, [
        for (final q in knoten.lesson.questions) q.correctIndex,
      ]);

      expect(container.read(titleStatsProvider).passedLessons, 1);
    });
  });
}

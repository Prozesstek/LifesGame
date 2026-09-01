import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/character/identity_controller.dart';
import 'package:lifes_game/theory/branch_screen.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/node_action_panel.dart';
import 'package:lifes_game/theory/widgets/node_bubble.dart';
import 'package:lifes_game/theory/widgets/node_state.dart';
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

/// Bringt das Handbuch hinter sich.
///
/// **Ohne das gibt es keinen Baum zu sehen** (ADR-0025): Solange das
/// Handbuch offen ist, *ist* es der Theorie-Bildschirm.
void _passHandbook(ProviderContainer container) {
  final notifier = container.read(theoryProgressProvider.notifier);
  for (final lesson in habitsBranch.lessons) {
    notifier.submit(lesson, <int?>[
      for (final question in lesson.questions) question.correctIndex,
    ]);
  }
}

Future<void> _pumpTree(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SkillTreeScreen()),
    ),
  );
  await tester.pump();
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

  group('SkillTreeScreen — das Handbuch steht davor (ADR-0025)', () {
    testWidgets('solange es offen ist, ist es der Bildschirm', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      // Aus der schmalen Zeile über einem unbenutzbaren Baum ist der
      // Bildschirm selbst geworden.
      expect(find.byType(BranchScreen), findsOneWidget);
      expect(find.byType(NodeBubble), findsNothing);
    });

    testWidgets('danach steht der Baum da', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      expect(find.byType(BranchScreen), findsNothing);
      expect(find.byType(NodeBubble), findsWidgets);
    });

    testWidgets('das Handbuch steht nicht mehr als Zeile über dem Baum', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      expect(find.text('Das Handbuch'), findsNothing);
    });
  });

  group('Der Baum — ein Bildschirm je Gebiet (ADR-0026)', () {
    final kinder = theoryGraph.childrenOf('koerper');

    testWidgets('zeigt ein Gebiet mit seinen fünf Kindern', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      expect(kinder.length, 5);
      expect(find.text('Körper'), findsWidgets);
      for (final kind in kinder) {
        expect(find.text(kind.name), findsOneWidget, reason: kind.id);
      }
    });

    testWidgets('die anderen Gebiete liegen nicht gleichzeitig im Bild', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      // Das ist der ganze Punkt der Entscheidung: nicht vier Bänder auf
      // einer Fläche, sondern eines je Bildschirm.
      final fremd = theoryGraph
          .childrenOf('wissenschaft')
          .where((n) => !n.parentIds.contains('koerper'));

      for (final kind in fremd) {
        expect(find.text(kind.name), findsNothing, reason: kind.id);
      }
    });

    testWidgets('vier Gebiete stehen zum Wischen bereit', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      final pages = tester.widget<PageView>(find.byType(PageView));
      expect(pages.childrenDelegate.estimatedChildCount, theoryRootIds.length);
    });

    testWidgets('der Startknoten sitzt unten, die Kinder darüber', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      final wurzel = tester.getCenter(find.text('Körper').last);
      for (final kind in kinder) {
        expect(
          tester.getCenter(find.text(kind.name)).dy,
          lessThan(wurzel.dy),
          reason: kind.id,
        );
      }
    });

    testWidgets('kein Verschieben und Zoomen mehr', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      // Waagerecht kann nur eine Bedeutung haben — und die gehört dem
      // Gebietswechsel.
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('nennt keine Levelsperre — Punkte statt Stufen', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      expect(find.textContaining('ab Level'), findsNothing);
    });

    testWidgets('die Kopfzeile nennt Gebiets- und Gesamtfortschritt', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);
      _passHandbook(container);

      await _pumpTree(tester, container);

      final gesamt = container.read(totalPagesProvider);
      final bestanden = container.read(passedPagesProvider);

      expect(find.text('0 von 6'), findsOneWidget);
      expect(find.text('gesamt $bestanden von $gesamt'), findsOneWidget);
    });

    testWidgets('jeder Aufstieg gibt zwei Punkte', (tester) async {
      final container = _containerAtLevel(4);
      addTearDown(container.dispose);

      expect(container.read(availableTheoryPointsProvider), 6);
    });
  });

  group('Ein Knoten wird hereingezogen, nicht geöffnet (ADR-0026)', () {
    final schlaf = theoryGraph.nodeById('koerper-schlaf')!;

    Future<void> pumpTree(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      _passHandbook(container);
      await _pumpTree(tester, container);
    }

    testWidgets('die Wurzel ist offen, die Kinder nicht', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final bubbles = tester.widgetList<NodeBubble>(find.byType(NodeBubble));
      final wurzel = bubbles.where((b) => b.node.isRoot);

      expect(wurzel.length, 1);
      expect(wurzel.single.state, NodeState.open);
    });

    testWidgets('ohne Punkte ist kein Kind kaufbar', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final bubbles = tester.widgetList<NodeBubble>(find.byType(NodeBubble));
      final kinder = bubbles.where((b) => !b.node.isRoot);

      expect(kinder, isNotEmpty);
      expect(kinder.every((b) => b.state == NodeState.tooExpensive), isTrue);
    });

    testWidgets('mit Punkten sind die Kinder kaufbar', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final bubbles = tester.widgetList<NodeBubble>(find.byType(NodeBubble));
      final kinder = bubbles.where((b) => !b.node.isRoot);

      expect(kinder, isNotEmpty);
      expect(kinder.every((b) => b.state == NodeState.affordable), isTrue);
    });

    testWidgets('ein Kind antippen kostet noch keinen Punkt', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      final vorher = container.read(availableTheoryPointsProvider);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      // Erkunden darf nichts kosten. Sonst gäbe man beim Umsehen Punkte
      // aus — der Grund, warum Antippen und Öffnen getrennt sind.
      expect(container.read(spentTheoryPointsProvider), 0);
      expect(container.read(availableTheoryPointsProvider), vorher);
    });

    testWidgets('es wandert nach unten und bringt den Öffnen-Knopf mit', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(find.text('Für einen Punkt öffnen'), findsOneWidget);
      expect(
        tester.getCenter(find.text('Für einen Punkt öffnen')).dy,
        lessThan(tester.getCenter(find.text(schlaf.name)).dy),
        reason: 'Der Knopf steht über dem Knoten (ADR-0026, Punkt 4).',
      );
    });

    testWidgets('ein Blatt zeigt eine leere Ebene statt sofort zu öffnen', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      expect(theoryGraph.childrenOf(schlaf.id), isEmpty);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      // Nur noch der Startknoten selbst — über ihm geht es nicht weiter.
      expect(find.byType(NodeBubble), findsOneWidget);
      expect(container.read(spentTheoryPointsProvider), 0);
    });

    testWidgets('der Knopf öffnet und zieht den Punkt ab', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      final vorher = container.read(availableTheoryPointsProvider);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Für einen Punkt öffnen'));
      await tester.pumpAndSettle();

      expect(container.read(spentTheoryPointsProvider), 1);
      expect(container.read(availableTheoryPointsProvider), vorher - 1);
      expect(
        container
            .read(theoryProgressProvider)
            .isNodeOpened(schlaf.id, theoryGraph),
        isTrue,
      );
    });

    testWidgets('ein zweiter Druck auf den Startknoten klappt wieder zu', (
      tester,
    ) async {
      // **Nicht mehr „er öffnet ebenfalls".** ADR-0026 gab dem zweiten
      // Druck das Öffnen — damals stand das Blatt immer offen und die
      // Geste war frei. Seit sie das Blatt auf- und zuklappt, wäre ein
      // Doppeldruck ein verlorener Theoriepunkt.
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();
      expect(find.text('Für einen Punkt öffnen'), findsOneWidget);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(find.text('Für einen Punkt öffnen'), findsNothing);
      expect(container.read(spentTheoryPointsProvider), 0);
    });

    testWidgets('beim Reingehen steht nichts über dem Startknoten', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final wurzel = theoryGraph.nodeById(theoryRootIds.first)!;

      expect(find.byType(NodeActionPanel), findsNothing);
      expect(find.text('Seite lesen'), findsNothing);

      await tester.tap(find.text(wurzel.name).last);
      await tester.pumpAndSettle();

      expect(find.byType(NodeActionPanel), findsOneWidget);
    });

    testWidgets('der Elternknoten führt zurück', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(find.text('Zurück zu Körper'), findsOneWidget);

      await tester.tap(find.text('Zurück zu Körper'));
      await tester.pumpAndSettle();

      // Alle fünf Kinder stehen wieder da.
      for (final kind in theoryGraph.childrenOf('koerper')) {
        expect(find.text(kind.name), findsOneWidget, reason: kind.id);
      }
      expect(find.text('Zurück zu Körper'), findsNothing);
    });

    testWidgets('an der Wurzel gibt es keinen Rückweg im Baum', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      expect(find.textContaining('Zurück zu'), findsNothing);
    });

    testWidgets('ein zu teurer Knoten nennt den Grund statt eines Knopfes', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(find.textContaining('Du brauchst einen Punkt'), findsOneWidget);
      expect(find.text('Für einen Punkt öffnen'), findsNothing);
    });

    testWidgets('ein Knoten verrät nicht, dass er eine Fähigkeit bringt', (
      tester,
    ) async {
      // **Verstecken ist der Punkt** (Issue #21, Punkt 8). Würde die
      // Blase es anzeigen, wäre der Baum eine Einkaufsliste: Man ginge
      // die Fähigkeitsknoten ab und liesse den Rest liegen. Der Inhalt
      // soll der Grund sein, nicht die Belohnung.
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final mitFaehigkeit = theoryGraph
          .childrenOf('koerper')
          .firstWhere((n) => n.unlocksAbility != null);

      await tester.tap(find.text(mitFaehigkeit.name));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fähigkeit'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('eine bestandene Seite bietet keinen Knopf mehr an', (
      tester,
    ) async {
      // **Beim Öffnen eines Gebiets stand hier jedes Mal „Seite noch
      // einmal lesen"** — unter dem Startknoten, den man längst gelesen
      // hat. Ein Knopf verspricht eine Handlung; eine bestandene Seite
      // hat keine offen.
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      _passHandbook(container);
      final wurzel = theoryGraph.nodeById(theoryRootIds.first)!;
      container.read(theoryProgressProvider.notifier).submit(
        wurzel.lesson,
        <int?>[for (final q in wurzel.lesson.questions) q.correctIndex],
      );

      await _pumpTree(tester, container);
      await tester.tap(find.text(wurzel.name).last);
      await tester.pumpAndSettle();

      expect(find.byType(NodeActionPanel), findsOneWidget);
      expect(find.text('Seite noch einmal lesen'), findsNothing);
      expect(find.text('Seite lesen'), findsNothing);
      expect(find.textContaining('Bestanden'), findsOneWidget);
    });

    testWidgets('nachlesen geht weiter — über den Knoten selbst', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      _passHandbook(container);
      final wurzel = theoryGraph.nodeById(theoryRootIds.first)!;
      container.read(theoryProgressProvider.notifier).submit(
        wurzel.lesson,
        <int?>[for (final q in wurzel.lesson.questions) q.correctIndex],
      );

      await _pumpTree(tester, container);
      await tester.tap(find.text(wurzel.name).last);
      await tester.pumpAndSettle();

      // Die Zeile ist selbst der Knopf — sonst gäbe es gar keinen Weg
      // mehr zurück in eine bestandene Seite.
      await tester.tap(find.textContaining('Bestanden'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
    });

    testWidgets('Pfeile wechseln das Gebiet, nicht nur das Wischen', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final zweitesGebiet = theoryGraph.nodeById(theoryRootIds[1])!;
      expect(find.text(zweitesGebiet.name), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(find.text(zweitesGebiet.name), findsWidgets);
    });

    testWidgets('am Rand der Reihe führt der Pfeil nirgendwohin', (
      tester,
    ) async {
      // Er verschwindet nicht, er wird blass. Ein Knopf, der kommt und
      // geht, lässt die Leiste zappeln.
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      final erstes = theoryGraph.nodeById(theoryRootIds.first)!;
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.text(erstes.name), findsWidgets);
    });

    testWidgets('eine offene Wurzel führt zu ihrer Seite', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      await tester.tap(
        find.text(theoryGraph.nodeById(theoryRootIds.first)!.name).last,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seite lesen'));
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/widgets/review_section.dart';
import 'package:lifes_game/achievements/achievements_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/widgets/lesson_result_view.dart';
import 'package:lifes_game/theory/review_controller.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/node_action_panel.dart';
import 'package:lifes_game/theory/widgets/node_bubble.dart';
import 'package:lifes_game/theory/widgets/node_state.dart';
import 'package:lifes_game/theory/widgets/tree_overview.dart';
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

/// Gibt alle Startpunkte bis auf einen aus, auf dem Weg der Grundlagen.
///
/// Seit ADR-0070 beginnt jeder mit neun Punkten. Tests, die „kein Punkt
/// mehr übrig“ brauchen, kaufen danach noch eine Wurzel und stehen bei
/// null.
void _bisAufEinenPunkt(ProviderContainer container) {
  final notifier = container.read(theoryProgressProvider.notifier);
  for (final id in theoryBasicsPath.take(TheoryPoints.atStart - 1)) {
    notifier.openNode(
      id,
      availablePoints: container.read(availableTheoryPointsProvider),
    );
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

  group('SkillTreeScreen — der Baum ist immer offen (ADR-0070)', () {
    testWidgets('ein neuer Stand sieht den Baum, kein Handbuch davor', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      expect(find.byType(NodeBubble), findsWidgets);
      expect(find.text('Das Handbuch'), findsNothing);
    });

    testWidgets('solange nichts gelesen ist, schlägt er den Weg der '
        'Grundlagen vor — mit Preis', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      final vorschlag = tester.widget<ContinueReadingTile>(
        find.byType(ContinueReadingTile),
      );
      expect(vorschlag.node.id, theoryBasicsPath.first);
      expect(vorschlag.cost, 1);
      expect(
        find.bySemanticsLabel(RegExp('Öffnen und lesen: .*kostet 1 Punkt')),
        findsOneWidget,
      );
    });

    testWidgets('ein Tipp darauf öffnet den Knoten und die Seite', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);
      final vorher = container.read(availableTheoryPointsProvider);

      await _pumpTree(tester, container);
      await tester.tap(find.byType(ContinueReadingTile));
      await tester.pumpAndSettle();

      expect(find.byType(LessonScreen), findsOneWidget);
      expect(
        container
            .read(theoryProgressProvider)
            .isNodeOpened(theoryBasicsPath.first, theoryGraph),
        isTrue,
      );
      expect(container.read(availableTheoryPointsProvider), vorher - 1);
    });

    testWidgets('ohne Punkt gibt es keinen Vorschlag', (tester) async {
      useTallView(tester);
      final container = ProviderContainer(
        overrides: [availableTheoryPointsProvider.overrideWithValue(0)],
      );
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      expect(find.byType(ContinueReadingTile), findsNothing);
    });
  });

  group('Der Baum — ein Bildschirm je Gebiet (ADR-0026)', () {
    final kinder = theoryGraph.childrenOf('koerper');

    testWidgets('zeigt ein Gebiet mit allen seinen Überschriften', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      // Vier befüllt, zwei angekündigt (ADR-0050).
      expect(kinder.length, 4);
      expect(find.text('Körper'), findsWidgets);
      for (final kind in kinder) {
        expect(find.text(kind.name), findsOneWidget, reason: kind.id);
      }
      for (final angekuendigt in theoryGraph.placeholdersOf('koerper')) {
        expect(find.text(angekuendigt.title), findsOneWidget);
      }
      expect(find.byType(PlaceholderBubble), findsNWidgets(2));
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsNWidgets(2));
    });

    testWidgets('die anderen Gebiete liegen nicht gleichzeitig im Bild', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

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

      await _pumpTree(tester, container);

      expect(find.textContaining('ab Level'), findsNothing);
    });

    testWidgets('die Kopfzeile nennt Gebiets- und Gesamtfortschritt', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      // Seit die App ohne Lesen auskommen soll: nur noch der Stand des
      // Gebiets, als Bruch. „gesamt … von …“ sagen die vier Balken.
      expect(find.text('0 / 20'), findsWidgets);
    });

    testWidgets('jeder Aufstieg gibt einen Punkt (ADR-0035)', (tester) async {
      final container = _containerAtLevel(4);
      addTearDown(container.dispose);

      // Die Startpunkte und drei Aufstiege (ADR-0070).
      expect(
        container.read(availableTheoryPointsProvider),
        TheoryPoints.atStart + 3,
      );
    });
  });

  group('Ein Knoten wird hereingezogen, nicht geöffnet (ADR-0026)', () {
    // Seit ADR-0050 sind die Kinder einer Wurzel Zwischenebenen.
    final schlaf = theoryGraph.nodeById('schlaf-regeneration')!;
    final schlafThema = theoryGraph.nodeById('koerper-schlaf')!;

    /// Die Wurzel Körper gekauft — seit ADR-0051 kostet sie einen Punkt,
    /// und erst dahinter beginnt das Erkunden.
    Future<void> pumpTree(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      container
          .read(theoryProgressProvider.notifier)
          .openNode(
            theoryRootIds.first,
            availablePoints: container.read(availableTheoryPointsProvider),
          );
      await _pumpTree(tester, container);
    }

    testWidgets('eine ungekaufte Wurzel ist kaufbar, nicht offen', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);

      await _pumpTree(tester, container);

      final wurzel = tester
          .widgetList<NodeBubble>(find.byType(NodeBubble))
          .singleWhere((b) => b.node.isRoot);

      // Der Startpunkt reicht für genau eine Wurzel (ADR-0051).
      expect(wurzel.state, NodeState.affordable);
    });

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
      _bisAufEinenPunkt(container);

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
      expect(container.read(spentTheoryPointsProvider), 1); // die Wurzel
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
      expect(theoryGraph.childrenOf(schlafThema.id), isEmpty);

      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(schlafThema.name));
      await tester.pumpAndSettle();

      // Nur noch der Startknoten selbst — über ihm geht es nicht weiter.
      expect(find.byType(NodeBubble), findsOneWidget);
      expect(container.read(spentTheoryPointsProvider), 1); // die Wurzel
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

      expect(container.read(spentTheoryPointsProvider), 2);
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
      expect(container.read(spentTheoryPointsProvider), 1); // die Wurzel
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

    /// Der Rückweg trägt nur noch den Namen; „Zurück zu“ hört der
    /// Vorleser.
    Finder rueckweg(String name) => find.byWidgetPredicate(
      (w) => w is Text && w.semanticsLabel == 'Zurück zu $name',
    );

    testWidgets('der Elternknoten führt zurück', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);
      await tester.tap(find.text(schlaf.name));
      await tester.pumpAndSettle();

      expect(rueckweg('Körper'), findsOneWidget);

      await tester.tap(rueckweg('Körper'));
      await tester.pumpAndSettle();

      // Alle Kinder stehen wieder da.
      for (final kind in theoryGraph.childrenOf('koerper')) {
        expect(find.text(kind.name), findsOneWidget, reason: kind.id);
      }
      expect(rueckweg('Körper'), findsNothing);
    });

    testWidgets('an der Wurzel gibt es keinen Rückweg im Baum', (tester) async {
      useTallView(tester);
      final container = _containerAtLevel(3);
      addTearDown(container.dispose);

      await pumpTree(tester, container);

      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.semanticsLabel ?? '').startsWith('Zurück zu'),
        ),
        findsNothing,
      );
    });

    testWidgets('ein zu teurer Knoten nennt den Grund statt eines Knopfes', (
      tester,
    ) async {
      useTallView(tester);
      final container = _containerAtLevel(1);
      addTearDown(container.dispose);
      _bisAufEinenPunkt(container);

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

      final ebene = theoryGraph.nodeById('kraft-muskulatur')!;
      final mitFaehigkeit = theoryGraph
          .childrenOf(ebene.id)
          .firstWhere((n) => n.unlocksAbility != null);

      await tester.tap(find.text(ebene.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(mitFaehigkeit.name));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fähigkeit'), findsNothing);
      // Der Funke der Rückfrage oben ist Erfahrung, kein Hinweis.
      final inDerRueckfrage = find.descendant(
        of: find.byType(ReviewSection),
        matching: find.byIcon(Icons.auto_awesome),
      );
      expect(
        find.byIcon(Icons.auto_awesome),
        findsNWidgets(inDerRueckfrage.evaluate().length),
      );
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

    /// Beantwortet die zweite Runde richtig, falls es eine gibt
    /// (ADR-0055): Was falsch war, kommt am Ende noch einmal.
    Future<void> zweiteRunde(WidgetTester tester) async {
      while (find.textContaining('Noch einmal').evaluate().isNotEmpty) {
        final question = shownQuestion();
        await tester.tap(find.text(question.options[question.correctIndex]));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
      }
    }

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
      await zweiteRunde(tester);
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

    group('Die zweite Runde (ADR-0055)', () {
      Future<void> ersteRunde(
        WidgetTester tester, {
        required int falsch,
      }) async {
        await tester.tap(
          find.text('${_first.questionCount} Fragen beantworten'),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < _first.questionCount; i++) {
          final question = shownQuestion();
          final option = i < falsch
              ? (question.correctIndex + 1) % question.options.length
              : question.correctIndex;
          await tester.tap(find.text(question.options[option]));
          await tester.pumpAndSettle();
          final isLast = i == _first.questionCount - 1;
          await tester.tap(find.text(isLast ? 'Auswerten' : 'Weiter'));
          await tester.pumpAndSettle();
        }
      }

      testWidgets('alles richtig: keine zweite Runde', (tester) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await pump(tester, container);

        await ersteRunde(tester, falsch: 0);

        expect(find.textContaining('Noch einmal'), findsNothing);
        expect(
          container.read(theoryProgressProvider).isPassed(_first.id),
          isTrue,
        );
      });

      testWidgets('eine falsche Antwort kommt am Ende noch einmal', (
        tester,
      ) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await pump(tester, container);

        await ersteRunde(tester, falsch: 1);

        expect(find.text('Noch einmal — die letzte'), findsOneWidget);
        // Noch nicht abgegeben: Das Ergebnis kommt nach der Runde.
        expect(
          container.read(theoryProgressProvider).recordFor(_first.id),
          isNull,
        );
      });

      testWidgets('wieder falsch heißt: sie kommt wieder', (tester) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await pump(tester, container);
        await ersteRunde(tester, falsch: 1);

        final frage = shownQuestion();
        await tester.tap(
          find.text(
            frage.options[(frage.correctIndex + 1) % frage.options.length],
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();

        expect(find.text('Noch einmal — die letzte'), findsOneWidget);
        expect(shownQuestion().prompt, frage.prompt);
      });

      testWidgets('gewertet wird der erste Durchgang', (tester) async {
        // Zwei von drei falsch, dann alles nachgeholt: Die Seite ist
        // trotzdem nicht bestanden. Sonst bestünde jede.
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await pump(tester, container);

        await ersteRunde(tester, falsch: 2);
        await zweiteRunde(tester);

        final record = container
            .read(theoryProgressProvider)
            .recordFor(_first.id);
        expect(record, isNotNull);
        expect(record!.bestCorrect, _first.questionCount - 2);
        expect(
          container.read(theoryProgressProvider).isPassed(_first.id),
          isFalse,
        );
      });
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

    group('Direkt zur nächsten Seite (ADR-0070)', () {
      final schleife = theoryGraph.nodeById('gewohnheiten-schleife')!;

      Future<void> bestehe(WidgetTester tester) async {
        await tester.tap(
          find.text('${_first.questionCount} Fragen beantworten'),
        );
        await tester.pumpAndSettle();
        await answerAll(tester, correctly: true);
      }

      testWidgets('nach einer bestandenen Seite steht die nächste da, mit '
          'ihrem Preis', (tester) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await pump(tester, container);
        await bestehe(tester);

        expect(find.byKey(LessonResultView.nextKey), findsOneWidget);
        expect(find.text(schleife.name), findsOneWidget);
        expect(
          find.bySemanticsLabel('Weiter zu ${schleife.name}, kostet 1 Punkt'),
          findsOneWidget,
        );
        // Der alte Hauptknopf heißt dann „Fertig“.
        expect(find.text('Fertig'), findsOneWidget);
        expect(find.text('Weiter'), findsNothing);
      });

      testWidgets('ein Tipp öffnet sie, zahlt den Punkt und zeigt sie', (
        tester,
      ) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await pump(tester, container);
        await bestehe(tester);
        final vorher = container.read(spentTheoryPointsProvider);

        await tester.tap(find.byKey(LessonResultView.nextKey));
        await tester.pumpAndSettle();

        expect(container.read(spentTheoryPointsProvider), vorher + 1);
        expect(
          container
              .read(theoryProgressProvider)
              .isNodeOpened(schleife.id, theoryGraph),
          isTrue,
        );
        // An der Stelle der gelesenen Seite, nicht darüber.
        expect(find.byType(LessonScreen), findsOneWidget);
        expect(find.text(schleife.summary), findsOneWidget);
      });

      testWidgets('ist sie schon offen, kostet der Tipp nichts', (
        tester,
      ) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(theoryProgressProvider.notifier);
        for (final id in theoryBasicsPath.take(5)) {
          notifier.openNode(
            id,
            availablePoints: container.read(availableTheoryPointsProvider),
          );
        }
        final vorher = container.read(spentTheoryPointsProvider);

        await pump(tester, container);
        await bestehe(tester);

        expect(
          find.bySemanticsLabel('Weiter zu ${schleife.name}'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(LessonResultView.nextKey));
        await tester.pumpAndSettle();

        expect(container.read(spentTheoryPointsProvider), vorher);
        expect(find.text(schleife.summary), findsOneWidget);
      });

      testWidgets('ohne Punkt und ohne offene Seite bleibt es bei „Weiter“', (
        tester,
      ) async {
        useTallView(tester);
        final container = ProviderContainer(
          overrides: [availableTheoryPointsProvider.overrideWithValue(0)],
        );
        addTearDown(container.dispose);
        // Der Weg bis hierher ist gelesen, sonst läge noch eine offene
        // Seite herum — und die wäre zu Recht die nächste.
        final notifier = container.read(theoryProgressProvider.notifier);
        for (final id in theoryBasicsPath.take(3)) {
          final seite = theoryGraph.nodeById(id)!.lesson;
          notifier.openNode(id, availablePoints: 1);
          notifier.submit(seite, <int?>[
            for (final q in seite.questions) q.correctIndex,
          ]);
        }

        await pump(tester, container);
        await bestehe(tester);

        expect(find.byKey(LessonResultView.nextKey), findsNothing);
        expect(find.text('Weiter'), findsOneWidget);
        expect(find.text('Fertig'), findsNothing);
      });

      testWidgets('wer durchfällt, bekommt keine nächste Seite', (
        tester,
      ) async {
        useTallView(tester);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await pump(tester, container);
        await tester.tap(
          find.text('${_first.questionCount} Fragen beantworten'),
        );
        await tester.pumpAndSettle();
        await answerAll(tester, correctly: false);

        expect(find.text('Noch nicht bestanden'), findsOneWidget);
        expect(find.byKey(LessonResultView.nextKey), findsNothing);
      });
    });
  });

  group('Gezählt wird der Graph, und nichts doppelt (ADR-0070)', () {
    // Der Umbau auf den Graphen (ADR-0019) hat Seiten aus `theoryTree`
    // herausgenommen; wer danach weiter die Zweige zählte, unterschlug
    // sie. ADR-0070 dreht die Gefahr um: Die fünf Seiten des früheren
    // Handbuchs stehen jetzt im Graphen **und** im Zweig. Wer beide
    // zusammenzählt, zählt sie doppelt.
    List<int?> richtig(Lesson lesson) => <int?>[
      for (final q in lesson.questions) q.correctIndex,
    ];

    test('die Gesamtzahl ist die Zahl der Knoten', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(totalPagesProvider), 63);
      expect(container.read(totalPagesProvider), theoryGraph.nodeCount);
    });

    test('eine bestandene Knotenseite zählt mit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final knoten = theoryGraph.nodes.firstWhere(
        (n) => !theoryTree.branches.any((b) => b.indexOf(n.lesson.id) >= 0),
      );

      expect(container.read(passedPagesProvider), 0);

      container
          .read(theoryProgressProvider.notifier)
          .submit(knoten.lesson, richtig(knoten.lesson));

      expect(container.read(passedPagesProvider), 1);
      expect(container.read(achievementStatsProvider).passedLessons, 1);
    });

    test('eine Seite des früheren Handbuchs zählt genau einmal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(theoryProgressProvider.notifier)
          .submit(_first, richtig(_first));

      expect(container.read(passedPagesProvider), 1);
      final zahlen = container.read(achievementStatsProvider);
      expect(zahlen.passedLessons, 1);
      expect(zahlen.perfectLessons, 1);
      // Auch die Rückfrage des Tages zieht sie nur einmal.
      expect(container.read(passedLessonsProvider), <Lesson>[_first]);
    });

    test('alle fünf zusammen sind fünf Seiten und fünfmal perfekt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(theoryProgressProvider.notifier);
      for (final lesson in habitsBranch.lessons) {
        notifier.submit(lesson, richtig(lesson));
      }

      expect(container.read(passedPagesProvider), 5);
      expect(container.read(achievementStatsProvider).perfectLessons, 5);
      expect(container.read(grundlagenGelesenProvider), isTrue);
    });
  });
}

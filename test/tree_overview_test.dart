import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/node_bubble.dart';
import 'package:lifes_game/theory/widgets/tree_overview.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Der Überblick im Wissensbaum (ADR-0056): Ring und Zähler an jedem
/// Knoten mit Unterpunkten, vier Gebiete oben, „Weiterlesen“, Legende.
void main() {
  /// Ein Stand auf Level 10, nichts gelesen. Mit [ohnePunkte] ist kein
  /// Punkt frei — dann schlägt der Baum auch nichts vor (ADR-0070).
  ProviderContainer container({bool ohnePunkte = false}) {
    final c = ProviderContainer(
      overrides: [
        playerLevelProvider.overrideWithValue(
          LevelCurve.levelFor(LevelCurve.totalXpFor(10)),
        ),
        if (ohnePunkte) availableTheoryPointsProvider.overrideWithValue(0),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  void bestehe(ProviderContainer c, String id) {
    final node = theoryGraph.nodeById(id)!;
    c
        .read(theoryProgressProvider.notifier)
        .openNode(id, availablePoints: c.read(availableTheoryPointsProvider));
    c.read(theoryProgressProvider.notifier).submit(node.lesson, <int?>[
      for (final q in node.lesson.questions) q.correctIndex,
    ]);
  }

  Future<void> baum(WidgetTester tester, ProviderContainer c) async {
    useTallView(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: SkillTreeScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('eine Zwischenebene zeigt, wie viel darunter geschafft ist', (
    tester,
  ) async {
    final c = container();
    bestehe(c, 'koerper');
    bestehe(c, 'kraft-muskulatur');
    final themen = theoryGraph.childrenOf('kraft-muskulatur');
    bestehe(c, themen.first.id);
    await baum(tester, c);

    final blase = tester.widget<NodeBubble>(
      find.byWidgetPredicate(
        (w) => w is NodeBubble && w.node.id == 'kraft-muskulatur',
      ),
    );
    expect(blase.below, (passed: 1, total: themen.length));
    expect(find.text('1 / ${themen.length}'), findsOneWidget);
  });

  testWidgets('vier Gebiete stehen oben mit ihrem Stand', (tester) async {
    final c = container();
    bestehe(c, 'koerper');
    await baum(tester, c);

    expect(find.byType(AreaProgressRow), findsOneWidget);
    final gesamt = theoryGraph.descendantsOf('koerper', includeSelf: true);
    expect(find.text('1/${gesamt.length}'), findsOneWidget);
  });

  testWidgets('ein Gebiet oben antippen wechselt dorthin', (tester) async {
    // Ohne Punkte: Sonst stünde „Geist“ schon als Vorschlag da.
    final c = container(ohnePunkte: true);
    await baum(tester, c);
    final geist = theoryGraph.nodeById(theoryRootIds[1])!;
    expect(find.text(geist.name), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(AreaProgressRow),
        matching: find.bySemanticsLabel(RegExp('^${geist.name},')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(geist.name), findsWidgets);
  });

  testWidgets('„Weiterlesen“ führt zur offenen Seite', (tester) async {
    final c = container();
    c
        .read(theoryProgressProvider.notifier)
        .openNode('koerper', availablePoints: 5);
    await baum(tester, c);

    final kachel = find.byType(ContinueReadingTile);
    expect(kachel, findsOneWidget);

    await tester.tap(kachel);
    await tester.pumpAndSettle();

    final seite = tester.widget<LessonScreen>(find.byType(LessonScreen));
    expect(seite.lesson.id, theoryGraph.nodeById('koerper')!.lesson.id);
  });

  testWidgets('ohne offene Seite und ohne Punkt kein „Weiterlesen“', (
    tester,
  ) async {
    await baum(tester, container(ohnePunkte: true));

    expect(find.byType(ContinueReadingTile), findsNothing);
  });

  testWidgets('ohne offene Seite schlägt er den Weg der Grundlagen vor', (
    tester,
  ) async {
    await baum(tester, container());

    final vorschlag = tester.widget<ContinueReadingTile>(
      find.byType(ContinueReadingTile),
    );
    expect(vorschlag.node.id, theoryBasicsPath.first);
    expect(vorschlag.cost, 1);
  });

  testWidgets('wer etwas geöffnet hat, bekommt das vorgeschlagen und nicht '
      'den Weg', (tester) async {
    final c = container();
    c
        .read(theoryProgressProvider.notifier)
        .openNode('koerper', availablePoints: 5);
    await baum(tester, c);

    final vorschlag = tester.widget<ContinueReadingTile>(
      find.byType(ContinueReadingTile),
    );
    expect(vorschlag.node.id, 'koerper');
    expect(vorschlag.cost, isNull);
  });

  testWidgets('die Legende erklärt die Zeichen', (tester) async {
    await baum(tester, container());

    await tester.tap(find.byTooltip('Was die Zeichen bedeuten'));
    await tester.pumpAndSettle();

    expect(find.text('Was die Zeichen bedeuten'), findsWidgets);
    expect(find.text('Geöffnet, noch zu lesen'), findsOneWidget);
    expect(find.byType(NodeStateBadge), findsWidgets);
  });
}

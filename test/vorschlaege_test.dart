import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/progression/show_level_up.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/lesson_screen.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:lifes_game/theory/widgets/tree_overview.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';

/// Vorschläge für das nächste Kapitel (26.10.2026): bis zu drei im Baum
/// und in der Feier eines Aufstiegs; ein Tipp öffnet und liest.
void main() {
  const heute = Day(2026, 10, 26);

  /// Eine eigene Gewohnheit aus Gesellschaft, zehn Tage abgehakt.
  HabitTracker gesellig() {
    const h = CustomHabit(
      id: 'eigen-anrufen',
      name: 'Freund anrufen',
      area: SkillArea.gesellschaft,
      difficulty: HabitDifficulty.mittel,
    );
    var t = const HabitTracker.empty()
        .addCustom(h, slots: 5)
        .activate(h.id, today: heute.plus(-10));
    for (var i = 10; i > 0; i--) {
      t = t.check(h.id, heute.plus(-i)).tracker;
    }
    return t;
  }

  ProviderContainer stand({required int level}) {
    final c = ProviderContainer(
      overrides: [
        todayProvider.overrideWithValue(heute),
        savedGameProvider.overrideWithValue(SaveData(habits: gesellig())),
        playerLevelProvider.overrideWithValue(
          LevelCurve.levelFor(LevelCurve.totalXpFor(level)),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Der Weg der Grundlagen ist gelesen — danach gab es bisher nichts.
  void grundlagenGelesen(ProviderContainer c) {
    final theorie = c.read(theoryProgressProvider.notifier);
    for (final id in theoryBasicsPath) {
      final node = theoryGraph.nodeById(id)!;
      theorie.openNode(id, availablePoints: 100);
      theorie.submit(node.lesson, <int?>[
        for (final q in node.lesson.questions) q.correctIndex,
      ]);
    }
  }

  testWidgets('nach den Grundlagen stehen oben bis zu drei Vorschläge', (
    tester,
  ) async {
    useTallView(tester);
    final c = stand(level: 20);
    grundlagenGelesen(c);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(home: SkillTreeScreen()),
      ),
    );
    await tester.pump();

    final kacheln = tester
        .widgetList<ContinueReadingTile>(find.byType(ContinueReadingTile))
        .toList();
    expect(kacheln, hasLength(3));
    expect(kacheln.map((k) => k.node.id).toSet(), hasLength(3));
    // Die Häkchen in Gesellschaft schlagen eine Seite dort vor.
    final passend = kacheln.where(
      (k) => k.grund == TheoryVorschlagGrund.gewohnheiten,
    );
    expect(passend, hasLength(1));
    expect(
      theoryGraph.rootIdsOf(passend.single.node.id),
      contains(SkillArea.gesellschaft.name),
    );
  });

  testWidgets('beim Aufstieg mit Punkt: ein Tipp öffnet und liest', (
    tester,
  ) async {
    useTallView(tester);
    final c = stand(level: 20);
    grundlagenGelesen(c);
    final vorschlaege = c.read(vorschlaegeProvider(null));
    expect(vorschlaege, isNotEmpty);
    final erster = vorschlaege.first;
    expect(erster.step.needsOpening, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showLevelUp(context, ref, before: 19),
                child: const Text('los'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();

    final knopf = find.byKey(LevelUpSheet.vorschlagKey(erster.node.id));
    expect(knopf, findsOneWidget);
    await tester.tap(knopf);
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(
      c.read(theoryProgressProvider).openedNodeIds,
      contains(erster.node.id),
      reason: 'Der Punkt ist mit dem Tipp ausgegeben.',
    );
  });
}

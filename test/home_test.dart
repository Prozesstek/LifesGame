import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/combat/enemy_picker_screen.dart';
import 'package:lifes_game/gear/shop_screen.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/home/widgets/hub_tile.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/theory/theory_controller.dart';
import 'package:theory/theory.dart';
import 'package:lifes_game/main.dart';
import 'package:lifes_game/theory/skill_tree_screen.dart';

import 'test_view.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('zeigt alle Bereiche des Konzepts', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      for (final title in <String>[
        'Gewohnheiten',
        'Theorie',
        'Kampf',
        'Laden',
        'Charakter',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('nur der Kampf ist zu Beginn gesperrt', (tester) async {
      // Der Startbildschirm hatte lange gesperrte Kacheln, damit
      // sichtbar blieb, wohin es geht. Seit ADR-0018 ist genau eine
      // wieder zu: Mit nur einem Move ist der erste Kampf nicht knapp,
      // sondern unmöglich.
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));
      final locked = tiles
          .where((t) => t.onTap == null)
          .map((t) => t.title)
          .toList();

      expect(tiles, hasLength(5));
      expect(locked, <String>['Kampf']);
    });

    testWidgets('die gesperrte Kachel nennt den Weg, nicht die Absage', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      expect(find.textContaining('Erst das Handbuch'), findsOneWidget);
    });

    testWidgets('mit durchgearbeitetem Handbuch geht der Kampf auf', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(
              SaveData(theory: _mitHandbuch()),
            ),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));
      final locked = tiles.where((t) => t.onTap == null);

      expect(locked, isEmpty);
    });
    testWidgets('Gewohnheiten führt zum Tracker', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Gewohnheiten'));
      await tester.pumpAndSettle();

      expect(find.byType(HabitsScreen), findsOneWidget);
    });

    testWidgets('Theorie führt zum Skillbaum', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Theorie'));
      await tester.pumpAndSettle();

      expect(find.byType(SkillTreeScreen), findsOneWidget);
    });

    testWidgets('Kampf führt zur Gegnerwahl, sobald er offen ist', (
      tester,
    ) async {
      // Braucht seit ADR-0018 das durchgearbeitete Handbuch. Ohne
      // Vorbedingung wäre die Kachel gesperrt und der Tipp ginge ins
      // Leere.
      useTallView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedGameProvider.overrideWithValue(
              SaveData(theory: _mitHandbuch()),
            ),
          ],
          child: const LifesGameApp(),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.byType(EnemyPickerScreen), findsOneWidget);
    });

    testWidgets('ein gesperrter Kampf führt nirgendwohin', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.byType(EnemyPickerScreen), findsNothing);
    });

    testWidgets('Laden führt zum Shop', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Laden'));
      await tester.pumpAndSettle();

      expect(find.byType(ShopScreen), findsOneWidget);
    });

    testWidgets('Charakter führt zum Charakterbildschirm', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Charakter'));
      await tester.pumpAndSettle();

      expect(find.byType(CharacterScreen), findsOneWidget);
    });

    testWidgets('der Charakter startet auf Level 1 ohne Gold', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('0 von 100 Erfahrung bis Level 2'), findsOneWidget);

      // Zweimal: einmal auf der Levelkarte, einmal als Zustand der
      // Laden-Kachel.
      expect(find.text('0 Gold'), findsNWidgets(2));
    });
  });
}

/// Ein Theoriestand, in dem das Handbuch durchgearbeitet ist.
///
/// **Die Zahl dahinter ist der Grund für ADR-0018:** Die fünf Lektionen
/// geben zusammen 275 Erfahrung und damit Level 3 — genau die Stufe, auf
/// der der zweite Fähigkeitsslot aufgeht. Vier Lektionen wären 220 und
/// damit fünf Punkte zu wenig.
TheoryProgress _mitHandbuch() {
  final branch = theoryTree.branches.firstWhere(
    (b) => b.id == handbookBranchId,
  );

  var progress = const TheoryProgress.empty();
  for (final lesson in branch.lessons) {
    progress = progress.submit(lesson, <int?>[
      for (final question in lesson.questions) question.correctIndex,
    ]).progress;
  }
  return progress;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/combat_screen.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/home/widgets/hub_tile.dart';
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
        'Shop',
        'Charakter',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('noch nicht gebaute Bereiche sind nicht antippbar', (
      tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));
      final locked = tiles.where((t) => t.onTap == null).map((t) => t.title);

      expect(locked, containsAll(<String>['Shop', 'Charakter']));
      expect(locked, isNot(contains('Gewohnheiten')));
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

    testWidgets('Kampf führt zum Kampfbildschirm', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      // Kein pumpAndSettle: der Kampfbildschirm enthält ein Flame-Widget,
      // das dauerhaft animiert und deshalb nie „zur Ruhe kommt“.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CombatScreen), findsOneWidget);
    });

    testWidgets('der Charakter startet auf Level 1 ohne Gold', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('0 Gold'), findsOneWidget);
      expect(find.text('0 von 100 Erfahrung bis Level 2'), findsOneWidget);
    });
  });
}

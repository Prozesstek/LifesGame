import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/character/character_screen.dart';
import 'package:lifes_game/combat/enemy_picker_screen.dart';
import 'package:lifes_game/gear/shop_screen.dart';
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
        'Laden',
        'Charakter',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });

    testWidgets('alle fünf Bereiche sind offen', (tester) async {
      // Der Startbildschirm hatte lange gesperrte Kacheln, damit sichtbar
      // blieb, wohin es geht. Mit Laden und Charakter ist der MVP-Schnitt
      // bis auf den Dungeon vollständig — hier steht jetzt, dass keine
      // Kachel mehr ins Leere zeigt.
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      final tiles = tester.widgetList<HubTile>(find.byType(HubTile));
      final locked = tiles.where((t) => t.onTap == null).map((t) => t.title);

      expect(tiles, hasLength(5));
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

    testWidgets('Kampf führt zur Gegnerwahl', (tester) async {
      useTallView(tester);
      await tester.pumpWidget(const ProviderScope(child: LifesGameApp()));
      await tester.pump();

      await tester.tap(find.text('Kampf'));
      await tester.pumpAndSettle();

      expect(find.byType(EnemyPickerScreen), findsOneWidget);
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

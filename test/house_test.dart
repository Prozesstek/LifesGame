import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/achievements/achievements_screen.dart';
import 'package:lifes_game/village/house_screen.dart';
import 'package:lifes_game/village/village_game.dart';
import 'package:lifes_game/village/village_map.dart';
import 'package:lifes_game/village/village_screen.dart';

import 'test_view.dart';

/// Das eigene Haus: ein Raum, in dem man sieht, was man erreicht hat.
void main() {
  group('Der Raum', () {
    test('jedes Ding im Haus ist vom Eingang aus erreichbar', () {
      for (final ort in VillagePlace.haus) {
        final platz = house.doors[ort];
        expect(platz, isNotNull, reason: ort.label);
        expect(
          house.pathBetween(house.start, platz!),
          isNotNull,
          reason: ort.label,
        );
      }
    });

    test('jedes Ding hat ein Bild', () {
      for (final ort in VillagePlace.values) {
        expect(DorfBilder.orte, contains(ort), reason: ort.label);
      }
    });
  });

  group('Was es zeigt', () {
    const tag = Day(2026, 9, 23);

    HabitTracker mitTruhe() {
      const eigene = CustomHabit(
        id: 'a',
        name: 'a',
        stat: HabitStat.staerke,
        difficulty: HabitDifficulty.mittel,
        priority: HabitPriority.normal,
      );
      final t = const HabitTracker.empty()
          .addCustom(eigene, slots: 5)
          .activate('a')
          .check('a', tag)
          .tracker;
      return t.openChest(tag).tracker;
    }

    test('ein Pokal je Errungenschaft, ein Banner je Titel', () {
      final ansicht = HouseView.from(
        earnedAchievements: const <String>{'x', 'y', 'z'},
        earnedTitles: const <String>{'moench'},
        loadout: const Loadout.empty(),
        habits: const HabitTracker.empty(),
      );
      expect(ansicht.trophies, 3);
      expect(ansicht.titles, <String>['der Mönch']);
      expect(ansicht.gearIcons, isEmpty, reason: 'nichts angelegt');
    });

    test('das Gold neben der Truhe ist das Gold aus Tagestruhen', () {
      final t = mitTruhe();
      final ansicht = HouseView.from(
        earnedAchievements: const <String>{},
        earnedTitles: const <String>{},
        loadout: const Loadout.empty(),
        habits: t,
      );
      expect(ansicht.chestsOpened, 1);
      expect(ansicht.chestGold, DailyChest.forDay(tag).gold);
      expect(
        ansicht.treasures,
        DailyChest.forDay(tag).tier == ChestTier.schatz ? 1 : 0,
      );
    });
  });

  group('Der Weg hinein und hinaus', () {
    Future<VillageGame> spielVon(WidgetTester tester) async {
      return tester
          .widget<GameWidget<VillageGame>>(
            find.byType(GameWidget<VillageGame>).last,
          )
          .game!;
    }

    Future<void> laufenLassen(WidgetTester tester, double sekunden) async {
      for (var t = 0.0; t < sekunden; t += 0.05) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> tippe(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('vom Dorf ins Haus, zu den Trophäen und wieder hinaus', (
      tester,
    ) async {
      usePhoneView(tester);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: VillageScreen())),
      );
      await tester.pump();

      final dorf = await spielVon(tester);
      dorf.walker.walkTo(
        VillageMap.centerOf(village.doors[VillagePlace.zuhause]!),
      );
      await laufenLassen(tester, 4);
      await tippe(tester, 'Zuhause betreten');
      expect(find.byType(HouseScreen), findsOneWidget);

      final haus = await spielVon(tester);
      haus.walker.walkTo(
        VillageMap.centerOf(house.doors[VillagePlace.trophaeen]!),
      );
      await laufenLassen(tester, 4);
      await tippe(tester, 'Trophäen ansehen');
      expect(find.byType(AchievementsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      haus.walker.walkTo(
        VillageMap.centerOf(house.doors[VillagePlace.ausgang]!),
      );
      await laufenLassen(tester, 4);
      await tippe(tester, 'Hinausgehen');
      expect(find.byType(HouseScreen), findsNothing);
      expect(find.byType(VillageScreen), findsOneWidget);
    });

    testWidgets('die Truhe zeigt die Schätze', (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HouseScreen())),
      );
      await tester.pump();

      final haus = await spielVon(tester);
      haus.walker.walkTo(VillageMap.centerOf(house.doors[VillagePlace.truhe]!));
      await laufenLassen(tester, 4);
      await tippe(tester, 'Schatztruhe öffnen');

      expect(find.text('Deine Schätze'), findsOneWidget);
      expect(find.textContaining('Noch leer'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/habit_check_tile.dart';
import 'package:lifes_game/home/widgets/status_leiste.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/skills/widgets/gebiets_balken.dart';
import 'package:lifes_game/skills/widgets/gebiets_kacheln.dart';
import 'package:lifes_game/ui/beute_flug.dart';
import 'package:lifes_game/ui/palette.dart';

import 'test_view.dart';

/// ADR-0092: oben die vier Gebiete, auf der Kachel nur noch Erfahrung,
/// Gold und die Kette.
void main() {
  const heute = Day(2026, 10, 30);

  CustomHabit eigene(
    String id,
    String name,
    SkillArea area, {
    HabitGoal? goal,
  }) => CustomHabit(
    id: id,
    name: name,
    area: area,
    difficulty: HabitDifficulty.mittel,
    goal: goal,
  );

  HabitTracker mit(List<CustomHabit> eigene) {
    var tracker = const HabitTracker.empty();
    for (final habit in eigene) {
      tracker = tracker.addCustom(habit, slots: 10).activate(habit.id);
    }
    return tracker;
  }

  final zwei = mit(<CustomHabit>[
    eigene('a', 'Laufen', SkillArea.koerper),
    eigene('b', 'Lesen', SkillArea.geist),
  ]);

  Future<void> bildschirm(WidgetTester tester, HabitTracker tracker) async {
    useTallView(tester);
    final container = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        todayProvider.overrideWithValue(heute),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HabitsScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('die vier Gebiete stehen über der Liste', (tester) async {
    await bildschirm(tester, zwei);

    for (final area in SkillArea.values) {
      expect(find.byKey(GebietsKacheln.keyFor(area)), findsOneWidget);
    }
    final unten = tester.getBottomLeft(find.byType(GebietsKacheln)).dy;
    final oben = tester.getTopLeft(find.byType(HabitCheckTile).first).dy;
    expect(unten, lessThanOrEqualTo(oben));
  });

  testWidgets('Level und Gold stehen in der Titelzeile', (tester) async {
    await bildschirm(tester, zwei);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(StatusLeiste),
      ),
      findsOneWidget,
    );
    expect(find.byType(GebietsBalken), findsNothing);
  });

  testWidgets('die Funken fliegen in die Kachel ihres Gebiets', (tester) async {
    await bildschirm(tester, zwei);

    await tester.tap(find.text('Lesen'));
    await tester.pump();

    final maler = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.foregroundPainter)
        .whereType<BeuteFlugMaler>()
        .single;
    final funken = maler.flug.stuecke.where((s) => s.ziel == FlugZiel.gebiet);
    expect(funken, isNotEmpty);
    final kachel = tester.getCenter(
      find.byKey(GebietsKacheln.keyFor(SkillArea.geist)),
    );
    for (final funke in funken) {
      expect(funke.nach, kachel);
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ein Mengenziel nennt sein Ziel und hat keinen Knopf', (
    tester,
  ) async {
    await bildschirm(
      tester,
      mit(<CustomHabit>[
        eigene(
          'w',
          'Wasser',
          SkillArea.koerper,
          goal: HabitGoal.menge(target: 5, unit: 'Gläser'),
        ),
      ]),
    );

    expect(find.text('5 Gläser'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });

  testWidgets('das Kreuz bleibt auf der offenen Kachel, der Wecker nicht', (
    tester,
  ) async {
    await bildschirm(tester, zwei);

    Finder aufDerKachel(IconData icon) => find.descendant(
      of: find.byType(HabitCheckTile),
      matching: find.byIcon(icon),
    );
    expect(aufDerKachel(Icons.add_alarm_outlined), findsNothing);
    expect(aufDerKachel(Icons.close), findsNWidgets(2));
  });

  testWidgets('das Kreuz ist rot, ohne Knopf, oben rechts in der Kachel', (
    tester,
  ) async {
    await bildschirm(tester, zwei);

    final kachel = find.byType(HabitCheckTile).first;
    final kreuz = find.descendant(
      of: kachel,
      matching: find.byIcon(Icons.close),
    );
    expect(tester.widget<Icon>(kreuz).color, Palette.enemy);
    expect(
      find.ancestor(of: kreuz, matching: find.byType(IconButton)),
      findsNothing,
    );

    final flaeche = tester.getRect(kachel);
    final mitte = tester.getCenter(kreuz);
    expect(mitte.dx, greaterThan(flaeche.center.dx));
    expect(mitte.dy, lessThan(flaeche.center.dy));
  });
}

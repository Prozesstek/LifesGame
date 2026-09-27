import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/gear/gear_controller.dart';
import 'package:lifes_game/habits/daily_quests_provider.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/daily_quests_card.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Tagesaufgaben in der App (ADR-0055): vom Häkchen bis zum Schlüssel.
///
/// Mit **zwei** laufenden Gewohnheiten ist die Aufgabe zum Abhaken immer
/// „Hake 2 ab" oder „Erledige heute alles" — beide sind erfüllt, sobald
/// beide abgehakt sind. Der Test hängt damit nicht vom Würfel des Tages
/// ab.
void main() {
  const heute = Day(2026, 9, 27);
  final a = HabitCatalog.all[0];
  final b = HabitCatalog.all[1];

  HabitTracker beideErledigt() => const HabitTracker.empty()
      .activate(a.id)
      .activate(b.id)
      .check(a.id, heute)
      .tracker
      .check(b.id, heute)
      .tracker;

  ProviderContainer container(HabitTracker tracker) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        todayProvider.overrideWithValue(heute),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> zeige(
    WidgetTester tester,
    ProviderContainer c,
    Widget screen,
  ) async {
    useTallView(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump();
  }

  test('die Aufgabe zum Abhaken ist erfüllt, wenn beides erledigt ist', () {
    final c = container(beideErledigt());

    final zumAbhaken = c
        .read(dailyQuestsProvider)
        .singleWhere((q) => q.kind.isHabitCount);

    expect(zumAbhaken.isDone, isTrue);
    expect(c.read(claimableQuestsProvider), contains(zumAbhaken));
  });

  testWidgets('die Karte steht auf dem Gewohnheiten-Bildschirm', (
    tester,
  ) async {
    await zeige(tester, container(beideErledigt()), const HabitsScreen());

    expect(find.byType(DailyQuestsCard), findsOneWidget);
    expect(find.text('Tagesaufgaben'), findsOneWidget);
  });

  testWidgets('Abholen bringt einen Schlüssel, und nur einmal', (tester) async {
    final c = container(beideErledigt());
    await zeige(tester, c, const HabitsScreen());
    final vorher = c.read(earnedKeysProvider);
    final abholbar = c.read(claimableQuestsProvider).length;

    final knopf = find.descendant(
      of: find.byType(DailyQuestsCard),
      matching: find.text('Abholen'),
    );
    expect(knopf, findsNWidgets(abholbar));

    await tester.tap(knopf.first);
    await tester.pump();

    expect(c.read(earnedKeysProvider), vorher + DailyQuests.keysPerQuest);
    expect(c.read(claimableQuestsProvider), hasLength(abholbar - 1));
    expect(
      find.descendant(
        of: find.byType(DailyQuestsCard),
        matching: find.text('Abgeholt'),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('eine offene Aufgabe hat keinen Knopf', (tester) async {
    final offen = const HabitTracker.empty().activate(a.id).activate(b.id);
    await zeige(tester, container(offen), const HabitsScreen());

    expect(
      find.descendant(
        of: find.byType(DailyQuestsCard),
        matching: find.text('Abholen'),
      ),
      findsNothing,
    );
  });

  testWidgets('die Startseite sagt, dass etwas abzuholen ist', (tester) async {
    await zeige(tester, container(beideErledigt()), const HomeScreen());

    expect(
      find.descendant(
        of: find.byType(TodayCard),
        matching: find.textContaining('abholen'),
      ),
      findsOneWidget,
    );
  });
}

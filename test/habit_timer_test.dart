import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/habit_check_tile.dart';
import 'package:lifes_game/habits/widgets/habit_timer_sheet.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/progression/level_provider.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Zeitziele als Timer in der App (ADR-0067): vom Tipp auf die Kachel
/// über den laufenden Ring bis zum Häkchen bei null.
///
/// Die Uhr ist hier eine Variable: `tester.pump` bewegt den Sekundentakt,
/// aber nicht `DateTime.now` — und der Timer rechnet aus der Uhr.
void main() {
  const heute = Day(2026, 10, 4);
  final starter = HabitCatalog.starter;
  final lesen = CustomHabit(
    id: 'custom-1',
    name: 'Lesen',
    stat: HabitStat.klarheit,
    difficulty: HabitDifficulty.mittel,
    goal: HabitGoal.zeit(target: 20),
  );
  final wasser = CustomHabit(
    id: 'custom-2',
    name: 'Wasser',
    stat: HabitStat.ausdauer,
    difficulty: HabitDifficulty.mittel,
    goal: HabitGoal.menge(target: 5, unit: 'Gläser'),
  );

  HabitTracker mit(List<CustomHabit> habits) {
    var t = const HabitTracker.empty();
    for (final habit in habits) {
      t = t.addCustom(habit, slots: 5).activate(habit.id, today: heute);
    }
    return t;
  }

  ProviderContainer container(HabitTracker tracker, _Uhr uhr) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        todayProvider.overrideWithValue(heute),
        clockProvider.overrideWithValue(() => uhr.jetzt),
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

  /// Lässt [dauer] vergehen — auf der Uhr **und** im Sekundentakt.
  Future<void> warte(WidgetTester tester, _Uhr uhr, Duration dauer) async {
    uhr.jetzt = uhr.jetzt.add(dauer);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  group('Die Kachel', () {
    testWidgets('ein Zeitziel trägt den Timer-Knopf statt des Plus', (
      tester,
    ) async {
      final uhr = _Uhr();
      final c = container(mit(<CustomHabit>[lesen, wasser]), uhr);
      await zeige(tester, c, const HabitsScreen());

      expect(find.byKey(HabitCheckTile.timerKey(lesen.id)), findsOneWidget);
      expect(find.byKey(HabitCheckTile.timerKey(wasser.id)), findsNothing);
      // Das Plus gehört weiter der Menge, und nur ihr.
      expect(find.byTooltip('Eins mehr'), findsOneWidget);
      expect(find.byTooltip('5 Minuten mehr'), findsNothing);
    });

    testWidgets('ein Tipp öffnet den Timer und hakt nicht ab', (tester) async {
      final uhr = _Uhr();
      final c = container(mit(<CustomHabit>[lesen]), uhr);
      await zeige(tester, c, const HabitsScreen());

      await tester.tap(find.text(lesen.name));
      await tester.pumpAndSettle();

      expect(find.byType(HabitTimerSheet), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      expect(c.read(habitTrackerProvider).isChecked(lesen.id, heute), isFalse);
      expect(c.read(habitTrackerProvider).timer, isNull);
    });
  });

  group('Das Blatt', () {
    Future<ProviderContainer> offen(WidgetTester tester, _Uhr uhr) async {
      final c = container(mit(<CustomHabit>[lesen]), uhr);
      await zeige(tester, c, const HabitsScreen());
      await tester.tap(find.byKey(HabitCheckTile.timerKey(lesen.id)));
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('Start lässt die Zeit herunterlaufen', (tester) async {
      final uhr = _Uhr();
      final c = await offen(tester, uhr);

      await tester.tap(find.byKey(HabitTimerSheet.startKey));
      await tester.pump();
      expect(c.read(habitTrackerProvider).timer!.isRunning, isTrue);
      expect(find.byKey(HabitTimerSheet.pauseKey), findsOneWidget);

      await warte(tester, uhr, const Duration(minutes: 7, seconds: 18));

      // Im Blatt und auf der Kachel darunter dieselbe Zahl.
      expect(find.text('12:42'), findsNWidgets(2));
    });

    testWidgets('Pause hält an, und was gelaufen ist, bleibt stehen', (
      tester,
    ) async {
      final uhr = _Uhr();
      final c = await offen(tester, uhr);

      await tester.tap(find.byKey(HabitTimerSheet.startKey));
      await tester.pump();
      await warte(tester, uhr, const Duration(minutes: 12, seconds: 40));
      await tester.tap(find.byKey(HabitTimerSheet.pauseKey));
      await tester.pump();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.progressOn(lesen.id, heute), 12);
      expect(tracker.timer!.isRunning, isFalse);
      expect(find.byKey(HabitTimerSheet.startKey), findsOneWidget);

      // Eine Stunde später steht dieselbe Zeit da.
      await warte(tester, uhr, const Duration(hours: 1));
      expect(find.text('07:20'), findsOneWidget);
      expect(tracker.isChecked(lesen.id, heute), isFalse);
    });

    testWidgets('er läuft weiter, wenn das Blatt zu ist', (tester) async {
      final uhr = _Uhr();
      final c = await offen(tester, uhr);

      await tester.tap(find.byKey(HabitTimerSheet.startKey));
      await tester.pump();
      await tester.tap(find.byKey(HabitTimerSheet.closeKey));
      await tester.pumpAndSettle();

      expect(find.byType(HabitTimerSheet), findsNothing);
      expect(c.read(habitTrackerProvider).timer!.isRunning, isTrue);

      await warte(tester, uhr, const Duration(minutes: 5));
      expect(find.text('15:00'), findsOneWidget);
    });

    testWidgets('bei null ist abgehakt, das Blatt geht zu, der Ertrag ist da', (
      tester,
    ) async {
      final uhr = _Uhr();
      final c = await offen(tester, uhr);
      final xpVorher = c.read(totalXpProvider);

      await tester.tap(find.byKey(HabitTimerSheet.startKey));
      await tester.pump();
      await warte(tester, uhr, const Duration(minutes: 20));
      await tester.pumpAndSettle();

      final tracker = c.read(habitTrackerProvider);
      expect(tracker.isChecked(lesen.id, heute), isTrue);
      expect(tracker.timer, isNull);
      expect(find.byType(HabitTimerSheet), findsNothing);
      expect(c.read(totalXpProvider), greaterThan(xpVorher));
    });

    testWidgets('„schon erledigt“ hakt ab, ohne zu warten', (tester) async {
      final uhr = _Uhr();
      final c = await offen(tester, uhr);

      await tester.tap(find.byKey(HabitTimerSheet.doneKey));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).isChecked(lesen.id, heute), isTrue);
      expect(find.byType(HabitTimerSheet), findsNothing);
    });

    testWidgets('es passt aufs Handy, auch mit langem Namen', (tester) async {
      final lang = CustomHabit(
        id: 'custom-1',
        name: 'Jeden Abend in Ruhe ein Kapitel im Sachbuch lesen',
        stat: HabitStat.klarheit,
        difficulty: HabitDifficulty.mittel,
        goal: HabitGoal.zeit(target: 120),
      );
      final uhr = _Uhr();
      final c = container(mit(<CustomHabit>[lang]), uhr);
      await zeige(tester, c, const HabitsScreen());
      usePhoneView(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HabitCheckTile.timerKey(lang.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(HabitTimerSheet.startKey));
      await tester.pump();
      await warte(tester, uhr, const Duration(minutes: 3));

      expect(find.text('117:00'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('schließen allein ändert nichts', (tester) async {
      final uhr = _Uhr();
      final c = await offen(tester, uhr);
      final vorher = c.read(habitTrackerProvider);

      await tester.tap(find.byKey(HabitTimerSheet.closeKey));
      await tester.pumpAndSettle();

      expect(identical(c.read(habitTrackerProvider), vorher), isTrue);
    });
  });

  group('Beim Zurückkommen', () {
    testWidgets('ein Timer, der im Hintergrund ablief, hakt sofort ab', (
      tester,
    ) async {
      final uhr = _Uhr();
      final gestartet = mit(<CustomHabit>[
        lesen,
      ]).startTimer(lesen.id, heute, uhr.jetzt);
      // Die App war eine halbe Stunde zu.
      uhr.jetzt = uhr.jetzt.add(const Duration(minutes: 30));
      final c = container(gestartet, uhr);

      await zeige(tester, c, const HabitsScreen());
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).isChecked(lesen.id, heute), isTrue);
    });

    testWidgets('ein noch laufender zeigt die Restzeit von jetzt', (
      tester,
    ) async {
      final uhr = _Uhr();
      final gestartet = mit(<CustomHabit>[
        lesen,
      ]).startTimer(lesen.id, heute, uhr.jetzt);
      uhr.jetzt = uhr.jetzt.add(const Duration(minutes: 8));
      final c = container(gestartet, uhr);

      await zeige(tester, c, const HabitsScreen());

      expect(find.text('12:00'), findsOneWidget);
    });
  });

  group('Heute auf der Startseite', () {
    Finder inDerKarte(Finder finder) {
      return find.descendant(of: find.byType(TodayCard), matching: finder);
    }

    testWidgets(
      'die Startvorlage zeigt ihre zwei Minuten und öffnet den Timer',
      (tester) async {
        final uhr = _Uhr();
        final tracker = const HabitTracker.empty().activate(
          starter.id,
          today: heute,
        );
        final c = container(tracker, uhr);
        await zeige(tester, c, const HomeScreen());

        expect(inDerKarte(find.text('02:00')), findsOneWidget);

        await tester.tap(inDerKarte(find.text(starter.name)));
        await tester.pumpAndSettle();

        expect(find.byType(HabitTimerSheet), findsOneWidget);
        expect(
          c.read(habitTrackerProvider).isChecked(starter.id, heute),
          isFalse,
        );
      },
    );

    testWidgets('läuft er, zählt die Zeile mit und hakt bei null ab', (
      tester,
    ) async {
      final uhr = _Uhr();
      final tracker = const HabitTracker.empty()
          .activate(starter.id, today: heute)
          .startTimer(starter.id, heute, uhr.jetzt);
      final c = container(tracker, uhr);
      await zeige(tester, c, const HomeScreen());

      await warte(tester, uhr, const Duration(seconds: 45));
      expect(inDerKarte(find.text('01:15')), findsOneWidget);

      await warte(tester, uhr, const Duration(seconds: 75));
      await tester.pumpAndSettle();

      expect(c.read(habitTrackerProvider).isChecked(starter.id, heute), isTrue);
    });

    testWidgets('ohne Zeitziel steht keine Restzeit da', (tester) async {
      final uhr = _Uhr();
      final c = container(mit(<CustomHabit>[wasser]), uhr);
      await zeige(tester, c, const HomeScreen());

      expect(inDerKarte(find.byIcon(Icons.timer_outlined)), findsNothing);
    });
  });
}

/// Eine Uhr, die der Test stellt.
class _Uhr {
  DateTime jetzt = DateTime(2026, 10, 4, 8);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/widgets/daily_chest_card.dart';
import 'package:lifes_game/habits/widgets/week_card.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/lagerfeuer/am_feuer.dart';
import 'package:lifes_game/lagerfeuer/am_feuer_provider.dart';
import 'package:lifes_game/lagerfeuer/lagerfeuer_screen.dart';
import 'package:lifes_game/lagerfeuer/widgets/lagerfeuer_karte.dart';
import 'package:lifes_game/lagerfeuer/widgets/morgen_zuerst.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Das Lagerfeuer (ADR-0076): Der Tag endet an einer Stelle.
void main() {
  // Ein Dienstag — kein Tag des Wochenrückblicks.
  final dienstag = DateTime(2026, 10, 20, 10);
  final abends = DateTime(2026, 10, 20, 19);
  final a = HabitCatalog.all[0];
  final b = HabitCatalog.all[1];

  HabitTracker zwei() =>
      const HabitTracker.empty().activate(a.id).activate(b.id);

  ProviderContainer container(HabitTracker tracker, DateTime jetzt) {
    final c = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        clockProvider.overrideWithValue(() => jetzt),
        ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
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

  group('Wann es brennt', () {
    test('ab sechs Uhr abends, auch wenn noch etwas offen ist', () {
      expect(
        AmFeuer.brenntUm(DateTime(2026, 10, 20, 17, 59), tagGeschafft: false),
        isFalse,
      );
      expect(
        AmFeuer.brenntUm(DateTime(2026, 10, 20, 18), tagGeschafft: false),
        isTrue,
      );
    });

    test('morgens, sobald der Tag geschafft ist', () {
      expect(
        AmFeuer.brenntUm(DateTime(2026, 10, 20, 8), tagGeschafft: true),
        isTrue,
      );
    });

    testWidgets('vorher glimmt es nur — offen ist es trotzdem', (tester) async {
      await zeige(
        tester,
        container(zwei(), dienstag),
        const LagerfeuerScreen(),
      );
      expect(find.bySemanticsLabel('Das Feuer glimmt'), findsOneWidget);
      expect(find.text(LagerfeuerScreen.schluss), findsOneWidget);

      await zeige(tester, container(zwei(), abends), const LagerfeuerScreen());
      expect(find.bySemanticsLabel('Das Feuer brennt'), findsOneWidget);
    });
  });

  group('Was wartet', () {
    test('Rückfrage, Truhe und abholbare Aufgaben zählen, sonst nichts', () {
      const amFeuer = AmFeuer(
        brennt: true,
        rueckfrageOffen: true,
        truheWartet: true,
        aufgabenAbholbar: 2,
      );
      expect(amFeuer.wartet, 4);
    });

    testWidgets('die Startseite zeigt es am Feuer, und ein Tipp führt hin', (
      tester,
    ) async {
      final heute = Day.from(dienstag);
      final erledigt = zwei()
          .check(a.id, heute)
          .tracker
          .check(b.id, heute)
          .tracker;
      final c = container(erledigt, dienstag);
      final wartet = c.read(amFeuerProvider).wartet;
      expect(c.read(amFeuerProvider).truheWartet, isTrue);

      await zeige(tester, c, const HomeScreen());
      expect(find.byKey(DailyChestCard.oeffnenKey), findsNothing);
      expect(
        find.bySemanticsLabel('Lagerfeuer, $wartet warten'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(LagerfeuerKarte.oeffnenKey));
      await tester.pumpAndSettle();

      expect(find.byType(LagerfeuerScreen), findsOneWidget);
      expect(find.byKey(DailyChestCard.oeffnenKey), findsOneWidget);
    });

    testWidgets('der Wochenrückblick steht sonntags am Feuer, dienstags '
        'nicht', (tester) async {
      await zeige(
        tester,
        container(zwei(), dienstag),
        const LagerfeuerScreen(),
      );
      expect(find.byType(WeekCard), findsNothing);

      final sonntag = DateTime(2026, 10, 18, 20);
      await zeige(tester, container(zwei(), sonntag), const LagerfeuerScreen());
      expect(find.byType(WeekCard), findsOneWidget);
    });
  });

  group('Morgen zuerst', () {
    testWidgets('ein Tipp wählt, ein zweiter nimmt zurück', (tester) async {
      final c = container(zwei(), abends);
      final morgen = Day.from(abends).next;
      await zeige(tester, c, const LagerfeuerScreen());

      await tester.tap(find.byKey(MorgenZuerst.knopfKey(b.id)));
      await tester.pumpAndSettle();
      expect(c.read(habitTrackerProvider).firstUpOn(morgen), b.id);
      expect(find.bySemanticsLabel('${b.name}, morgen zuerst'), findsOneWidget);

      await tester.tap(find.byKey(MorgenZuerst.knopfKey(b.id)));
      await tester.pumpAndSettle();
      expect(c.read(habitTrackerProvider).firstUpOn(morgen), isNull);
    });

    testWidgets('am Morgen steht sie oben in „Heute“, mit Flamme', (
      tester,
    ) async {
      final morgen = Day.from(dienstag).next;
      final tracker = zwei().setFirstUp(morgen, b.id);
      final c = container(tracker, DateTime(2026, 10, 21, 7));
      await zeige(tester, c, const HomeScreen());

      final namen = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(TodayCard),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .where((t) => t == a.name || t == b.name)
          .toList();
      expect(namen, <String>[b.name, a.name]);
      expect(find.byKey(TodayCard.flammeKey), findsOneWidget);
    });

    testWidgets('an einem Ruhetag morgen steht dort nur das Wort', (
      tester,
    ) async {
      // Nur dienstags fällig: Mittwoch ist Ruhetag.
      final tracker = const HabitTracker.empty().activate(a.id).setWeekdays(
        a.id,
        const <int>{DateTime.tuesday},
        today: Day.from(dienstag),
      );
      await zeige(tester, container(tracker, abends), const LagerfeuerScreen());
      expect(find.text('Ruhetag'), findsOneWidget);
      expect(find.byKey(MorgenZuerst.knopfKey(a.id)), findsNothing);
    });
  });
}

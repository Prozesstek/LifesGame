import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/habits/habits_screen.dart';
import 'package:lifes_game/habits/widgets/daily_chest_card.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/today_card.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// „Heute" auf der Startseite (ADR-0053).
///
/// Der wichtigste Test ist der zweite: Ein Tipp auf der Startseite hakt
/// **wirklich** ab — über denselben Weg wie der Gewohnheiten-Bildschirm,
/// nicht über einen zweiten.
void main() {
  const heute = Day(2026, 9, 27);
  final starter = HabitCatalog.starter;
  final zweite = HabitCatalog.all.firstWhere((t) => t.id != starter.id);

  Future<ProviderContainer> startseite(
    WidgetTester tester,
    HabitTracker tracker, {
    bool allesOffen = false,
  }) async {
    useTallView(tester);
    final container = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(SaveData(habits: tracker)),
        todayProvider.overrideWithValue(heute),
        if (allesOffen)
          ersterStartProvider.overrideWithValue(ErsterStart.allesOffen),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  Finder inDerKarte(Finder finder) {
    return find.descendant(of: find.byType(TodayCard), matching: finder);
  }

  testWidgets('zeigt die offenen Gewohnheiten samt Auslöser', (tester) async {
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .activate(zweite.id)
        .setCue(starter.id, 'Nach dem Zähneputzen');
    await startseite(tester, tracker);

    expect(inDerKarte(find.byIcon(Icons.checklist_rounded)), findsOneWidget);
    expect(inDerKarte(find.text('0 / 2')), findsOneWidget);
    expect(inDerKarte(find.text(starter.name)), findsOneWidget);
    expect(inDerKarte(find.text(zweite.name)), findsOneWidget);
    expect(inDerKarte(find.text('Nach dem Zähneputzen')), findsOneWidget);
  });

  testWidgets('ein Tipp hakt ab, und die Zeile bleibt als erledigt stehen', (
    tester,
  ) async {
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .activate(zweite.id);
    final container = await startseite(tester, tracker);

    await tester.tap(inDerKarte(find.text(starter.name)));
    await tester.pump();
    await schonErledigt(tester);

    expect(
      container.read(habitTrackerProvider).isChecked(starter.id, heute),
      isTrue,
    );
    expect(inDerKarte(find.text(starter.name)), findsOneWidget);
    expect(inDerKarte(find.byIcon(Icons.check_circle)), findsOneWidget);
    expect(inDerKarte(find.text('1 / 2')), findsOneWidget);

    // Die Feier zum ersten Häkchen liegt jetzt über der Karte.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Noch ein Tipp nimmt das Häkchen zurück.
    await tester.tap(inDerKarte(find.text(starter.name)));
    await tester.pump();
    expect(
      container.read(habitTrackerProvider).isChecked(starter.id, heute),
      isFalse,
    );
  });

  testWidgets('alles erledigt: alle stehen noch da, die Truhe darunter', (
    tester,
  ) async {
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .activate(zweite.id)
        .check(starter.id, heute)
        .tracker
        .check(zweite.id, heute)
        .tracker;
    await startseite(tester, tracker);

    expect(inDerKarte(find.text(starter.name)), findsOneWidget);
    expect(inDerKarte(find.text(zweite.name)), findsOneWidget);
    expect(inDerKarte(find.byIcon(Icons.check_circle)), findsNWidgets(2));
    expect(inDerKarte(find.text('2 / 2')), findsOneWidget);
    expect(find.byKey(DailyChestCard.oeffnenKey), findsOneWidget);
  });

  testWidgets('auch nach der Truhe bleibt die Liste stehen', (tester) async {
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .check(starter.id, heute)
        .tracker
        .openChest(heute)
        .tracker;
    await startseite(tester, tracker);

    expect(inDerKarte(find.byIcon(Icons.check_circle)), findsOneWidget);
  });

  testWidgets('die Truhe steht auf der Startseite und geht dort auf', (
    tester,
  ) async {
    final offen = const HabitTracker.empty().activate(starter.id);
    await startseite(tester, offen);
    expect(find.byType(DailyChestCard), findsNothing);

    final erledigt = offen.check(starter.id, heute).tracker;
    final container = await startseite(tester, erledigt);
    await tester.tap(find.byKey(DailyChestCard.oeffnenKey));
    await tester.pumpAndSettle();

    expect(container.read(habitTrackerProvider).hasOpenedChest(heute), isTrue);
    await tester.tap(find.byKey(DailyChestCard.einsackenKey));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyChestCard.oeffnenKey), findsNothing);
    expect(find.byType(DailyChestCard), findsOneWidget);
  });

  testWidgets('ohne Gewohnheit führt sie zum Starten', (tester) async {
    // Ein Stand, der weiter ist, aber gerade nichts laufen hat. Ein
    // frischer bekommt statt dieser Karte die erste Frage (ADR-0068,
    // `erster_start_test.dart`).
    await startseite(tester, const HabitTracker.empty(), allesOffen: true);

    await tester.tap(
      inDerKarte(find.bySemanticsLabel('Erste Gewohnheit starten')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HabitsScreen), findsOneWidget);
  });

  testWidgets('die Flamme zeigt die Tageskette', (tester) async {
    // Zwei Gewohnheiten im Wechsel: Keine hat eine Kette über einen Tag,
    // die Tageskette steht trotzdem auf drei (ADR-0055).
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .activate(zweite.id)
        .check(starter.id, heute.previous.previous)
        .tracker
        .check(zweite.id, heute.previous)
        .tracker
        .check(starter.id, heute)
        .tracker;
    await startseite(tester, tracker);

    expect(
      inDerKarte(find.byIcon(Icons.local_fire_department_rounded)),
      findsOneWidget,
    );
    expect(inDerKarte(find.text('3')), findsOneWidget);
  });

  testWidgets('ohne Kette keine Flamme', (tester) async {
    await startseite(tester, const HabitTracker.empty().activate(starter.id));

    expect(
      inDerKarte(find.byIcon(Icons.local_fire_department_rounded)),
      findsNothing,
    );
  });

  testWidgets('der Kopf führt zum Gewohnheiten-Bildschirm', (tester) async {
    await startseite(tester, const HabitTracker.empty().activate(starter.id));

    await tester.tap(inDerKarte(find.byIcon(Icons.checklist_rounded)));
    await tester.pumpAndSettle();

    expect(find.byType(HabitsScreen), findsOneWidget);
  });
}

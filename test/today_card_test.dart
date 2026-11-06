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
import 'package:lifes_game/lagerfeuer/widgets/lagerfeuer_karte.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:lifes_game/ui/anschlagtafel.dart';

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

    // Auf dem Schild steht kein Zähler mehr (06.11.2026).
    expect(inDerKarte(find.byIcon(Icons.checklist_rounded)), findsNothing);
    expect(inDerKarte(find.text('0 / 2')), findsNothing);
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

  testWidgets('alles erledigt: alle stehen noch da, darunter das Feuer', (
    tester,
  ) async {
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .activate(zweite.id)
        .check(starter.id, heute)
        .tracker
        .check(zweite.id, heute)
        .tracker;
    await startseite(tester, tracker, allesOffen: true);

    expect(inDerKarte(find.text(starter.name)), findsOneWidget);
    expect(inDerKarte(find.text(zweite.name)), findsOneWidget);
    expect(inDerKarte(find.byIcon(Icons.check_circle)), findsNWidgets(2));
    // Die Truhe wartet am Lagerfeuer (ADR-0076), das Feuer sagt es.
    expect(find.byKey(DailyChestCard.oeffnenKey), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'^Lagerfeuer, \d+ wart')),
      findsOneWidget,
    );
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

  testWidgets('die Truhe wartet am Lagerfeuer und geht dort auf', (
    tester,
  ) async {
    final offen = const HabitTracker.empty().activate(starter.id);
    await startseite(tester, offen);
    expect(find.byType(LagerfeuerKarte), findsNothing);

    final erledigt = offen.check(starter.id, heute).tracker;
    final container = await startseite(tester, erledigt, allesOffen: true);
    await tester.tap(find.byKey(LagerfeuerKarte.oeffnenKey));
    await tester.pumpAndSettle();
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

  testWidgets('ohne Kette keine Flamme', (tester) async {
    await startseite(tester, const HabitTracker.empty().activate(starter.id));

    expect(
      inDerKarte(find.byIcon(Icons.local_fire_department_rounded)),
      findsNothing,
    );
  });

  testWidgets('die Tafel hat kein Schild mehr (06.11.2026)', (tester) async {
    // Zu den Gewohnheiten führt ihr Kreis; mit dem Schild gingen Pfeil,
    // Zähler und die kleine Flamme der Tageskette.
    final tracker = const HabitTracker.empty()
        .activate(starter.id)
        .check(starter.id, heute.previous)
        .tracker
        .check(starter.id, heute)
        .tracker;
    await startseite(tester, tracker);

    expect(inDerKarte(find.byIcon(Icons.chevron_right_rounded)), findsNothing);
    expect(
      inDerKarte(find.byIcon(Icons.local_fire_department_rounded)),
      findsNothing,
    );
  });

  testWidgets('abgehakt schlägt ein Stempel auf den Zettel', (tester) async {
    // Die Tafel (23.10.): Der Zettel wandert nach dem Häkchen nach unten
    // und behält dabei seinen Zustand — sonst läge der Stempel sofort da.
    await startseite(
      tester,
      const HabitTracker.empty().activate(starter.id).activate(zweite.id),
    );
    final stempel = inDerKarte(find.byKey(Steckbrief.stempelKey));
    double deckung() => tester
        .widget<Opacity>(
          find.ancestor(of: stempel, matching: find.byType(Opacity)).first,
        )
        .opacity;
    expect(stempel, findsNothing);

    await tester.tap(inDerKarte(find.text(zweite.name)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(stempel, findsOneWidget);
    expect(deckung(), lessThan(1));

    await tester.pumpAndSettle();
    expect(deckung(), 1);
  });
}

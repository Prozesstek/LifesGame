import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/habits/habits_controller.dart';
import 'package:lifes_game/home/erster_start.dart';
import 'package:lifes_game/home/erster_start_provider.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/mentor/scheinwerfer.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';
import 'package:theory/theory.dart';

import 'test_view.dart';
import 'tutorial_helfer.dart';

/// Der Scheinwerfer, der gelbe Punkt und die untere Leiste, die erst mit
/// ihrem ersten Kreis kommt (ADR-0095).
void main() {
  const heute = Day(2026, 10, 20);

  Future<void> starte(
    WidgetTester tester, {
    SaveData stand = const SaveData.empty(),
    bool allesOffen = false,
  }) async {
    useTallView(tester);
    final container = ProviderContainer(
      overrides: [
        savedGameProvider.overrideWithValue(stand),
        todayProvider.overrideWithValue(heute),
        hinweisGesehen,
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
    await tester.pumpAndSettle();
  }

  final einHaekchen = const HabitTracker.empty()
      .activate(HabitCatalog.starterId)
      .check(HabitCatalog.starterId, heute)
      .tracker;

  SaveData ersteSeiteGelesen() {
    final erste = theoryGraph.nodeById(theoryBasicsPath.first)!;
    final theorie = const TheoryProgress.empty().openNode(erste.id).submit(
      erste.lesson,
      <int?>[for (final q in erste.lesson.questions) q.correctIndex],
    ).progress;
    return SaveData(habits: einHaekchen, theory: theorie);
  }

  double leistenHoehe(WidgetTester tester) =>
      tester.getSize(find.byKey(EinblendLeiste.leisteKey)).height;

  double leistenDeckkraft(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find
            .descendant(
              of: find.byKey(EinblendLeiste.leisteKey),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      )
      .opacity;

  group('Der Scheinwerfer', () {
    testWidgets('liegt über allem, wenn der Mentor auf etwas zeigt', (
      tester,
    ) async {
      await starte(tester);

      expect(find.byKey(Scheinwerfer.schleierKey), findsOneWidget);
    });

    testWidgets('fehlt, wenn der Weg gegangen ist', (tester) async {
      await starte(tester, allesOffen: true);

      expect(find.byKey(Scheinwerfer.schleierKey), findsNothing);
    });

    testWidgets('sperrt nichts: was im Dunkeln liegt, lässt sich tippen', (
      tester,
    ) async {
      // Beim Schritt „erste Seite“ liegt nur die Theorie im Licht.
      await starte(tester, stand: SaveData(habits: einHaekchen));

      expect(find.byKey(Scheinwerfer.schleierKey), findsOneWidget);
      expect(
        find.byKey(HubCircle.keyFor('Gewohnheiten')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('der nächste Kreis trägt den gelben Punkt', (tester) async {
      await starte(tester, stand: SaveData(habits: einHaekchen));

      expect(find.byKey(HubCircle.leuchtKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(HubCircle.keyFor('Theorie')),
          matching: find.byType(ZielPunkt),
        ),
        findsOneWidget,
      );
    });
  });

  group('Die untere Leiste', () {
    testWidgets('fehlt, solange keiner ihrer Kreise da ist — ihr Platz '
        'steht trotzdem (08.11.2026)', (tester) async {
      await starte(tester);

      // Unsichtbar, aber nicht ohne Höhe: Wüchse sie beim Erscheinen,
      // rutschte alles darüber mit.
      expect(leistenDeckkraft(tester), 0);
      expect(leistenHoehe(tester), greaterThan(40));
      expect(find.byKey(HubCircle.keyFor('Laden')).hitTestable(), findsNothing);
    });

    testWidgets('blendet ein mit dem ersten Kreis', (tester) async {
      // Die erste Seite bringt Funkenstoß — und damit die Fähigkeiten.
      await starte(tester, stand: ersteSeiteGelesen());

      expect(leistenDeckkraft(tester), 1);
      expect(
        find.byKey(HubCircle.keyFor('Fähigkeiten')).hitTestable(),
        findsOneWidget,
      );
    });
  });

  testWidgets('bewegt sich ein Ziel, wandert das Licht mit (08.11.2026)', (
    tester,
  ) async {
    // Die untere Leiste fährt herein, nachdem der Schleier steht — sein
    // Loch blieb an der alten Stelle, und der Kreis stand im Dunkeln.
    useTallView(tester);
    final unten = ValueNotifier<double>(0);
    addTearDown(unten.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scheinwerfer(
          child: ValueListenableBuilder<double>(
            valueListenable: unten,
            builder: (_, abstand, _) => AnimatedPadding(
              duration: const Duration(milliseconds: 600),
              padding: EdgeInsets.only(top: abstand),
              child: const Align(
                alignment: Alignment.topLeft,
                child: ScheinwerferZiel(child: SizedBox(width: 40, height: 40)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final state = tester.state<State<Scheinwerfer>>(find.byType(Scheinwerfer));
    expect(Scheinwerfer.lichtVon(state).single.center.dy, closeTo(20, 1));

    unten.value = 500;
    await tester.pumpAndSettle();

    expect(Scheinwerfer.lichtVon(state).single.center.dy, closeTo(520, 1));
  });
}

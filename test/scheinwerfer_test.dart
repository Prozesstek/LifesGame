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
    testWidgets('fehlt, solange keiner ihrer Kreise da ist', (tester) async {
      await starte(tester);

      expect(leistenHoehe(tester), 0);
      expect(find.byKey(HubCircle.keyFor('Laden')).hitTestable(), findsNothing);
    });

    testWidgets('fährt herein mit dem ersten Kreis', (tester) async {
      // Die erste Seite bringt Funkenstoß — und damit die Fähigkeiten.
      await starte(tester, stand: ersteSeiteGelesen());

      expect(leistenHoehe(tester), greaterThan(40));
      expect(
        find.byKey(HubCircle.keyFor('Fähigkeiten')).hitTestable(),
        findsOneWidget,
      );
    });
  });
}

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/pit_run_view.dart';
import 'package:lifes_game/action/pit_screen.dart';
import 'package:lifes_game/combat/ladder_controller.dart';
import 'package:lifes_game/combat/widgets/lauf_ergebnis.dart';
import 'package:lifes_game/save/save_data.dart';
import 'package:lifes_game/save/save_providers.dart';

import 'test_view.dart';

/// Wer einen Lauf in der Grube verlässt, wird gefragt.
///
/// **Auf Android ist „Zurück“ eine Geste vom Bildschirmrand**, und das
/// Steuerkreuz nimmt den ganzen Bildschirm ein. Ohne Rückfrage beendete
/// ein Daumen, der zu weit links ansetzt, den Lauf — im Browser fiel das
/// nie auf.
void main() {
  const darunter = ValueKey<String>('darunter');

  /// Eine Seite unter der Grube, damit „Zurück“ irgendwohin führt.
  Future<ProviderContainer> hinab(WidgetTester tester) async {
    usePhoneView(tester);
    final container = ProviderContainer(
      overrides: [savedGameProvider.overrideWithValue(const SaveData())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              key: darunter,
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PitScreen(stage: PitStage(1)),
                  ),
                ),
                child: const Text('Hinab'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hinab'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PitScreen), findsOneWidget);
    return container;
  }

  ActionGame spielVon(WidgetTester tester) =>
      tester.widget<PitRunView>(find.byType(PitRunView)).game;

  Future<void> zurueck(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('„Zurück“ mitten im Lauf fragt und hält den Lauf an', (
    tester,
  ) async {
    await hinab(tester);

    await zurueck(tester);

    expect(find.byKey(PitScreen.abbrechenKey), findsOneWidget);
    expect(find.byType(PitScreen), findsOneWidget);
    expect(spielVon(tester).paused, isTrue);
  });

  testWidgets('wer weiterkämpft, bleibt, und der Lauf geht weiter', (
    tester,
  ) async {
    await hinab(tester);
    await zurueck(tester);

    await tester.tap(find.byKey(PitScreen.bleibenKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PitScreen), findsOneWidget);
    expect(spielVon(tester).paused, isFalse);
  });

  testWidgets('wer abbricht, geht — und gebucht wird nichts', (tester) async {
    final c = await hinab(tester);
    final vorher = c.read(ladderProvider);
    await zurueck(tester);

    await tester.tap(find.byKey(PitScreen.abbrechenKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PitScreen), findsNothing);
    expect(find.byKey(darunter), findsOneWidget);
    expect(c.read(ladderProvider), same(vorher));
  });

  testWidgets('nach einer Niederlage geht „Zurück“ ohne Frage', (tester) async {
    await hinab(tester);
    final game = spielVon(tester);
    for (var i = 0; i < 20000 && !game.sim.isOver; i++) {
      game.update(0.05);
    }
    expect(game.sim.isWon, isFalse);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byKey(LaufErgebnis.weiterKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await zurueck(tester);

    expect(find.byKey(PitScreen.abbrechenKey), findsNothing);
    expect(find.byType(PitScreen), findsNothing);
  });
}

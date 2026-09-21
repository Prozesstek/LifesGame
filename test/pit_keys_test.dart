import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/pit_run_view.dart';

/// Auf dem Rechner liegen die Fähigkeiten auf der Zahlenreihe: 1–3 die
/// Plätze.
void main() {
  /// Ein Lauf mit drei Plätzen, die kein Ziel brauchen — so wirkt jede
  /// Taste sofort, egal wo die Gegner stehen.
  ActionGame lauf() {
    return ActionGame(
      sim: ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.gereift,
        abilityIds: const <String>['steinhaut', 'bluetentau', 'aurastrom'],
      ),
    );
  }

  Future<ActionGame> zeige(WidgetTester tester) async {
    final game = lauf();
    addTearDown(game.frame.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PitRunView(game: game)),
      ),
    );
    await tester.pump();
    return game;
  }

  testWidgets('1, 2 und 3 wirken die drei Plätze in ihrer Reihenfolge', (
    tester,
  ) async {
    final game = await zeige(tester);

    for (final (taste, id) in <(LogicalKeyboardKey, String)>[
      (LogicalKeyboardKey.digit1, 'steinhaut'),
      (LogicalKeyboardKey.digit2, 'bluetentau'),
      (LogicalKeyboardKey.digit3, 'aurastrom'),
    ]) {
      expect(game.sim.slotCooldownRatio(id), 0, reason: id);
      await tester.sendKeyEvent(taste);
      expect(game.sim.slotCooldownRatio(id), greaterThan(0), reason: id);
    }
  });

  testWidgets('4, Leertaste und Umschalt tun nichts mehr', (tester) async {
    // Sturmschritt und Rundumschlag sind entfernt; nichts darf still an
    // ihre Stelle treten.
    final game = await zeige(tester);
    final vorher = game.sim.mana;

    for (final taste in <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.shiftLeft,
    ]) {
      await tester.sendKeyEvent(taste);
    }

    for (final id in <String>['steinhaut', 'bluetentau', 'aurastrom']) {
      expect(game.sim.slotCooldownRatio(id), 0, reason: id);
    }
    expect(game.sim.mana, vorher);
  });

  testWidgets('der Nummernblock tut dasselbe', (tester) async {
    final game = await zeige(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);

    expect(game.sim.slotCooldownRatio('steinhaut'), greaterThan(0));
  });
}

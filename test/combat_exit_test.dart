import 'package:combat/combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/combat/combat_controller.dart';
import 'package:lifes_game/combat/combat_screen.dart';
import 'package:lifes_game/combat/widgets/result_dialog.dart';
import 'package:lifes_game/combat/widgets/timing_bar.dart';

/// Wohin es nach dem Ergebnisblatt geht.
///
/// **Ein Sieg führt zurück zur Reihe.** Dort steht schon der nächste
/// Gegner. „Nochmal" hätte dagegen denselben Gegner neu aufgesetzt, den
/// man gerade geschlagen hat — und ein zweiter Sieg gegen ihn bringt
/// nichts ein (ADR-0032).
///
/// **Eine Niederlage bleibt im Kampf.** Dort ist „Nochmal" genau der
/// richtige nächste Schritt.
void main() {
  /// Ein Gegner, der beim ersten Treffer fällt.
  const strohpuppe = EnemyBlueprint(
    id: 'test-strohpuppe',
    name: 'Strohpuppe',
    maxHp: 1,
    attack: 0,
    defense: 0,
    maxEnergy: 0,
  );

  /// Ein Gegner, den niemand übersteht und der selbst nicht fällt.
  const uebermacht = EnemyBlueprint(
    id: 'test-uebermacht',
    name: 'Übermacht',
    maxHp: 99999,
    attack: 9999,
    defense: 9999,
    maxEnergy: 0,
  );

  /// Die Reihe als leerer Grund, von dem aus der Kampf geöffnet wird.
  Future<ProviderContainer> oeffneKampf(
    WidgetTester tester,
    EnemyBlueprint gegner,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(selectedEnemyProvider.notifier).select(gegner);
    container.read(combatControllerProvider.notifier).restart();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CombatScreen(),
                    ),
                  ),
                  child: const Text('Zur Reihe'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Zur Reihe'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  /// Eine Runde mit dem Waffenzug, bis das Ergebnisblatt aufgeht.
  Future<void> spieleBisZumBlatt(WidgetTester tester) async {
    // Getippt wird die Kachel; der Name darüber ist kein Knopf.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(Moves.basicAttack.name),
          matching: find.byType(Tooltip),
        ),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pump();
    // Die Tippfläche liegt über der Leiste und fängt den Tipp ab — genau
    // so ist es gewollt (`combat_test.dart`, „Tippen im Zeitfenster").
    await tester.tap(find.byType(TimingBar), warnIfMissed: false);
    await tester.pump();

    // Die Runde wird abgespielt; das Blatt kommt erst danach. Kein
    // `pumpAndSettle` — Flame rendert dauerhaft (`gotchas.md`).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(CombatResultDialog).evaluate().isNotEmpty) break;
    }
    expect(find.byType(CombatResultDialog), findsOneWidget);
  }

  testWidgets('nach einem Sieg geht es zurück zur Reihe', (tester) async {
    await oeffneKampf(tester, strohpuppe);
    await spieleBisZumBlatt(tester);

    expect(find.text('Gewonnen'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // **Erst die Feier, dann zurück.** Der erste Sieg verdient eine
    // Errungenschaft; ihr Blatt steht über dem Kampf und will weggetippt
    // werden. Zurück zur Reihe geht es erst danach — sonst verschwände
    // die Feier mit dem Bildschirm, auf dem sie steht.
    expect(find.text('Weiter'), findsWidgets);
    while (find.text('Weiter').evaluate().isNotEmpty) {
      expect(find.byType(CombatScreen), findsOneWidget);
      await tester.tap(find.text('Weiter').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(CombatScreen), findsNothing);
    expect(find.text('Zur Reihe'), findsOneWidget);
  });

  testWidgets('nach einer Niederlage bleibt der Kampf mit „Nochmal"', (
    tester,
  ) async {
    await oeffneKampf(tester, uebermacht);
    await spieleBisZumBlatt(tester);

    expect(find.text('Verloren'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    while (find.text('Weiter').evaluate().isNotEmpty) {
      await tester.tap(find.text('Weiter').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(CombatScreen), findsOneWidget);
    expect(find.text('Nochmal'), findsOneWidget);
  });
}

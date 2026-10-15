import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/ability_buttons.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/audio/sound_effects.dart';

/// Was ein Knopf beim Abklingen zeigt: Tortenstück, ausgegrautes Bild,
/// Sekunden in der Mitte und ein Glanz, wenn sie zurück ist.
void main() {
  group('AbklingAnzeige.zahl', () {
    test('bereit heisst keine Zahl', () {
      expect(AbklingAnzeige.zahl(0), isNull);
      expect(AbklingAnzeige.zahl(-0.1), isNull);
    });

    test('ab einer Sekunde ganze Sekunden, aufgerundet', () {
      expect(AbklingAnzeige.zahl(5), '5');
      expect(AbklingAnzeige.zahl(4.01), '5');
      expect(AbklingAnzeige.zahl(1), '1');
    });

    test('darunter eine Stelle mit Komma, nie „0,0“', () {
      expect(AbklingAnzeige.zahl(0.99), '0,9');
      expect(AbklingAnzeige.zahl(0.41), '0,5');
      expect(AbklingAnzeige.zahl(0.001), '0,1');
    });
  });

  group('AbklingAnzeige.glanz', () {
    test('ohne Rückkehr kein Glanz', () {
      expect(AbklingAnzeige.glanz(zurueckBei: null, jetzt: 3), 0);
    });

    test('voll im Augenblick der Rückkehr, danach weg', () {
      expect(AbklingAnzeige.glanz(zurueckBei: 2, jetzt: 2), 1);
      final mitte = AbklingAnzeige.glanz(
        zurueckBei: 2,
        jetzt: 2 + AbklingAnzeige.glanzSekunden / 2,
      );
      expect(mitte, closeTo(0.5, 1e-9));
      expect(
        AbklingAnzeige.glanz(
          zurueckBei: 2,
          jetzt: 2 + AbklingAnzeige.glanzSekunden,
        ),
        0,
      );
    });
  });

  testWidgets('der Knopf zählt herunter, graut aus und leuchtet zurück', (
    tester,
  ) async {
    final game = ActionGame(
      klang: const SilentSoundPlayer(),
      sim: ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.gereift,
        abilityIds: const <String>['steinhaut'],
      ),
    );
    addTearDown(game.frame.dispose);
    final welt = game.sim;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: game.frame,
              builder: (_, _, _) => AbilityButtons(game: game),
            ),
          ),
        ),
      ),
    );

    Future<void> neuBauen() async {
      game.frame.value++;
      await tester.pump();
    }

    expect(find.byKey(const Key('abklingzahl')), findsNothing);
    expect(find.byType(ColorFiltered), findsNothing);

    expect(welt.cast('steinhaut'), isTrue);
    await neuBauen();

    final zahl = AbklingAnzeige.zahl(welt.slotCooldownLeft('steinhaut'))!;
    expect(find.text(zahl), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget, reason: 'ausgegraut');

    // Bis kurz vor dem Ende: Die Zahl wird kleiner.
    while (welt.slotCooldownLeft('steinhaut') > 1.2) {
      welt.step(Vec2.zero);
    }
    await neuBauen();
    expect(find.text('2'), findsOneWidget);

    // Zurück: keine Zahl, kein Grau, dafür Glanz.
    while (welt.slotCooldownRatio('steinhaut') > 0) {
      welt.step(Vec2.zero);
    }
    await neuBauen();
    expect(find.byKey(const Key('abklingzahl')), findsNothing);
    expect(find.byType(ColorFiltered), findsNothing);
    expect(_glanz(tester), greaterThan(0.9));

    // Der Glanz läuft in der Zeit des Laufs aus.
    final bis = welt.elapsed + AbklingAnzeige.glanzSekunden + 0.05;
    while (welt.elapsed < bis) {
      welt.step(Vec2.zero);
    }
    await neuBauen();
    expect(_glanz(tester), 0);
  });
}

/// Wie stark der Knopf gerade leuchtet — aus dem Maler gelesen.
double _glanz(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.foregroundPainter)
      .whereType<AbklingSchatten>()
      .single
      .glanz;
}

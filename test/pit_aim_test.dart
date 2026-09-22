import 'package:action_combat/action_combat.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/pit_run_view.dart';

/// Kurz tippen zielt selbst, halten und ziehen zielt von Hand — am Knopf
/// mit dem Daumen, am Rechner mit Taste und Maus.
void main() {
  /// Ein offener Saal: ein Gegner rechts vom Helden, in Reichweite des
  /// Funkens, der Wächter ganz hinten.
  final saal = Level.parse('Saal', const <String>[
    '##############################',
    '#............................#',
    '#............................#',
    '#...@.....e..................#',
    '#............................#',
    '#............................#',
    '#...........................B#',
    '##############################',
  ]);

  Future<ActionGame> zeige(WidgetTester tester, List<String> plaetze) async {
    final game = ActionGame(
      sim: ActionWorld(
        level: saal,
        heroStats: ActionStats.gereift,
        abilityIds: plaetze,
      ),
    );
    addTearDown(game.frame.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PitRunView(game: game)),
      ),
    );
    await tester.pump();
    return game;
  }

  Offset knopf(WidgetTester tester, String name) {
    return tester.getCenter(find.bySemanticsLabel(name));
  }

  testWidgets('gezogen fliegt der Funke dorthin, wohin gezogen wurde', (
    tester,
  ) async {
    final game = await zeige(tester, const <String>['funkenstoss']);
    final von = knopf(tester, 'Funkenstoß');

    final finger = await tester.startGesture(von);
    expect(game.aimingId, 'funkenstoss');
    // Nach oben gezogen — der Gegner steht rechts.
    await finger.moveTo(von + const Offset(0, -60));
    expect(game.sim.aimPreview('funkenstoss', null), isA<AimLine>());
    await finger.up();

    expect(game.aimingId, isNull);
    expect(game.sim.slotCooldownRatio('funkenstoss'), greaterThan(0));
    final funke = game.sim.projectiles.single;
    expect(funke.direction.y, lessThan(-0.99));
  });

  testWidgets('kurz getippt zielt er selbst auf den Gegner', (tester) async {
    final game = await zeige(tester, const <String>['funkenstoss']);

    await tester.tapAt(knopf(tester, 'Funkenstoß'));

    final funke = game.sim.projectiles.single;
    expect(funke.direction.x, greaterThan(0.99));
  });

  testWidgets('Heilung wirkt schon beim Drücken', (tester) async {
    final game = await zeige(tester, const <String>['bluetentau']);

    final finger = await tester.startGesture(knopf(tester, 'Blütentau'));
    expect(game.sim.slotCooldownRatio('bluetentau'), greaterThan(0));
    expect(game.aimingId, isNull, reason: 'Nichts zu zielen.');
    await finger.up();
  });

  testWidgets('am Rechner: Taste halten, Maus zielt, loslassen setzt ab', (
    tester,
  ) async {
    final game = await zeige(tester, const <String>['frostnebel']);
    final held = game.sim.heroView.position;
    // Ein Punkt unterhalb des Helden, im Bild.
    final ziel = held + const Vec2(0, 90);
    final kamera = game.screenToWorld(Offset.zero);
    final imBild = Offset(ziel.x - kamera.x, ziel.y - kamera.y);

    final maus = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await maus.addPointer(location: Offset.zero);
    addTearDown(maus.removePointer);
    await maus.moveTo(imBild);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
    expect(game.aimingId, 'frostnebel');
    final vorschau = game.sim.aimPreview('frostnebel', ziel)! as AimCircle;
    expect(vorschau.center.y, closeTo(ziel.y, 0.5));

    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
    expect(game.aimingId, isNull);
    final zone = game.sim.zones.single;
    expect(zone.center.x, closeTo(ziel.x, 0.5));
    expect(zone.center.y, closeTo(ziel.y, 0.5));
  });
}

import 'package:action_combat/action_combat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/action_game.dart';
import 'package:lifes_game/action/minimap.dart';
import 'package:lifes_game/action/pit_run_view.dart';

/// Die Karte oben links in der Grube.
void main() {
  group('Was gesehen ist', () {
    final gang = Level.parse('Gang', <String>[
      '#' * 40,
      '#@${'.' * 36}B#',
      '#' * 40,
    ]);
    Vec2 mitteVon(int x) =>
        Vec2((x + 0.5) * ActionBalance.tileSize, 1.5 * ActionBalance.tileSize);

    test('der Umkreis des Helden ist aufgedeckt, das Weite nicht', () {
      final fog = MinimapFog()..reveal(gang, mitteVon(1));
      expect(fog.isSeen(1, 1), isTrue);
      expect(fog.isSeen(1 + MinimapFog.revealTiles, 1), isTrue);
      expect(fog.isSeen(2 + MinimapFog.revealTiles, 1), isFalse);
      expect(fog.isSeen(30, 1), isFalse);
    });

    test('was einmal gesehen ist, bleibt gesehen', () {
      final fog = MinimapFog()
        ..reveal(gang, mitteVon(1))
        ..reveal(gang, mitteVon(30));
      expect(fog.isSeen(1, 1), isTrue);
      expect(fog.isSeen(30, 1), isTrue);
      expect(fog.isSeen(15, 1), isFalse);
    });

    test('ein Gegner erscheint nur in der Nähe', () {
      expect(MinimapFog.shows(mitteVon(1), mitteVon(4)), isTrue);
      expect(MinimapFog.shows(mitteVon(1), mitteVon(20)), isFalse);
    });
  });

  group('In der Grube', () {
    Future<ActionGame> zeige(WidgetTester tester) async {
      final game = ActionGame(
        sim: ActionWorld(
          level: LevelCatalog.grube,
          heroStats: ActionStats.gereift,
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

    testWidgets('sitzt oben links, die Balken rechts daneben', (tester) async {
      await zeige(tester);
      final karte = tester.getRect(find.byType(PitMinimap));
      final balken = tester.getRect(find.byType(PitBar).first);

      expect(karte.left, lessThan(20));
      expect(karte.top, lessThan(20));
      expect(karte.width, lessThanOrEqualTo(PitMinimap.maxSide + 10));
      expect(balken.left, greaterThan(karte.right));
    });

    testWidgets('beim Start ist der Eingang schon aufgedeckt', (tester) async {
      final game = await zeige(tester);
      expect(game.fog.seenCount, greaterThan(0));
    });
  });
}

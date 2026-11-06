import 'package:action_combat/action_combat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/action/fels_tiefe.dart';

void main() {
  // Ein Gang in der Mitte eines Felsblocks: Steine bekommt nur, was
  // höchstens zwei Felder vom Boden entfernt liegt.
  final level = Level.parse('Fels', const <String>[
    '#########',
    '#########',
    '#########',
    '###.@.###',
    '#########',
    '#########',
    '#########',
  ]);
  final tiefe = FelsTiefe.aus(level);

  test('die Wand am Boden bekommt Steine, zwei Felder breit', () {
    expect(tiefe.istTief(3, 2), isFalse, reason: 'direkt über dem Gang');
    expect(tiefe.istTief(3, 1), isFalse, reason: 'zweiter Stein');
    expect(tiefe.istTief(1, 3), isFalse, reason: 'zwei links vom Gang');
  });

  test('dahinter ist Fels ohne Stein', () {
    expect(tiefe.istTief(3, 0), isTrue);
    expect(tiefe.istTief(0, 3), isTrue);
    expect(tiefe.istTief(8, 6), isTrue);
  });

  test('Boden ist nie tief', () {
    expect(tiefe.istTief(4, 3), isFalse);
  });

  test('jede gebaute Grube behält ihren Rand', () {
    for (var seed = 0; seed < 20; seed++) {
      final grube = LevelBuilder.build(stage: PitStage(5), seed: seed);
      final fels = FelsTiefe.aus(grube);
      for (var y = 0; y < grube.height; y++) {
        for (var x = 0; x < grube.width; x++) {
          if (!fels.istTief(x, y)) continue;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              expect(
                grube.tileAt(x + dx, y + dy),
                Tile.wand,
                reason: 'Seed $seed: tiefer Fels bei ($x, $y) grenzt an Boden',
              );
            }
          }
        }
      }
    }
  });
}

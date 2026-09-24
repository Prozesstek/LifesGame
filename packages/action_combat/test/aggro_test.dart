import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Wann ein Gegner kommt: wenn er den Helden sieht, oder wenn er von ihm
/// getroffen wurde. Nah sein allein reicht nicht — sonst zieht der Radius
/// ganze Räume durch die Wand heran.
void main() {
  // Held links, Fussvolk rechts, dazwischen eine Wand mit einer Lücke
  // unten. Abstand 4 Felder, also weit innerhalb des Radius.
  const zeilen = <String>[
    '############',
    '#@...#.e...#',
    '#....#.....#',
    '#....#.....#',
    '#..........#',
    '#.........B#',
    '############',
  ];

  ActionWorld welt({int attack = 0}) => ActionWorld(
        level: Level.parse('Wand', zeilen),
        heroStats: ActionStats(
          attack: attack,
          maxHp: 99999,
          defense: 0,
          energy: 8,
        ),
      );

  bool bemerkt(ActionWorld w, {int schritte = 60, Vec2 lauf = Vec2.zero}) {
    for (var i = 0; i < schritte; i++) {
      w.step(lauf);
      if (w.drainEvents().any(
            (e) =>
                e is EnemyNoticed &&
                w.views
                    .any((v) => v.id == e.id && v.kind != EnemyKind.endgegner),
          )) {
        return true;
      }
    }
    return false;
  }

  test('die Wand steht wirklich im Radius', () {
    const abstand = 6 * ActionBalance.tileSize;
    expect(abstand, lessThan(ActionBalance.aggroRadius));
  });

  test('hinter der Wand bemerkt er den nahen Helden nicht', () {
    expect(bemerkt(welt()), isFalse);
  });

  test('wer ihn sieht, kommt', () {
    // Schräg nach unten durch die Lücke: Dahinter ist die Sicht frei.
    expect(bemerkt(welt(), schritte: 240, lauf: const Vec2(1, 1)), isTrue);
  });

  test('ohne Wand dazwischen bemerkt er ihn sofort', () {
    final offen = ActionWorld(
      level: Level.parse('Offen', const <String>[
        '#########',
        '#@....e.#',
        '#......B#',
        '#########',
      ]),
      heroStats: const ActionStats(
        attack: 0,
        maxHp: 99999,
        defense: 0,
        energy: 8,
      ),
    );
    expect(bemerkt(offen, schritte: 2), isTrue);
  });
}

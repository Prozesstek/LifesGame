import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein offener Saal: Held oben links, ein Gegner schräg darunter, der
/// Wächter weit ausser Sicht.
final Level _saal = Level.parse('Saal', const <String>[
  '##########################',
  '#@.......................#',
  '#........................#',
  '#........................#',
  '#....e...................#',
  '#........................#',
  '#.......................B#',
  '##########################',
]);

/// Eine Wand zwischen Held und Gegner, offen nur am rechten Ende.
final Level _winkel = Level.parse('Winkel', const <String>[
  '##########################',
  '#@.......................#',
  '#........................#',
  '#######..................#',
  '#........................#',
  '#..e.....................#',
  '#.......................B#',
  '##########################',
]);

EntityView _gegner(ActionWorld welt) => welt.views.firstWhere(
      (v) => v.kind == EnemyKind.fussvolk,
    );

void main() {
  group('Gegner laufen gerade, nicht über Eck', () {
    test('im offenen Saal geradewegs auf den Helden zu', () {
      // Das Wegfeld kennt nur vier Richtungen. Folgt ein Gegner ihm Feld
      // für Feld, läuft er eine Treppe -- genau das war zu sehen.
      final welt = ActionWorld(level: _saal, heroStats: ActionStats.gereift);
      final held = welt.heroView.position;

      for (var i = 0; i < 20; i++) {
        welt.step(Vec2.zero);
        final gegner = _gegner(welt);
        final soll = (held - gegner.position).normalized;
        expect(
          gegner.facing.x * soll.x + gegner.facing.y * soll.y,
          greaterThan(0.99),
          reason: 'Schritt $i: Blick ${gegner.facing}, Luftlinie $soll',
        );
      }
    });

    test('hinter einer Wand schräg zur Ecke, nicht die Wand entlang', () {
      final welt = ActionWorld(level: _winkel, heroStats: ActionStats.gereift);
      final start = _gegner(welt).position;

      for (var i = 0; i < 30; i++) {
        welt.step(Vec2.zero);
      }
      final gegner = _gegner(welt);
      final weg = gegner.position - start;

      // Er muss nach rechts um die Wand -- und dabei schon nach oben
      // ziehen, statt erst die ganze Strecke waagrecht zu laufen.
      expect(weg.x, greaterThan(0));
      expect(weg.y, lessThan(0));
    });

    test('um die Wand herum kommt er trotzdem an', () {
      final welt = ActionWorld(level: _winkel, heroStats: ActionStats.gereift);

      // Oberkante der Wand: Wer darüber steht, ist um die Ecke herum.
      const wandOben = 3 * ActionBalance.tileSize;
      var herum = false;
      for (var i = 0; i < 60 * 10 && !welt.isOver; i++) {
        welt.step(Vec2.zero);
        final lebend = welt.views.where((v) => v.kind == EnemyKind.fussvolk);
        if (lebend.isEmpty) break;
        if (lebend.first.position.y < wandOben) herum = true;
      }
      expect(herum, isTrue);
    });
  });

  group('Niemand bleibt hängen', () {
    test('in gebauten Gruben steht kein Verfolger still, der einen Weg hat',
        () {
      // Ein Held, den nichts umbringt und der nichts umbringt, läuft zum
      // Wächter; alle, die ihn bemerken, laufen hinterher. Gezählt wird,
      // wer eine Sekunde lang keine vier Punkte vorankommt, obwohl er
      // einen Weg hätte.
      //
      // Vorher hingen hier drei Sorten: an Ecken, weil eine blockierte
      // Achse einfach verworfen wurde; im Durchgang, weil sich Troll und
      // Fussvolk gegenseitig festschoben; und der Troll vor Gängen, die
      // schmaler sind als er.
      const zaeh = ActionStats(
        attack: 1,
        maxHp: 1000000,
        defense: 999,
        energy: 8,
      );
      final haengen = <String>[];

      for (final stufe in <int>[10, 30]) {
        for (var seed = 0; seed < 10; seed++) {
          final level = LevelBuilder.build(stage: PitStage(stufe), seed: seed);
          final welt = ActionWorld(level: level, heroStats: zaeh, seed: seed);
          final feld = welt.fieldTo(welt.sleepingBossAt!);
          final gemerkt = <int>{};
          final anker = <int, Vec2>{};
          final still = <int, int>{};

          for (var i = 0; i < 60 * 60 && !welt.isOver; i++) {
            welt.step(feld.directionFrom(welt.heroView.position));
            for (final e in welt.drainEvents().whereType<EnemyNoticed>()) {
              gemerkt.add(e.id);
            }
            final held = welt.heroView.position;
            for (final v in welt.views) {
              if (!gemerkt.contains(v.id)) continue;
              if (v.kind == EnemyKind.schuetze) continue;
              final weg = welt.pathDistanceTo(v.position);
              final start = anker[v.id] ??= v.position;
              if (weg == null ||
                  weg <= 2 ||
                  (v.position - held).length < 60 ||
                  (v.position - start).length >= 4) {
                still[v.id] = 0;
                anker[v.id] = v.position;
                continue;
              }
              still[v.id] = (still[v.id] ?? 0) + 1;
              if (still[v.id] == 60) {
                haengen.add('Stufe $stufe, $seed: ${v.kind} bei ${v.position}');
              }
            }
          }
        }
      }

      expect(haengen, isEmpty);
    });
  });
}

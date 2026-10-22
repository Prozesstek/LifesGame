import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Beute in der Grube (ADR-0083): die erste Stufe der Kaskade — ob etwas
/// fällt —, das Einsammeln und was liegen bleibt.

/// Ein Gegner direkt neben dem Helden, der Wächter weit weg.
final Level _dicht = Level.parse('Dicht', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@e.......................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Ein Schütze fünf Felder weg — in Reichweite des Bogens.
final Level _fern = Level.parse('Fern', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@....s...................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Der Wächter direkt neben dem Helden, ohne Tor.
final Level _waechter = Level.parse('Wächter', const <String>[
  '##############',
  '#............#',
  '#...@B.......#',
  '#............#',
  '##############',
]);

const _stark = ActionStats(attack: 60, maxHp: 900, defense: 30, energy: 20);

ActionWorld _welt(
  Level level, {
  bool beute = true,
  int seed = 1,
  String? waffe,
}) {
  return ActionWorld(
    level: level,
    heroStats: _stark,
    dropsItems: beute,
    weaponMoveId: waffe,
    seed: seed,
  );
}

List<ActionEvent> _laufe(ActionWorld welt, int schritte, [Vec2? eingabe]) {
  final ereignisse = <ActionEvent>[];
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe ?? Vec2.zero);
    ereignisse.addAll(welt.drainEvents());
  }
  return ereignisse;
}

/// Läuft, bis der erste Gegner fällt.
List<ActionEvent> _bisZumKill(ActionWorld welt) {
  final ereignisse = <ActionEvent>[];
  for (var i = 0; i < 1200 && !welt.isOver; i++) {
    welt.step(Vec2.zero);
    ereignisse.addAll(welt.drainEvents());
    if (ereignisse.whereType<EntityDied>().isNotEmpty) break;
  }
  return ereignisse;
}

int _schritte(double sekunden) => (sekunden / ActionBalance.stepSeconds).ceil();

void main() {
  group('Ob etwas fällt', () {
    test('ohne Schalter fällt nichts — so bleibt die Tagesgrube', () {
      for (var seed = 0; seed < 60; seed++) {
        final welt = _welt(_dicht, beute: false, seed: seed);
        final ereignisse = _bisZumKill(welt);
        expect(ereignisse.whereType<ItemDropped>(), isEmpty);
      }
    });

    test('das Fussvolk wirft selten etwas', () {
      var funde = 0;
      const laeufe = 400;
      for (var seed = 0; seed < laeufe; seed++) {
        final welt = _welt(_dicht, seed: seed);
        funde += _bisZumKill(welt).whereType<ItemDropped>().length;
      }
      final quote = funde / laeufe;
      expect(quote, closeTo(ActionBalance.itemDropChance, 0.05));
    });

    test('derselbe Startwert wirft dasselbe', () {
      for (var seed = 0; seed < 30; seed++) {
        final a = _bisZumKill(_welt(_dicht, seed: seed));
        final b = _bisZumKill(_welt(_dicht, seed: seed));
        expect(
          a.whereType<ItemDropped>().length,
          b.whereType<ItemDropped>().length,
          reason: 'Startwert $seed',
        );
      }
    });

    test('Beute verschiebt keinen anderen Würfel', () {
      // Mit und ohne Beute derselbe Lauf: gleiche Treffer, gleicher Tod.
      for (var seed = 0; seed < 10; seed++) {
        final mit = _bisZumKill(_welt(_dicht, seed: seed))
            .whereType<HitLanded>()
            .map((e) => e.amount)
            .toList();
        final ohne = _bisZumKill(_welt(_dicht, beute: false, seed: seed))
            .whereType<HitLanded>()
            .map((e) => e.amount)
            .toList();
        expect(mit, ohne, reason: 'Startwert $seed');
      }
    });
  });

  group('Der Wächter', () {
    test('wirft immer, und es landet ohne Hinlaufen im Rucksack', () {
      final welt = _welt(_waechter);
      final ereignisse = _laufe(welt, _schritte(60));
      expect(welt.isWon, isTrue);
      final vomWaechter =
          ereignisse.whereType<ItemDropped>().where((e) => e.boss).toList();
      expect(vomWaechter, hasLength(1));
      expect(welt.collectedItems, contains(vomWaechter.single.nth));
      expect(welt.itemDrops, isEmpty);
    });
  });

  group('Einsammeln', () {
    /// Ein Startwert, bei dem der ferne Schütze etwas fallen lässt.
    ActionWorld schuetzeMitFund() {
      for (var seed = 0; seed < 300; seed++) {
        final welt = _welt(_fern, seed: seed, waffe: 'basic_attack');
        final ereignisse = _bisZumKill(welt);
        if (ereignisse.whereType<ItemDropped>().isNotEmpty) return welt;
      }
      fail('kein Startwert mit Fund');
    }

    test('was weit weg liegt, holt sich nicht von selbst', () {
      final welt = schuetzeMitFund();
      _laufe(welt, _schritte(2));
      expect(welt.itemDrops, hasLength(1));
      expect(welt.collectedItems, isEmpty);
    });

    test('hinlaufen sammelt ein', () {
      final welt = schuetzeMitFund();
      final fund = welt.itemDrops.single;
      final ereignisse = <ActionEvent>[];
      for (var i = 0; i < _schritte(5) && welt.collectedItems.isEmpty; i++) {
        final weg = fund.position - welt.heroView.position;
        welt.step(weg.normalized);
        ereignisse.addAll(welt.drainEvents());
      }
      expect(welt.collectedItems, <int>[fund.nth]);
      expect(ereignisse.whereType<ItemCollected>().single.id, fund.id);
      expect(welt.itemDrops, isEmpty);
    });

    test('jeder Fund hat seine eigene Nummer', () {
      final nummern = <int>[];
      for (var seed = 0; seed < 200; seed++) {
        final welt = _welt(_dicht, seed: seed);
        nummern.addAll(
          _bisZumKill(welt).whereType<ItemDropped>().map((e) => e.nth),
        );
      }
      // Je Lauf beginnt die Zählung bei eins.
      expect(nummern.toSet(), <int>{1});
    });
  });
}

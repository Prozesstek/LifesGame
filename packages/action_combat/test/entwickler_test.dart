import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die Werkbank des Entwicklermodus in der Grube: Gegner und Funde von
/// Hand, auf dem Weg des Spiels.

final Level _saal = Level.parse('Saal', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@........................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

const _stats = ActionStats(attack: 10, maxHp: 400, defense: 20, energy: 40);

ActionWorld _welt() => ActionWorld(
  level: _saal,
  heroStats: _stats,
  stage: PitStage(12),
  dropsItems: true,
);

void main() {
  group('Gegner beschwören', () {
    test('setzt einen Gegner der Art vor den Helden', () {
      final welt = _welt();
      final vorher = welt.totalEnemies;
      welt.devBeschwoereGegner(EnemyKind.grimlock);

      final neue = welt.views.where((v) => v.kind == EnemyKind.grimlock);
      expect(neue, hasLength(1));
      expect(welt.totalEnemies, vorher + 1);
      final abstand = (neue.single.position - welt.heroView.position).length;
      expect(abstand, lessThan(ActionBalance.tileSize * 6));
    });

    test('jede Art ausser dem Wächter lässt sich beschwören', () {
      for (final kind in EnemyKind.values) {
        if (kind == EnemyKind.endgegner || kind == EnemyKind.keiner) continue;
        final welt = _welt();
        welt.devBeschwoereGegner(kind);
        expect(
          welt.views.where((v) => v.kind == kind),
          isNotEmpty,
          reason: kind.name,
        );
      }
    });

    test('den Wächter nicht — er gehört in seinen Raum', () {
      final welt = _welt();
      final vorher = welt.views.length;
      welt.devBeschwoereGegner(EnemyKind.endgegner);
      expect(welt.views, hasLength(vorher));
    });

    test('ein beschworener Gegner kämpft und fällt wie jeder andere', () {
      final welt = _welt();
      welt.devBeschwoereGegner(EnemyKind.fussvolk);
      final ereignisse = <ActionEvent>[];
      for (var i = 0; i < 2000 && !welt.isOver; i++) {
        welt.step(Vec2.zero);
        ereignisse.addAll(welt.drainEvents());
        if (ereignisse.whereType<EntityDied>().isNotEmpty) break;
      }
      expect(ereignisse.whereType<HitLanded>(), isNotEmpty);
      expect(ereignisse.whereType<EntityDied>(), isNotEmpty);
    });
  });

  group('Fund legen', () {
    test('meldet einen Fund mit der nächsten Nummer, und er lässt sich '
        'einsammeln', () {
      final welt = _welt();
      final nth = welt.devLegeFund();
      expect(nth, 1);
      final gefallen = welt.drainEvents().whereType<ItemDropped>().single;
      expect(gefallen.nth, nth);
      expect(gefallen.boss, isFalse);

      // Er liegt vor dem Helden; in den Magneten laufen sammelt ihn ein.
      final fund = welt.itemDrops.single;
      final richtung = (fund.position - welt.heroView.position).normalized;
      for (var i = 0; i < 200 && welt.collectedItems.isEmpty; i++) {
        welt.step(richtung);
      }
      expect(welt.collectedItems, <int>[nth]);
    });

    test('zwei Funde tragen zwei Nummern', () {
      final welt = _welt();
      expect(welt.devLegeFund(), 1);
      expect(welt.devLegeFund(), 2);
      expect(welt.itemsDropped, 2);
    });
  });
}

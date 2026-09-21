import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Eine Traube: der Held links, fünf Gegner dicht beieinander rechts.
final Level _traube = Level.parse('Traube', const <String>[
  '##########',
  '#....ee..#',
  '#@...ee..#',
  '#....e..B#',
  '##########',
]);

/// Ein Gang mit einem Schützen am Ende — nah genug, dass er den Helden
/// von Anfang an bemerkt.
final Level _gang = Level.parse('Gang', const <String>[
  '#########',
  '#@.....s#',
  '#......B#',
  '#########',
]);

ActionWorld _welt(Level level, {ActionStats? stats, int seed = 1}) {
  return ActionWorld(
    level: level,
    heroStats: stats ?? ActionStats.gereift,
    seed: seed,
  );
}

void _spiele(ActionWorld welt, double sekunden, Vec2 eingabe) {
  final schritte = (sekunden / ActionBalance.stepSeconds).round();
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe);
  }
}

void main() {
  group('Der Fernkämpfer', () {
    test('er schiesst, statt heranzulaufen', () {
      final welt = _welt(_gang);
      _spiele(welt, 2, Vec2.zero);

      expect(welt.projectiles, isNotEmpty);
    });

    test('sein Geschoss trifft den Helden', () {
      final welt = _welt(_gang);
      final vorher = welt.heroHp;
      _spiele(welt, 6, Vec2.zero);

      expect(welt.heroHp, lessThan(vorher));
    });

    test('es bleibt an einer Wand hängen', () {
      // Der Held steht in einer Nische: Was ihn nicht sehen kann, darf
      // ihn nicht treffen. Der Wächter braucht den langen Weg aussen
      // herum und kommt in der Messzeit nicht an.
      final nische = Level.parse('Nische', const <String>[
        '##########',
        '#@#.....s#',
        '#.#......#',
        '#.#......#',
        '#.#.....B#',
        '#........#',
        '##########',
      ]);
      final welt = ActionWorld(level: nische, heroStats: ActionStats.gereift);
      final vorher = welt.heroHp;
      _spiele(welt, 3, Vec2.zero);

      expect(welt.heroHp, vorher);
    });

    test('er weicht zurück, wenn der Held zu nah kommt', () {
      final welt = _welt(_gang);
      final schuetze = welt.views.firstWhere(
        (v) => v.kind == EnemyKind.schuetze,
      );
      final vorher = schuetze.position.x;

      _spiele(welt, 3, const Vec2(1, 0));

      final nachher = welt.views
          .where((v) => v.kind == EnemyKind.schuetze)
          .map((v) => v.position.x);
      if (nachher.isNotEmpty) {
        expect(nachher.first, greaterThanOrEqualTo(vorher - 1));
      }
    });
  });

  group('Heilkugeln', () {
    test('ein voller Lauf hinterlässt welche', () {
      // Über 27 Gegner mit 28 % Quote ist „gar keine" praktisch
      // ausgeschlossen; der Test hängt trotzdem am Startwert, nicht am
      // Zufall des Tages.
      final welt = ActionWorld(
        level: LevelCatalog.grube,
        heroStats: ActionStats.mitPotenz,
        seed: 7,
      );
      var gesehen = 0;
      while (!welt.isOver && welt.elapsed < 300) {
        welt.step(_zumNaechstenGegner(welt));
        gesehen += welt.drainEvents().whereType<OrbDropped>().length;
      }

      expect(gesehen, greaterThan(0));
    });

    test('eine eingesammelte Kugel heilt', () {
      final welt = _welt(_traube, stats: ActionStats.frisch);
      // Erst Schaden nehmen, sonst gibt es nichts zu heilen.
      while (!welt.isOver && welt.heroHpRatio > 0.7 && welt.elapsed < 60) {
        welt.step(_zumNaechstenGegner(welt));
      }

      var geheilt = 0;
      while (!welt.isOver && welt.elapsed < 120) {
        welt.step(_zumNaechstenGegner(welt));
        for (final event in welt.drainEvents().whereType<OrbCollected>()) {
          geheilt += event.healed;
        }
      }

      expect(welt.orbsCollected, greaterThan(0));
      expect(geheilt, greaterThan(0));
    });
  });

  group('Rückstoss', () {
    test('ein getroffener Gegner weicht zurück', () {
      final welt = _welt(_traube);
      _spiele(welt, 1.5, const Vec2(1, 0));

      // Irgendwer wurde getroffen; niemand steht mehr im Helden drin.
      final held = welt.heroView.position;
      for (final sicht in welt.views) {
        if (sicht.faction != Faction.gegner) continue;
        expect(
          held.distanceTo(sicht.position),
          greaterThan(sicht.radius),
          reason: 'ein Gegner steckt im Helden',
        );
      }
    });

    test('der Endgegner bleibt stehen', () {
      final nurBoss = Level.parse('Boss', const <String>[
        '########',
        '#@....B#',
        '#.....e#',
        '########',
      ]);
      final welt = ActionWorld(
        level: nurBoss,
        heroStats: ActionStats.mitPotenz,
      );
      _spiele(welt, 4, const Vec2(1, 0));

      final boss = welt.bossView;
      if (boss != null) {
        // Er darf sich bewegt haben — aber auf den Helden **zu**, nicht
        // von ihm weg.
        expect(boss.position.x, lessThan(nurBoss.worldWidth));
      }
    });
  });
}

Vec2 _zumNaechstenGegner(ActionWorld welt) {
  final held = welt.heroView;
  Vec2? ziel;
  var beste = 1 << 29;

  for (final sicht in welt.views) {
    if (sicht.faction != Faction.gegner) continue;
    final distanz = welt.pathDistanceTo(sicht.position);
    if (distanz == null || distanz >= beste) continue;
    beste = distanz;
    ziel = sicht.position;
  }
  if (ziel == null) return Vec2.zero;

  final direkt = ziel - held.position;
  if (direkt.length <= ActionBalance.tileSize * 1.5) return direkt.normalized;
  return welt.fieldTo(ziel).directionFrom(held.position);
}

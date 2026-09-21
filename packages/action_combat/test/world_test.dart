import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Eine kleine Kammer: Held links, ein Gegner rechts, ein Endgegner
/// daneben. Klein genug, dass ein Test sie ganz durchspielt.
final Level _kammer = Level.parse('Kammer', const <String>[
  '##########',
  '#........#',
  '#@..e...B#',
  '#........#',
  '##########',
]);

ActionWorld _welt({ActionStats? stats, int seed = 1}) {
  return ActionWorld(
    level: _kammer,
    heroStats: stats ?? ActionStats.gereift,
    seed: seed,
  );
}

/// Lässt die Welt [sekunden] lang laufen, mit fester Eingabe.
void _spiele(ActionWorld welt, double sekunden, Vec2 eingabe) {
  final schritte = (sekunden / ActionBalance.stepSeconds).round();
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe);
  }
}

void main() {
  group('Der feste Zeitschritt', () {
    test('advance macht aus einer Sekunde sechzig Schritte', () {
      final welt = _welt();
      var schritte = 0;
      // In Häppchen, wie ein Renderer sie liefert.
      for (var i = 0; i < 10; i++) {
        schritte += welt.advance(0.1, Vec2.zero);
      }

      expect(schritte, 60);
      expect(welt.elapsed, closeTo(1.0, 0.001));
    });

    test('ein sehr langes Bild holt nur begrenzt nach', () {
      final welt = _welt();
      final schritte = welt.advance(10, Vec2.zero);

      expect(schritte, ActionBalance.maxCatchUpSteps);
    });

    test('derselbe Startwert ergibt denselben Lauf', () {
      // **Die Zusage, auf der das ganze Package steht.** Ohne sie liesse
      // sich ein Lauf nicht kopflos durchspielen, und jede Balance-Zahl
      // wäre eine Momentaufnahme.
      final a = _welt(seed: 42);
      final b = _welt(seed: 42);

      const richtung = Vec2(1, 0);
      _spiele(a, 3, richtung);
      _spiele(b, 3, richtung);

      expect(a.heroHp, b.heroHp);
      expect(a.kills, b.kills);
      expect(a.elapsed, b.elapsed);
      final viewsA = a.views.map((v) => v.position).toList();
      final viewsB = b.views.map((v) => v.position).toList();
      expect(viewsA, viewsB);
    });

    test('ein anderer Startwert ergibt einen anderen Lauf', () {
      final a = _welt(seed: 1);
      final b = _welt(seed: 2);

      const richtung = Vec2(1, 0);
      _spiele(a, 3, richtung);
      _spiele(b, 3, richtung);

      expect(a.heroHp == b.heroHp && a.kills == b.kills, isFalse);
    });
  });

  group('Bewegung', () {
    test('der Held läuft, wohin die Eingabe zeigt', () {
      final welt = _welt();
      final vorher = welt.heroView.position;

      _spiele(welt, 0.5, const Vec2(0, 1));

      expect(welt.heroView.position.y, greaterThan(vorher.y));
    });

    test('ohne Eingabe bleibt er stehen', () {
      final welt = _welt();
      final vorher = welt.heroView.position;

      _spiele(welt, 0.5, Vec2.zero);

      expect(welt.heroView.position, vorher);
    });

    test('er kommt nicht durch eine Wand', () {
      final welt = _welt();

      // Zehn Sekunden nach oben — die Wand ist nach einem halben Feld da.
      _spiele(welt, 10, const Vec2(0, -1));

      expect(welt.level.isWallAtPoint(welt.heroView.position), isFalse);
      expect(
        welt.heroView.position.y,
        greaterThan(ActionBalance.tileSize),
        reason: 'er steckt in der oberen Wand',
      );
    });

    test('an einer Wand entlang geht es weiter', () {
      // Schräg gegen die obere Wand: Die Y-Richtung wird geschluckt, die
      // X-Richtung nicht. Ohne das bleibt man an jeder Ecke kleben.
      final welt = _welt();
      final vorher = welt.heroView.position;

      _spiele(welt, 1, const Vec2(1, -1));

      expect(welt.heroView.position.x, greaterThan(vorher.x));
    });
  });

  group('Kampf', () {
    test('der Held schlägt von selbst, wenn jemand in Reichweite ist', () {
      final welt = _welt();
      _spiele(welt, 2, const Vec2(1, 0));

      expect(welt.kills, greaterThan(0));
    });

    test('ein Treffer meldet sich als Ereignis', () {
      final welt = _welt();
      _spiele(welt, 2, const Vec2(1, 0));

      final events = welt.drainEvents();
      expect(events.whereType<AttackSwung>(), isNotEmpty);
      expect(events.whereType<HitLanded>(), isNotEmpty);
      expect(events.whereType<EntityDied>(), isNotEmpty);
    });

    test('abgeholte Ereignisse kommen kein zweites Mal', () {
      final welt = _welt();
      _spiele(welt, 2, const Vec2(1, 0));

      expect(welt.drainEvents(), isNotEmpty);
      expect(welt.drainEvents(), isEmpty);
    });

    test('ein starker Held braucht weniger Schläge als ein frischer', () {
      // Die Frage, für die der Prototyp gebaut ist, als Zusage: Macht
      // muss sich in der Zahl der Schläge niederschlagen.
      int schlaegeBis(ActionStats stats) {
        final welt = ActionWorld(
          level: _kammer,
          heroStats: stats,
          seed: 5,
        );
        var treffer = 0;
        while (!welt.isOver && welt.kills == 0 && welt.elapsed < 60) {
          welt.step(const Vec2(1, 0));
          treffer += welt
              .drainEvents()
              .whereType<HitLanded>()
              .where((h) => h.targetFaction == Faction.gegner)
              .length;
        }
        return treffer;
      }

      expect(
        schlaegeBis(ActionStats.mitPotenz),
        lessThan(schlaegeBis(ActionStats.frisch)),
      );
    });
  });

  group('Wie ein Lauf endet', () {
    test('alle Gegner erledigt heisst gewonnen', () {
      final welt = _welt();

      while (!welt.isOver && welt.elapsed < 120) {
        welt.step(_zumNaechstenGegner(welt));
      }

      expect(welt.isOver, isTrue);
      expect(welt.isWon, isTrue);
      expect(welt.enemiesLeft, 0);
    });

    test('das Ende meldet sich genau einmal', () {
      final welt = _welt();
      var enden = 0;

      while (!welt.isOver && welt.elapsed < 120) {
        welt.step(_zumNaechstenGegner(welt));
        enden += welt.drainEvents().whereType<RunEnded>().length;
      }
      // Noch ein paar Schritte nach dem Ende.
      for (var i = 0; i < 60; i++) {
        welt.step(Vec2.zero);
        enden += welt.drainEvents().whereType<RunEnded>().length;
      }

      expect(enden, 1);
    });

    test('nach dem Ende passiert nichts mehr', () {
      final welt = _welt();
      while (!welt.isOver && welt.elapsed < 120) {
        welt.step(_zumNaechstenGegner(welt));
      }

      final zeit = welt.elapsed;
      _spiele(welt, 5, const Vec2(1, 0));

      expect(welt.elapsed, zeit);
    });

    test('ein frischer Held fällt in dieser Kammer', () {
      // Der Endgegner ist so ausgelegt, dass Tag-0-Werte nicht reichen.
      // Fiele das weg, wäre die Halle kein Prüfstein mehr.
      final welt = _welt(stats: ActionStats.frisch);

      while (!welt.isOver && welt.elapsed < 180) {
        welt.step(_zumNaechstenGegner(welt));
      }

      expect(welt.isOver, isTrue);
      expect(welt.isWon, isFalse);
    });
  });

  group('Das Wegfeld', () {
    test('es findet um eine Ecke herum', () {
      final winkel = Level.parse('Winkel', const <String>[
        '#######',
        '#@...##',
        '####.##',
        '####.##',
        '####eB#',
        '#######',
      ]);
      final welt = ActionWorld(level: winkel, heroStats: ActionStats.gereift);

      while (!welt.isOver && welt.elapsed < 120) {
        welt.step(_zumNaechstenGegner(welt));
      }

      expect(welt.isWon, isTrue, reason: 'der Weg um die Ecke fehlt');
    });

    test('Entfernung am Weg entlang, nicht Luftlinie', () {
      final winkel = Level.parse('Winkel', const <String>[
        '#######',
        '#@...##',
        '####.##',
        '####.##',
        '####eB#',
        '#######',
      ]);
      final welt = ActionWorld(level: winkel, heroStats: ActionStats.gereift);
      final gegner = welt.views.firstWhere(
        (v) => v.faction == Faction.gegner,
      );

      final amWeg = welt.pathDistanceTo(gegner.position);
      final luftlinie = welt.heroView.position.distanceTo(gegner.position) /
          ActionBalance.tileSize;

      expect(amWeg, isNotNull);
      expect(amWeg, greaterThan(luftlinie));
    });
  });
}

/// Dieselbe stumpfe Steuerung wie im kopflosen Lauf: zum nächsten
/// Gegner am Weg entlang.
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

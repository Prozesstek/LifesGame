import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein langer Saal: der Held links, ein Gegner rechts von ihm, weit
/// genug weg, um nicht sofort zu schlagen, und der Wächter ganz hinten.
final Level _saal = Level.parse('Saal', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@......e.................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Eine Wand zwischen dem Helden und dem, wohin er zielt.
final Level _mauer = Level.parse('Mauer', const <String>[
  '##############################',
  '#......#.....................#',
  '#......#.....................#',
  '#...@..#.....e...............#',
  '#......#.....................#',
  '#......#.....................#',
  '#......#....................B#',
  '##############################',
]);

ActionWorld _welt(List<String> faehigkeiten, {Level? level}) {
  return ActionWorld(
    level: level ?? _saal,
    heroStats: ActionStats.gereift,
    abilityIds: faehigkeiten,
  );
}

EntityView _fussvolk(ActionWorld welt) =>
    welt.views.firstWhere((v) => v.kind == EnemyKind.fussvolk);

int _treffer(ActionWorld welt, int schritte) {
  var summe = 0;
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(Vec2.zero);
    for (final e in welt.drainEvents().whereType<HitLanded>()) {
      if (e.targetFaction == Faction.gegner) summe += e.amount;
    }
  }
  return summe;
}

void main() {
  group('Der Katalog', () {
    test('jede Fähigkeit zielt so, wie sie wirkt', () {
      for (final a in PitAbilities.all) {
        final geschossOderSchlag = a.effects.any(
          (e) => e is BoltAtNearest || e is StrikeNearest,
        );
        switch (a.aim) {
          case PitAim.richtung:
            expect(geschossOderSchlag, isTrue, reason: a.id);
            expect(a.castRange, 0, reason: a.id);
          case PitAim.bereich:
            expect(a.castRange, greaterThan(0), reason: a.id);
            expect(a.areaRadius, greaterThan(0), reason: a.id);
            expect(geschossOderSchlag, isFalse, reason: a.id);
          case PitAim.umDenHelden:
            expect(a.areaRadius, greaterThan(0), reason: a.id);
            expect(a.castRange, 0, reason: a.id);
          case PitAim.selbst:
            expect(geschossOderSchlag, isFalse, reason: a.id);
            expect(a.areaRadius, 0, reason: a.id);
        }
      }
    });

    test('Eisfeld und Zeitdehnung setzt man ab', () {
      // Der Anlass: „sowas wie Eisfeld oder Zeitdehnung sollen AOE
      // Skillshots werden".
      expect(PitAbilities.frostnebel.aim, PitAim.bereich);
      expect(PitAbilities.zeitdehnung.aim, PitAim.bereich);
    });
  });

  group('Ein Geschoss als Skillshot', () {
    test('in die falsche Richtung trifft es nicht — und kostet trotzdem', () {
      final welt = _welt(const <String>['funkenstoss']);
      final vorher = welt.mana;
      final held = welt.heroView.position;

      expect(welt.castAt('funkenstoss', held + const Vec2(0, -100)), isTrue);
      expect(welt.mana, lessThan(vorher));
      expect(_treffer(welt, 60), 0);
    });

    test('in die richtige Richtung trifft es', () {
      final welt = _welt(const <String>['funkenstoss']);
      final ziel = _fussvolk(welt).position;

      expect(welt.castAt('funkenstoss', ziel), isTrue);
      expect(_treffer(welt, 60), greaterThan(0));
    });

    test('es fliegt genau seine Reichweite weit', () {
      // Der Gegner steht in der Bahn, aber hinter der Reichweite.
      final weit = Level.parse('weit', const <String>[
        '########################################',
        '#@....................................e#',
        '#.....................................B#',
        '########################################',
      ]);
      final welt = _welt(const <String>['funkenstoss'], level: weit);
      final held = welt.heroView.position;

      welt.castAt('funkenstoss', held + const Vec2(1, 0));
      expect(_treffer(welt, 90), 0);
    });

    test('über eine Wand gezielt, bleibt es an ihr hängen', () {
      final nah = Level.parse('Mauer nah', const <String>[
        '##############################',
        '#......#.....................#',
        '#......#.....................#',
        '#...@..#..e..................#',
        '#......#.....................#',
        '#......#....................B#',
        '##############################',
      ]);
      final welt = _welt(const <String>['funkenstoss'], level: nah);
      final ziel = _fussvolk(welt).position;
      final held = welt.heroView.position;
      expect(
        (ziel - held).length,
        lessThan(PitAbilities.funkenstoss.reach),
        reason: 'Sonst misst der Test die Reichweite, nicht die Wand.',
      );

      expect(welt.castAt('funkenstoss', ziel), isTrue);
      expect(_treffer(welt, 60), 0);
    });

    test('kurz getippt ohne Gegner in Reichweite kostet nichts', () {
      final leer = Level.parse('leer', const <String>[
        '##############################',
        '#@...........................#',
        '#......................e....B#',
        '##############################',
      ]);
      final welt = _welt(const <String>['funkenstoss'], level: leer);
      final vorher = welt.mana;

      expect(welt.cast('funkenstoss'), isFalse);
      expect(welt.mana, vorher);
    });

    test('die Vorschau ist so lang, wie es fliegt', () {
      final welt = _welt(const <String>['funkenstoss']);
      final held = welt.heroView.position;
      final vorschau = welt.aimPreview(
        'funkenstoss',
        held + const Vec2(0, 50),
      );

      expect(vorschau, isA<AimLine>());
      final linie = vorschau! as AimLine;
      expect(
        (linie.to - linie.from).length,
        closeTo(PitAbilities.funkenstoss.reach, 0.001),
      );
      expect(linie.to.x, closeTo(held.x, 0.001));
    });
  });

  group('Ein Schlag als Skillshot', () {
    test('trifft nur, wer davor steht', () {
      final nah = Level.parse('nah', const <String>[
        '##############################',
        '#...........................B#',
        '#...e@.......................#',
        '##############################',
      ]);
      final welt = _welt(const <String>['heavy_attack'], level: nah);
      final held = welt.heroView.position;

      // Der Gegner steht links; geschlagen wird nach rechts.
      expect(welt.castAt('heavy_attack', held + const Vec2(40, 0)), isTrue);
      final gegnerTreffer = welt
          .drainEvents()
          .whereType<HitLanded>()
          .where((e) => e.targetFaction == Faction.gegner);
      expect(gegnerTreffer, isEmpty);
    });
  });

  group('Ein abgesetzter Bereich', () {
    test('liegt dort, wo man ihn hinsetzt — und nicht am Helden', () {
      final welt = _welt(const <String>['frostnebel']);
      final held = welt.heroView.position;
      final ziel = held + const Vec2(0, 90);

      expect(welt.castAt('frostnebel', ziel), isTrue);
      expect(welt.zones, hasLength(1));
      expect(welt.zones.single.center.x, closeTo(ziel.x, 0.001));
      expect(welt.zones.single.center.y, closeTo(ziel.y, 0.001));
      expect(welt.zones.single.tint, PitTint.eis);
    });

    test('er reicht höchstens so weit, wie man werfen kann', () {
      final welt = _welt(const <String>['frostnebel']);
      final held = welt.heroView.position;

      welt.castAt('frostnebel', held + const Vec2(2000, 0));
      expect(
        (welt.zones.single.center - held).length,
        closeTo(PitAbilities.frostnebel.castRange, 0.001),
      );
    });

    test('er lässt sich hinter eine Wand setzen', () {
      final welt = _welt(const <String>['frostnebel'], level: _mauer);
      final held = welt.heroView.position;

      welt.castAt('frostnebel', held + const Vec2(200, 0));
      const wandRechts = 8 * ActionBalance.tileSize;
      expect(welt.zones.single.center.x, greaterThan(wandRechts));
      expect(welt.zones.single.center.x, closeTo(held.x + 200, 0.001));
    });

    test('er bremst, wer hineinläuft — auch nach dem Absetzen', () {
      // Wurzeln zwischen Held und Gegner, noch ohne ihn zu berühren: Er
      // hat den Helden bemerkt, läuft auf ihn zu und damit hindurch.
      final gang = Level.parse('Gang', const <String>[
        '##############################',
        '#............................#',
        '#...@.....e..................#',
        '#............................#',
        '#...........................B#',
        '##############################',
      ]);
      final welt = _welt(const <String>['wurzelgriff'], level: gang);
      final held = welt.heroView.position;

      welt.castAt('wurzelgriff', held + const Vec2(70, 0));
      expect(_fussvolk(welt).isSlowed, isFalse, reason: 'Noch draussen.');

      var gebremst = false;
      for (var i = 0; i < 120 && !welt.isOver; i++) {
        welt.step(Vec2.zero);
        final sicht = welt.views.where((v) => v.kind == EnemyKind.fussvolk);
        if (sicht.isNotEmpty && sicht.first.isSlowed) gebremst = true;
      }
      expect(gebremst, isTrue);
    });

    test('er läuft ab', () {
      final welt = _welt(const <String>['frostnebel']);
      welt.castAt('frostnebel', welt.heroView.position + const Vec2(0, 100));
      expect(welt.zones, isNotEmpty);

      final sekunden = PitAbilities.frostnebel.effects
          .whereType<SlowAround>()
          .single
          .seconds;
      final schritte = (sekunden / ActionBalance.stepSeconds).ceil() + 2;
      for (var i = 0; i < schritte; i++) {
        welt.step(Vec2.zero);
      }
      expect(welt.zones, isEmpty);
    });

    test('die Vorschau zeigt genau den Kreis, der dann liegt', () {
      final welt = _welt(const <String>['giftmoor']);
      final held = welt.heroView.position;
      final ziel = held + const Vec2(900, 60);

      final vorschau = welt.aimPreview('giftmoor', ziel)! as AimCircle;
      welt.castAt('giftmoor', ziel);
      final zone = welt.zones.single;

      expect(vorschau.center.x, closeTo(zone.center.x, 0.001));
      expect(vorschau.center.y, closeTo(zone.center.y, 0.001));
      expect(vorschau.radius, zone.radius);
      expect(vorschau.castRange, PitAbilities.giftmoor.castRange);
    });

    test('kurz getippt setzt er sich auf den nächsten Gegner', () {
      final welt = _welt(const <String>['frostnebel']);
      final gegner = _fussvolk(welt).position;

      expect(welt.cast('frostnebel'), isTrue);
      expect(welt.zones.single.center.x, closeTo(gegner.x, 0.001));
      expect(_fussvolk(welt).isSlowed, isTrue);
    });
  });

  group('Ohne Ziel', () {
    test('Heilung und Schutz zeigen nichts', () {
      final welt = _welt(const <String>['bluetentau', 'steinhaut']);
      expect(welt.aimPreview('bluetentau', null), isNull);
      expect(welt.aimPreview('steinhaut', null), isNull);
    });

    test('Klingenwirbel zeigt seinen Kreis am Helden', () {
      final welt = _welt(const <String>['klingenwirbel']);
      final vorschau = welt.aimPreview(
        'klingenwirbel',
        welt.heroView.position + const Vec2(300, 0),
      )! as AimCircle;

      expect(vorschau.center.x, welt.heroView.position.x);
      expect(vorschau.castRange, 0);
      expect(vorschau.radius, 70);
    });
  });
}

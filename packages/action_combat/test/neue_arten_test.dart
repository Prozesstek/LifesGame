import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Ein langer Saal: der Held links, ein Gegner ein Stück rechts, der
/// Wächter ganz hinten — weit genug, dass er nicht mitspielt.
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

/// Der Gegner vier Felder neben dem Helden — in Reichweite von Haken,
/// Falle und Eisball.
final Level _nah = Level.parse('Nah', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@...e....................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Eine Wand zwischen Held und Gegner.
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

/// Ein Gang, ein Feld breit: der einzige Weg zum Wächter.
final Level _gang = Level.parse('Gang', const <String>[
  '##############################',
  '#.......#####################',
  '#...@...........e...........B#',
  '#.......#####################',
  '##############################',
]);

/// Der Wächter gleich neben dem Helden, ohne Tor — er ist sofort wach.
final Level _waechter = Level.parse('Wächter', const <String>[
  '############',
  '#..........#',
  '#..@..B....#',
  '#..........#',
  '#.........e#',
  '############',
]);

const _stark = ActionStats(attack: 30, maxHp: 400, defense: 20, energy: 40);

/// Schlägt so schwach, dass ein Gegner ein paar Treffer übersteht — für
/// Tests, die ihn danach noch ansehen wollen.
const _sanft = ActionStats(attack: 1, maxHp: 400, defense: 20, energy: 40);

ActionWorld _welt(
  List<String> faehigkeiten, {
  Level? level,
  String? ultimate,
  ActionStats stats = _stark,
  int seed = 1,
}) {
  return ActionWorld(
    level: level ?? _saal,
    heroStats: stats,
    abilityIds: faehigkeiten,
    ultimateId: ultimate,
    seed: seed,
  );
}

EntityView _gegner(ActionWorld welt) =>
    welt.views.firstWhere((v) => v.kind == EnemyKind.fussvolk);

EntityView _boss(ActionWorld welt) =>
    welt.views.firstWhere((v) => v.kind == EnemyKind.endgegner);

List<ActionEvent> _laufe(ActionWorld welt, int schritte, [Vec2? eingabe]) {
  final ereignisse = <ActionEvent>[];
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe ?? Vec2.zero);
    ereignisse.addAll(welt.drainEvents());
  }
  return ereignisse;
}

int _schritte(double sekunden) => (sekunden / ActionBalance.stepSeconds).ceil();

void main() {
  group('Die Ultimate', () {
    test('liegt nie auf einem der drei Plätze', () {
      for (final u in PitAbilities.ultimates) {
        expect(u.isUltimate, isTrue, reason: u.id);
        expect(PitAbilities.byId(u.id), isNull, reason: u.id);
        expect(u.manaCost, 0, reason: u.id);
        expect(u.cooldown, 0, reason: u.id);
      }
      final welt = _welt(<String>['wassergrube']);
      expect(welt.slots, isEmpty);
    });

    test('eine gewöhnliche Fähigkeit wird keine Ultimate', () {
      final welt = _welt(const <String>[], ultimate: 'funkenstoss');
      expect(welt.ultimate, isNull);
    });

    test('beginnt leer und geht erst voll', () {
      final welt = _welt(const <String>[], ultimate: 'wassergrube');
      expect(welt.ultimateCharge, 0);
      expect(welt.canCast('wassergrube'), isFalse);
      expect(welt.cast('wassergrube'), isFalse);
    });

    test('ein Kill lädt ein Achtel', () {
      final welt = _welt(const <String>['donnerkeil'], ultimate: 'wassergrube');
      // Der Gegner fällt durch Donnerkeil und Grundangriff.
      for (var i = 0; i < 600 && welt.kills == 0; i++) {
        welt.cast('donnerkeil');
        welt.step(Vec2.zero);
      }
      expect(welt.kills, 1);
      expect(welt.ultimateCharge, closeTo(ActionBalance.ultimatePerKill, 1e-9));
    });

    test('ohne Ultimate lädt nichts', () {
      final welt = _welt(const <String>['donnerkeil']);
      for (var i = 0; i < 600 && welt.kills == 0; i++) {
        welt.cast('donnerkeil');
        welt.step(Vec2.zero);
      }
      expect(welt.ultimateCharge, 0);
    });

    test('Treffer am Wächter laden', () {
      final welt = ActionWorld(
        level: _waechter,
        heroStats: _stark,
        ultimateId: 'wassergrube',
        weaponMoveId: 'basic_attack',
      );
      var treffer = 0;
      for (var i = 0; i < 300 && treffer < 5; i++) {
        welt.step(Vec2.zero);
        for (final e in welt.drainEvents().whereType<HitLanded>()) {
          if (e.targetId == _boss(welt).id && !e.overTime) treffer++;
        }
      }
      expect(treffer, greaterThanOrEqualTo(5));
      expect(
        welt.ultimateCharge,
        greaterThanOrEqualTo(5 * ActionBalance.ultimatePerBossHit - 1e-9),
      );
    });

    test('voll gewirkt, kostet sie kein Mana und ist wieder leer', () {
      final welt = _welt(const <String>['donnerkeil'], ultimate: 'wassergrube');
      // Acht Kills gibt der Saal nicht her — also laden, wie es acht
      // Kills täten.
      for (var i = 0; i < 8; i++) {
        welt.debugChargeUltimate(ActionBalance.ultimatePerKill);
      }
      expect(welt.canCast('wassergrube'), isTrue);
      final mana = welt.mana;
      expect(welt.cast('wassergrube'), isTrue);
      expect(welt.mana, mana);
      expect(welt.ultimateCharge, 0);
    });
  });

  group('Stillstand', () {
    test('ein Gefrorener steht still und zerspringt beim nächsten Treffer', () {
      final welt = _welt(
        const <String>['eisball'],
        level: _nah,
        stats: _sanft,
      );
      expect(welt.cast('eisball'), isTrue);
      // Bis der Eisball trifft.
      for (var i = 0; i < 120 && !_gegner(welt).isFrozen; i++) {
        welt.step(Vec2.zero);
      }
      expect(_gegner(welt).isFrozen, isTrue);
      final wo = _gegner(welt).position;
      _laufe(welt, 10);
      expect(_gegner(welt).position, wo, reason: 'Er hat sich bewegt.');

      // Der Held läuft hin und schlägt: kritisch, und das Eis ist weg.
      var kritisch = false;
      for (var i = 0; i < 200 && _gegner(welt).isFrozen; i++) {
        welt.step(const Vec2(1, 0));
        for (final e in welt.drainEvents().whereType<HitLanded>()) {
          if (e.targetFaction == Faction.gegner && e.isCrit) kritisch = true;
        }
      }
      expect(_gegner(welt).isFrozen, isFalse);
      expect(kritisch, isTrue);
    });

    test('beim Wächter wirkt erst der dritte, halb so lang', () {
      final welt = _welt(const <String>['fanghaken'], level: _waechter);
      final kerben = <BossStunNotched>[];
      for (var wurf = 0; wurf < 3; wurf++) {
        welt.debugStun(_boss(welt).id, 2);
        kerben.addAll(welt.drainEvents().whereType<BossStunNotched>());
        if (wurf < 2) expect(_boss(welt).isStunned, isFalse);
      }
      expect(kerben.map((k) => k.stunned), <bool>[false, false, true]);
      expect(_boss(welt).isStunned, isTrue);
      expect(welt.bossStunNotches, 0);
      _laufe(welt, _schritte(2 * ActionBalance.bossStunShare) + 2);
      expect(_boss(welt).isStunned, isFalse);
    });
  });

  group('Haken und Strudel', () {
    test('der Haken zieht den Gegner vor die Füsse und hält ihn fest', () {
      final welt = _welt(
        const <String>['fanghaken'],
        level: _nah,
        stats: _sanft,
      );
      final vorher = _gegner(welt).position.distanceTo(welt.heroView.position);
      expect(welt.castAt('fanghaken', _gegner(welt).position), isTrue);
      _laufe(welt, _schritte(ActionBalance.shoveSeconds) + 2);
      final nachher = _gegner(welt).position.distanceTo(welt.heroView.position);
      expect(nachher, lessThan(vorher / 3));
      expect(_gegner(welt).isStunned, isTrue);
    });

    test('durch eine Wand zieht er nichts und kostet nichts', () {
      final welt = _welt(const <String>['fanghaken'], level: _mauer);
      final mana = welt.mana;
      expect(welt.cast('fanghaken'), isFalse);
      expect(welt.mana, mana);
    });

    test('den Wächter zieht er nicht', () {
      final welt = _welt(const <String>['fanghaken'], level: _waechter);
      welt.castAt('fanghaken', _boss(welt).position);
      _laufe(welt, _schritte(ActionBalance.shoveSeconds) + 1);
      // Gezogen stünde er Schulter an Schulter mit dem Helden; gelaufen ist
      // er in der Zeit nur ein Stück.
      final abstand = _boss(welt).position.distanceTo(welt.heroView.position);
      expect(
        abstand,
        greaterThan(_boss(welt).radius + welt.heroView.radius + 20),
      );
    });

    test('der Strudel zieht alle zur Mitte', () {
      final welt = _welt(const <String>[], ultimate: 'wassergrube');
      welt.debugChargeUltimate(1);
      final ziel = _gegner(welt).position + const Vec2(0, 60);
      expect(welt.castAt('wassergrube', ziel), isTrue);
      _laufe(welt, _schritte(ActionBalance.shoveSeconds) + 2);
      expect(_gegner(welt).position.distanceTo(ziel), lessThan(20));
      expect(_gegner(welt).isStunned, isTrue);
    });
  });

  group('Der Held selbst', () {
    test('der Sturm trägt ihn nach vorn und lässt eine Spur', () {
      final welt = _welt(const <String>['glutspur']);
      final start = welt.heroView.position;
      expect(welt.castAt('glutspur', start + const Vec2(0, -1)), isTrue);
      _laufe(welt, _schritte(ActionBalance.dashSeconds) + 2);
      final weg = welt.heroView.position.distanceTo(start);
      // Nach oben ist nach zwei Feldern Wand — er bleibt davor stehen.
      expect(weg, lessThan(70));
      expect(welt.zones, isNotEmpty);
    });

    test('der Sturm geht nach vorn bis zur vollen Weite', () {
      final welt = _welt(const <String>['glutspur']);
      final start = welt.heroView.position;
      welt.castAt('glutspur', start + const Vec2(0, 1));
      _laufe(welt, _schritte(ActionBalance.dashSeconds) + 2);
      // Nach unten sind es drei Felder bis zur Wand.
      expect(welt.heroView.position.y - start.y, greaterThan(60));
      expect(welt.isDashing, isFalse);
    });

    test('Rückenwind macht schneller', () {
      final o = _welt(const <String>[]);
      final m = _welt(const <String>['rueckenwind']);
      m.cast('rueckenwind');
      final start = o.heroView.position;
      _laufe(o, 20, const Vec2(0, -1));
      _laufe(m, 20, const Vec2(0, -1));
      expect(
        (m.heroView.position - start).length,
        greaterThan((o.heroView.position - start).length * 1.2),
      );
    });

    test('der Glückstrank würfelt mit dem Würfel des Laufs', () {
      int wurf(int seed) {
        final welt = _welt(const <String>['glueckstrank'], seed: seed);
        welt.cast('glueckstrank');
        return welt.drainEvents().whereType<LuckRolled>().single.outcome;
      }

      for (var seed = 1; seed < 6; seed++) {
        expect(wurf(seed), wurf(seed), reason: 'Seed $seed');
      }
      final ausgaenge = <int>{for (var s = 1; s < 60; s++) wurf(s)};
      expect(ausgaenge.length, greaterThan(3));
    });
  });

  group('Was fliegt und was liegt', () {
    test('der Bumerang trifft hin und zurück je einmal', () {
      final welt = _welt(const <String>['wiederkehr']);
      final ziel = _gegner(welt);
      welt.castAt('wiederkehr', ziel.position);
      var treffer = 0;
      for (var i = 0; i < 300 && welt.projectiles.isNotEmpty; i++) {
        welt.step(Vec2.zero);
        for (final e in welt.drainEvents().whereType<HitLanded>()) {
          if (e.targetId == ziel.id && !e.overTime) treffer++;
        }
      }
      expect(treffer, 2);
      expect(welt.projectiles, isEmpty);
    });

    test('eine Falle schnappt einmal zu, und es liegen höchstens zwei', () {
      final welt = _welt(const <String>['schnappfalle']);
      final weit = welt.heroView.position + const Vec2(0, 64);
      welt.castAt('schnappfalle', weit);
      welt.debugResetCooldowns();
      welt.castAt('schnappfalle', weit + const Vec2(32, 0));
      welt.debugResetCooldowns();
      welt.castAt('schnappfalle', weit + const Vec2(64, 0));
      expect(welt.traps, hasLength(ActionBalance.maxTraps));

      final zweite = _welt(
        const <String>['schnappfalle'],
        level: _nah,
        stats: _sanft,
      );
      zweite.castAt('schnappfalle', _gegner(zweite).position);
      final e = _laufe(zweite, 2);
      expect(e.whereType<TrapSprung>(), hasLength(1));
      expect(zweite.traps, isEmpty);
      expect(_gegner(zweite).isStunned, isTrue);
    });

    test('der Fels ist Wand und verschwindet wieder', () {
      final welt = _welt(const <String>['steinschlag']);
      final punkt = welt.heroView.position + const Vec2(96, 64);
      expect(welt.castAt('steinschlag', punkt), isTrue);
      expect(welt.level.isWallAtPoint(punkt), isTrue);
      _laufe(welt, _schritte(8) + 2);
      expect(welt.level.isWallAtPoint(punkt), isFalse);
    });

    test('nie auf den einzigen Weg', () {
      final welt = _welt(const <String>['steinschlag'], level: _gang);
      final imGang = welt.heroView.position + const Vec2(160, 0);
      expect(welt.castAt('steinschlag', imGang), isTrue);
      expect(welt.level.isWallAtPoint(imGang), isFalse);
    });

    test('die Ranke schleudert zur Seite', () {
      final welt = _welt(
        const <String>['rankenpeitsche'],
        level: _nah,
        stats: _sanft,
      );
      // Den Gegner heranholen: Er läuft auf den Helden zu.
      for (var i = 0; i < 400; i++) {
        if (_gegner(welt).position.distanceTo(welt.heroView.position) < 50) {
          break;
        }
        welt.step(Vec2.zero);
      }
      final vorher = _gegner(welt).position;
      final richtung = (vorher - welt.heroView.position).normalized;
      welt.castAt('rankenpeitsche', vorher);
      _laufe(welt, _schritte(ActionBalance.shoveSeconds));
      final weg = _gegner(welt).position - vorher;
      final rechts = Vec2(-richtung.y, richtung.x);
      expect(weg.x * rechts.x + weg.y * rechts.y, greaterThan(20));
    });
  });

  group('Begleiter', () {
    test('höchstens einer: Die Pflanze verdrängt den Falken', () {
      final welt = _welt(const <String>['falke'], ultimate: 'wassergrube');
      expect(welt.cast('falke'), isTrue);
      expect(welt.companion?.stationary, isFalse);
      final pflanze = _welt(
        const <String>['falke'],
        ultimate: 'fleischfressende_pflanze',
      );
      pflanze.cast('falke');
      pflanze.debugChargeUltimate(1);
      pflanze.castAt(
        'fleischfressende_pflanze',
        pflanze.heroView.position + const Vec2(0, 32),
      );
      expect(pflanze.companion?.stationary, isTrue);
    });

    test('was der Falke tötet, lädt die Ultimate nicht', () {
      const schwach =
          ActionStats(attack: 30, maxHp: 400, defense: 20, energy: 40);
      final welt = _welt(
        const <String>['falke'],
        ultimate: 'wassergrube',
        stats: schwach,
      );
      welt.cast('falke');
      // Der Held bleibt stehen; der Falke pickt, bis der Gegner fällt —
      // ausser er kommt in Reichweite des Grundangriffs. Damit nur der
      // Falke zählt, läuft der Held vor ihm davon.
      for (var i = 0; i < 2000 && welt.kills == 0; i++) {
        if (welt.companion == null) welt.cast('falke');
        welt.step(const Vec2(-1, 0));
      }
      expect(welt.kills, 1);
      expect(welt.ultimateCharge, 0);
    });

    test('die Pflanze frisst, wer fast am Ende ist — nie den Wächter', () {
      final welt = _welt(
        const <String>[],
        level: _waechter,
        ultimate: 'fleischfressende_pflanze',
        stats: _sanft,
      );
      welt.debugChargeUltimate(1);
      welt.castAt('fleischfressende_pflanze', _boss(welt).position);
      welt.debugWound(_boss(welt).id, 0.2);
      final e = _laufe(welt, _schritte(2));
      expect(
        e.whereType<CompanionStruck>().where((c) => c.devoured),
        isEmpty,
      );
      expect(_boss(welt).isAlive, isTrue);
    });
  });
}

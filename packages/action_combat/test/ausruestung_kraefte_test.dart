import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// Die Kräfte der neuen Ausrüstung (ADR-0077) — je Kraft ein Verhalten,
/// nicht ein Katalogeintrag (`gotchas.md`).

/// Ein langer Saal, der Gegner weit genug weg, dass er nicht mitspielt.
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

/// Der Gegner vier Felder neben dem Helden.
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

/// Der Gegner direkt neben dem Helden.
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

/// Hinter einer Wand, die der Held nicht durchschaut.
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

/// Zwei Gegner hintereinander — für den Langspeer.
final Level _hintereinander = Level.parse('Hintereinander', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@ee......................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Zwei vor dem Helden, einer schräg hinter ihm — für die Sichel.
final Level _bogen = Level.parse('Bogen', const <String>[
  '##############################',
  '#............................#',
  '#....e.......................#',
  '#...@e.......................#',
  '#..e.........................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

const _stark = ActionStats(attack: 30, maxHp: 400, defense: 20, energy: 40);

/// Schlägt so schwach, dass ein Gegner viele Treffer übersteht.
const _sanft = ActionStats(attack: 1, maxHp: 400, defense: 20, energy: 40);

/// Dazwischen: Ein Gegner übersteht ein paar Treffer, der Lebensraub ist
/// trotzdem eine ganze Zahl.
const _mittel = ActionStats(attack: 5, maxHp: 400, defense: 20, energy: 40);

/// Das volle Vampirset: vier Teile und die volle Stufe des Sets.
final List<PitModifier> _vampir = <PitModifier>[
  ...PitGearPowers.blutsichel.modifiers,
  ...PitGearPowers.nachtmantel.modifiers,
  ...PitGearPowers.fledermaushaube.modifiers,
  ...PitGearPowers.schattenstiefel.modifiers,
  ...PitGearPowers.blutpakt.modifiers,
];

ActionWorld _welt({
  List<PitModifier> modifiers = const <PitModifier>[],
  List<String> faehigkeiten = const <String>[],
  Level? level,
  ActionStats stats = _stark,
  String? waffe,
}) {
  return ActionWorld(
    level: level ?? _saal,
    heroStats: stats,
    abilityIds: faehigkeiten,
    weaponMoveId: waffe,
    modifiers: modifiers,
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

int _schritte(double sekunden) => (sekunden / ActionBalance.stepSeconds).ceil();

/// Treffer des Helden auf Gegner, ohne Dauerschaden.
Iterable<HitLanded> _treffer(List<ActionEvent> ereignisse) => ereignisse
    .whereType<HitLanded>()
    .where((e) => e.targetFaction != Faction.held && !e.overTime);

void main() {
  group('Der Katalog', () {
    test('jede neue Kraft bringt ein Passiv mit', () {
      final neue = PitGearPowers.all.where((k) => k.id.startsWith('kraft-'));
      expect(neue, hasLength(13));
      for (final kraft in neue) {
        expect(
          kraft.modifiers.whereType<GrantPassive>(),
          isNotEmpty,
          reason: kraft.id,
        );
      }
    });

    test('ein Passiv der Ausrüstung lässt jede Fähigkeit, wie sie ist', () {
      final welt = _welt(
        modifiers: PitGearPowers.echo.modifiers,
        faehigkeiten: const <String>['funkenstoss'],
      );
      expect(welt.slots.single.manaCost, PitAbilities.funkenstoss.manaCost);
      expect(welt.slots.single.cooldown, PitAbilities.funkenstoss.cooldown);
    });
  });

  group('Lebensraub', () {
    test('heilt einen Anteil dessen, was der Treffer abzog', () {
      final welt = _welt(
        modifiers: PitGearPowers.nachtmantel.modifiers,
        level: _dicht,
      );
      welt.debugWound(welt.heroView.id, 0.5);
      for (var i = 0; i < _schritte(5); i++) {
        welt.step(Vec2.zero);
        final jetzt = welt.drainEvents();
        final treffer = _treffer(jetzt).firstOrNull;
        if (treffer == null) continue;
        final heilung = jetzt.whereType<HeroHealed>().single;
        expect(heilung.amount, (treffer.amount * 0.03).round());
        return;
      }
      fail('kein Treffer in fünf Sekunden');
    });

    test('rechnet am ganzen Schlag, nicht am Rest des Lebens', () {
      // Zwei gleiche Läufe; in einem hat der Gegner fast kein Leben mehr.
      // Der Schlag zieht dort weniger ab, der Raub bleibt derselbe.
      (HitLanded, HeroHealed) ersterRaub({required bool angeschlagen}) {
        final welt = _welt(
          modifiers: PitGearPowers.nachtmantel.modifiers,
          level: _dicht,
        );
        welt.debugWound(welt.heroView.id, 0.5);
        if (angeschlagen) {
          final gegner = welt.views.firstWhere(
            (v) => v.faction != Faction.held && v.kind != EnemyKind.endgegner,
          );
          welt.debugWound(gegner.id, 0.05);
        }
        for (var i = 0; i < _schritte(5); i++) {
          welt.step(Vec2.zero);
          final jetzt = welt.drainEvents();
          final treffer = _treffer(jetzt).firstOrNull;
          if (treffer == null) continue;
          return (treffer, jetzt.whereType<HeroHealed>().single);
        }
        fail('kein Treffer in fünf Sekunden');
      }

      final (voll, heilungVoll) = ersterRaub(angeschlagen: false);
      final (rest, heilungRest) = ersterRaub(angeschlagen: true);
      expect(rest.amount, lessThan(voll.amount), reason: 'gekappt am Leben');
      expect(heilungRest.amount, heilungVoll.amount);
    });

    test('ohne Stück heilt kein Treffer', () {
      final welt = _welt(level: _dicht);
      welt.debugWound(welt.heroView.id, 0.5);
      final ereignisse = _laufe(welt, _schritte(2));
      expect(_treffer(ereignisse), isNotEmpty);
      expect(ereignisse.whereType<HeroHealed>(), isEmpty);
    });
  });

  group('Der Blutpakt', () {
    test('zieht jede Sekunde zwei Prozent ab, auch ohne Gegner', () {
      final welt = _welt(modifiers: _vampir, level: _mauer);
      final voll = welt.heroMaxHp;
      _laufe(welt, _schritte(2) + 1);
      final verloren = voll - welt.heroHp;
      expect(verloren, closeTo(voll * 0.04, voll * 0.011));
    });

    test('zählt nicht als Treffer: kein Kampfrausch', () {
      final welt = ActionWorld(
        level: _mauer,
        heroStats: _stark,
        abilityIds: const <String>['kampfrausch'],
        modifiers: _vampir,
      );
      _laufe(welt, _schritte(3));
      expect(welt.rageStacks, 0);
    });

    test('kann den Helden töten', () {
      final welt = _welt(modifiers: _vampir, level: _mauer);
      welt.debugWound(welt.heroView.id, 0.03);
      _laufe(welt, _schritte(3));
      expect(welt.isOver, isTrue);
      expect(welt.isWon, isFalse);
    });

    test('der Lebensraub zählt doppelt', () {
      final welt = _welt(modifiers: _vampir, level: _dicht, stats: _mittel);
      welt.debugWound(welt.heroView.id, 0.5);
      for (var i = 0; i < _schritte(5); i++) {
        welt.step(Vec2.zero);
        final jetzt = welt.drainEvents();
        final treffer = _treffer(jetzt).firstOrNull;
        if (treffer == null) continue;
        final heilung = jetzt.whereType<HeroHealed>().single;
        expect(heilung.amount, (treffer.amount * 0.12 * 2).round());
        return;
      }
      fail('kein Treffer in fünf Sekunden');
    });

    test('ein Fünftel des Raubs trifft, auch bei vollem Leben', () {
      final welt = _welt(modifiers: _vampir, level: _dicht, stats: _mittel);
      for (var i = 0; i < _schritte(5); i++) {
        welt.step(Vec2.zero);
        final jetzt = welt.drainEvents();
        final treffer = _treffer(jetzt).toList();
        if (treffer.isEmpty) continue;
        final erster = treffer.first;
        final moeglich = erster.amount * 0.12 * 2;
        expect(treffer, hasLength(2), reason: 'Schlag und Raub');
        expect(treffer.last.amount, (moeglich * 0.2).round());
        return;
      }
      fail('kein Treffer in fünf Sekunden');
    });

    test('eine Heilfähigkeit heilt nicht, sie trifft den nächsten Gegner', () {
      final welt = _welt(
        modifiers: _vampir,
        faehigkeiten: const <String>['bluetentau'],
        level: _nah,
      );
      welt.debugWound(welt.heroView.id, 0.5);
      final vorher = welt.heroHp;
      expect(welt.cast('bluetentau'), isTrue);
      final ereignisse = welt.drainEvents();

      expect(welt.heroHp, vorher);
      expect(ereignisse.whereType<BloodLashed>(), hasLength(1));
      expect(ereignisse.whereType<HeroHealed>(), isEmpty);
      final schlag = _treffer(ereignisse).single;
      expect(schlag.amount, greaterThan(0));
    });

    test('ohne Gegner in Sicht verpufft die Heilung', () {
      final welt = _welt(
        modifiers: _vampir,
        faehigkeiten: const <String>['bluetentau'],
        level: _mauer,
      );
      welt.debugWound(welt.heroView.id, 0.5);
      final vorher = welt.heroHp;
      expect(welt.cast('bluetentau'), isTrue);
      expect(welt.heroHp, vorher);
      expect(welt.drainEvents().whereType<BloodLashed>(), isEmpty);
    });

    test('zwei Teile heilen je Kill — vier machen auch daraus Schaden', () {
      final zwei = _welt(
        modifiers: PitGearPowers.blutdurst.modifiers,
        level: _dicht,
      );
      zwei.debugWound(zwei.heroView.id, 0.5);
      final vorher = zwei.heroHp;
      final ereignisse = _laufe(zwei, _schritte(3));
      expect(ereignisse.whereType<EntityDied>(), isNotEmpty);
      expect(zwei.heroHp, greaterThan(vorher));

      final vier = _welt(modifiers: _vampir, level: _dicht);
      vier.debugWound(vier.heroView.id, 0.5);
      final alle = _laufe(vier, _schritte(1));
      expect(alle.whereType<EntityDied>(), isNotEmpty);
      // Kein Gegner mehr in Sicht: Die Kill-Heilung verpufft, und geheilt
      // hat nur der Lebensraub — genau so viel wie im selben Lauf ganz ohne
      // Kill-Heilung. (Seit der Raub am ganzen Schlag rechnet, kann er
      // allein mehr heilen als die drei Prozent eines Kills.)
      final ohneKillHeilung = _welt(
        modifiers: <PitModifier>[
          ..._vampir.where(
            (m) => !(m is GrantPassive && m.passive is HealOnKill),
          ),
        ],
        level: _dicht,
      );
      ohneKillHeilung.debugWound(ohneKillHeilung.heroView.id, 0.5);
      final vergleich = _laufe(ohneKillHeilung, _schritte(1));
      int geheilt(List<ActionEvent> e) =>
          e.whereType<HeroHealed>().fold<int>(0, (s, h) => s + h.amount);
      expect(geheilt(alle), geheilt(vergleich));
    });
  });

  group('Frostreif', () {
    test('bremst und friert, wer im Kreis steht', () {
      final welt = _welt(
        modifiers: PitGearPowers.frostreif.modifiers,
        level: _dicht,
        stats: _sanft,
      );
      final ereignisse = _laufe(welt, _schritte(0.6));
      final gegner = welt.views.firstWhere((v) => v.kind == EnemyKind.fussvolk);
      expect(gegner.isSlowed, isTrue);
      final kaelte = ereignisse.whereType<HitLanded>().where(
            (e) => e.overTime && e.targetFaction != Faction.held,
          );
      expect(kaelte, isNotEmpty);
    });

    test('wer weit weg steht, merkt nichts', () {
      final welt = _welt(
        modifiers: PitGearPowers.frostreif.modifiers,
        level: _saal,
      );
      _laufe(welt, 2);
      final gegner = welt.views.firstWhere((v) => v.kind == EnemyKind.fussvolk);
      expect(gegner.isSlowed, isFalse);
      expect(welt.frostAuraRadius, 60);
    });
  });

  group('Irrlichter', () {
    test('alle fünf Sekunden eins, höchstens drei, und sie kreisen', () {
      final welt = _welt(
        modifiers: PitGearPowers.irrlichter.modifiers,
        level: _mauer,
      );
      _laufe(welt, _schritte(4.9));
      expect(welt.wisps, isEmpty);
      _laufe(welt, _schritte(0.2));
      expect(welt.wisps, hasLength(1));
      _laufe(welt, _schritte(16));
      expect(welt.wisps, hasLength(3));
      for (final licht in welt.wisps) {
        expect(licht.seeking, isFalse);
        expect(
          licht.position.distanceTo(welt.heroView.position),
          lessThan(ActionBalance.wispOrbitRadius + 4),
        );
      }
    });

    test('eins sucht einen Gegner in Sicht und zerplatzt an ihm', () {
      final welt = _welt(
        modifiers: PitGearPowers.irrlichter.modifiers,
        level: _nah,
        stats: _sanft,
      );
      final ereignisse = _laufe(welt, _schritte(7));
      expect(ereignisse.whereType<WispBurst>(), isNotEmpty);
    });
  });

  group('Flickwerk', () {
    test('nach drei Sekunden ohne Treffer liegt ein Schild', () {
      final welt = _welt(
        modifiers: PitGearPowers.flickwerk.modifiers,
        level: _mauer,
      );
      final erst = _laufe(welt, _schritte(2.9));
      expect(welt.shieldRatio, 0);
      expect(erst.whereType<ShieldRaised>(), isEmpty);
      final dann = _laufe(welt, _schritte(0.2));
      expect(welt.shieldRatio, 1);
      expect(dann.whereType<ShieldRaised>(), hasLength(1));
    });

    test('der Schild fängt den ersten Schlag ab', () {
      final welt = _welt(
        modifiers: PitGearPowers.flickwerk.modifiers,
        level: _saal,
        stats: _sanft,
      );
      _laufe(welt, _schritte(3.1));
      expect(welt.shieldRatio, 1);
      for (var i = 0; i < _schritte(15); i++) {
        welt.step(const Vec2(1, 0));
        final getroffen = welt.drainEvents().whereType<HitLanded>().any(
              (e) => e.targetFaction == Faction.held && !e.overTime,
            );
        if (!getroffen) continue;
        expect(welt.heroHp, welt.heroMaxHp);
        expect(welt.shieldRatio, lessThan(1));
        return;
      }
      fail('kein Schlag in fünfzehn Sekunden');
    });
  });

  group('Falkenblick', () {
    test('ein kritischer Treffer bringt Mana', () {
      final welt = _welt(
        modifiers: PitGearPowers.falkenblick.modifiers,
        faehigkeiten: const <String>['steinhaut'],
        level: _dicht,
        stats: _sanft,
      );
      for (var i = 0; i < _schritte(60); i++) {
        welt.debugResetCooldowns();
        welt.cast('steinhaut');
        final vorher = welt.mana;
        welt.step(Vec2.zero);
        final krit = _treffer(welt.drainEvents()).any((e) => e.isCrit);
        if (!krit) continue;
        expect(welt.mana - vorher, greaterThanOrEqualTo(2));
        return;
      }
      fail('kein kritischer Treffer in einer Minute');
    });
  });

  group('Ein Kill bringt etwas', () {
    test('Seelenernte: acht Mana', () {
      final welt = _welt(
        modifiers: PitGearPowers.seelenernte.modifiers,
        faehigkeiten: const <String>['steinhaut'],
        level: _dicht,
      );
      welt.cast('steinhaut');
      for (var i = 0; i < _schritte(3); i++) {
        final vorher = welt.mana;
        welt.step(Vec2.zero);
        final tot = welt.drainEvents().whereType<EntityDied>().isNotEmpty;
        if (!tot) continue;
        expect(welt.mana - vorher, greaterThanOrEqualTo(7));
        return;
      }
      fail('kein Kill in drei Sekunden');
    });

    test('Hasenlauf: kurz schneller', () {
      final welt = _welt(
        modifiers: PitGearPowers.hasenlauf.modifiers,
        level: _dicht,
      );
      final bisKill = <ActionEvent>[];
      for (var i = 0; i < _schritte(3); i++) {
        welt.step(Vec2.zero);
        bisKill.addAll(welt.drainEvents());
        if (bisKill.whereType<EntityDied>().isNotEmpty) break;
      }
      expect(bisKill.whereType<EntityDied>(), isNotEmpty);

      double weg() {
        final start = welt.heroView.position;
        _laufe(welt, 10, const Vec2(1, 0));
        return welt.heroView.position.distanceTo(start);
      }

      final schnell = weg();
      _laufe(welt, _schritte(3));
      final normal = weg();
      expect(schnell, closeTo(normal * 1.3, normal * 0.05));
    });
  });

  group('Echo', () {
    test('jede vierte Fähigkeit mit Schaden trifft noch einmal', () {
      final welt = _welt(
        modifiers: PitGearPowers.echo.modifiers,
        faehigkeiten: const <String>['funkenstoss', 'bluetentau'],
        level: _nah,
        // Genug Mana für acht Würfe und acht Heilungen.
        stats: const ActionStats(
          attack: 1,
          maxHp: 400,
          defense: 20,
          energy: 100,
        ),
      );
      final rechts = welt.heroView.position + const Vec2(1, 0);
      var echos = 0;
      for (var i = 1; i <= 8; i++) {
        welt.debugResetCooldowns();
        // Eine Heilung dazwischen zählt nicht mit.
        welt.cast('bluetentau');
        expect(welt.castAt('funkenstoss', rechts), isTrue, reason: 'Wurf $i');
        echos += welt.drainEvents().whereType<AbilityEchoed>().length;
        expect(echos, i ~/ 4, reason: 'nach Wurf $i');
      }
    });
  });

  group('Die zwei neuen Waffen', () {
    test('der Langspeer trifft beide hintereinander', () {
      final welt = _welt(
        level: _hintereinander,
        stats: _sanft,
        waffe: 'spear_thrust',
      );
      for (var i = 0; i < _schritte(2); i++) {
        welt.step(Vec2.zero);
        final jetzt = welt.drainEvents();
        if (jetzt.whereType<AttackSwung>().isEmpty) continue;
        final ziele = _treffer(jetzt).map((e) => e.targetId).toSet();
        expect(ziele, hasLength(2));
        return;
      }
      fail('kein Stich in zwei Sekunden');
    });

    test('die Sichel trifft im Bogen davor, nicht dahinter', () {
      final welt = _welt(level: _bogen, stats: _sanft, waffe: 'sickle_reap');
      final hinten = welt.views
          .where((v) => v.kind == EnemyKind.fussvolk)
          .reduce((a, b) => a.position.x < b.position.x ? a : b);
      for (var i = 0; i < _schritte(2); i++) {
        welt.step(Vec2.zero);
        final jetzt = welt.drainEvents();
        if (jetzt.whereType<AttackSwung>().isEmpty) continue;
        final ziele = _treffer(jetzt).map((e) => e.targetId).toSet();
        expect(ziele, hasLength(2));
        expect(ziele, isNot(contains(hinten.id)));
        return;
      }
      fail('kein Hieb in zwei Sekunden');
    });
  });
}

import 'package:action_combat/action_combat.dart';
import 'package:test/test.dart';

/// AktivesBretts zehn Fähigkeiten und zwei Ultimates (ADR-0074) — je
/// Wirkung ein Verhalten, nicht ein Katalogeintrag (`gotchas.md`: ein
/// Feld, das Verhalten steuern soll, braucht einen Test auf das
/// Verhalten).

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

/// Eine Wand drei Felder rechts vom Helden.
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

/// Der Gegner zwei Felder vor dem Helden — für den Rammbock.
final Level _zwei = Level.parse('Zwei', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@.e......................#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Vier Gegner in einer Reihe — für den Kettenblitz.
final Level _reihe = Level.parse('Reihe', const <String>[
  '##############################',
  '#............................#',
  '#............................#',
  '#...@....e..e..e..e..........#',
  '#............................#',
  '#............................#',
  '#...........................B#',
  '##############################',
]);

/// Ein Tor zwei Felder unter dem Helden.
final Level _tor = Level.parse('Tor', const <String>[
  '##############',
  '#......@.....#',
  '#............#',
  '#######==#####',
  '#............#',
  '#............#',
  '#......B.....#',
  '##############',
]);

const _stark = ActionStats(attack: 30, maxHp: 400, defense: 20, energy: 40);

/// Schlägt so schwach, dass ein Gegner ein paar Treffer übersteht.
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

List<ActionEvent> _laufe(ActionWorld welt, int schritte, [Vec2? eingabe]) {
  final ereignisse = <ActionEvent>[];
  for (var i = 0; i < schritte && !welt.isOver; i++) {
    welt.step(eingabe ?? Vec2.zero);
    ereignisse.addAll(welt.drainEvents());
  }
  return ereignisse;
}

int _schritte(double sekunden) => (sekunden / ActionBalance.stepSeconds).ceil();

const double _feld = ActionBalance.tileSize;

void main() {
  group('Der Katalog', () {
    test('zehn Fähigkeiten und zwei Ultimates sind da', () {
      const ids = <String>[
        'zinseszins',
        'schattenschritt',
        'kampfrausch',
        'kriegsschrei',
        'spiegelbild',
        'parade',
        'ruhepuls',
        'kettenblitz',
        'rammbock',
        'zweiter_atem',
      ];
      for (final id in ids) {
        expect(PitAbilities.byId(id), isNotNull, reason: id);
      }
      expect(PitAbilities.ultimateById('bestform'), isNotNull);
      expect(PitAbilities.ultimateById('rueckspulen'), isNotNull);
    });

    test('genau drei sind passiv', () {
      final passiv =
          PitAbilities.all.where((a) => a.isPassive).map((a) => a.id);
      const erwartet = <String>['kampfrausch', 'ruhepuls', 'zweiter_atem'];
      expect(passiv, unorderedEquals(erwartet));
    });
  });

  group('Passiv', () {
    test('hat keinen Knopf: lässt sich nicht wirken', () {
      final welt = _welt(const <String>['kampfrausch', 'ruhepuls']);
      expect(welt.slots, hasLength(2));
      expect(welt.canCast('kampfrausch'), isFalse);
      expect(welt.cast('kampfrausch'), isFalse);
      expect(welt.cast('ruhepuls'), isFalse);
    });
  });

  group('Zinseszins', () {
    test('jede Wiederholung zählt, höchstens fünfmal', () {
      final welt = _welt(
        const <String>['zinseszins'],
        level: _dicht,
        stats: _sanft,
      );
      for (var i = 1; i <= 7; i++) {
        welt.debugResetCooldowns();
        // Gezielt: Der Rückstoss schiebt den Gegner sonst aus der
        // Reichweite, und kurzes Tippen fände kein Ziel.
        final rechts = welt.heroView.position + const Vec2(1, 0);
        expect(welt.castAt('zinseszins', rechts), isTrue, reason: 'Wurf $i');
        expect(welt.stacksOf('zinseszins'), i < 5 ? i : 5);
      }
    });

    test('nach vier Sekunden Pause beginnt er von vorn', () {
      final welt = _welt(
        const <String>['zinseszins'],
        level: _dicht,
        stats: _sanft,
      );
      welt.cast('zinseszins');
      welt.debugResetCooldowns();
      welt.cast('zinseszins');
      expect(welt.stacksOf('zinseszins'), 2);

      _laufe(welt, _schritte(4.1));
      expect(welt.stacksOf('zinseszins'), 0);
    });
  });

  group('Schattenschritt', () {
    test('springt in die gezielte Richtung', () {
      final welt = _welt(const <String>['schattenschritt']);
      final vorher = welt.heroView.position;
      expect(welt.castAt('schattenschritt', vorher + const Vec2(0, 1)), isTrue);
      final nachher = welt.heroView.position;
      expect(nachher.y, greaterThan(vorher.y + _feld));
    });

    test('nie durch eine Wand', () {
      final welt = _welt(const <String>['schattenschritt'], level: _mauer);
      final vorher = welt.heroView.position;
      welt.castAt('schattenschritt', vorher + const Vec2(1, 0));
      // Die Wand steht in Spalte 7.
      expect(
        welt.heroView.position.x + welt.heroView.radius,
        lessThanOrEqualTo(7 * _feld),
      );
    });

    test('nie durch das Tor', () {
      final welt = _welt(const <String>['schattenschritt'], level: _tor);
      final vorher = welt.heroView.position;
      welt.castAt('schattenschritt', vorher + const Vec2(0, 1));
      // Das Tor liegt in Reihe 3.
      expect(
        welt.heroView.position.y + welt.heroView.radius,
        lessThanOrEqualTo(3 * _feld),
      );
    });

    test('unsichtbar greift kein Gegner an', () {
      // Der Held springt vom Gegner weg; sichtbar liefe der hinterher.
      ActionWorld lauf({required bool unsichtbar}) {
        final welt = _welt(
          unsichtbar ? const <String>['schattenschritt'] : const <String>[],
          level: _nah,
          stats: _sanft,
        );
        if (unsichtbar) {
          welt.castAt(
            'schattenschritt',
            welt.heroView.position + const Vec2(-1, 0),
          );
          expect(welt.isVanished, isTrue);
        }
        return welt;
      }

      final versteckt = lauf(unsichtbar: true);
      final offen = lauf(unsichtbar: false);
      final startVersteckt = _gegner(versteckt).position;
      final startOffen = _gegner(offen).position;
      _laufe(versteckt, _schritte(1));
      _laufe(offen, _schritte(1));

      expect(_gegner(versteckt).position, startVersteckt);
      expect(_gegner(offen).position, isNot(startOffen));
    });

    test('der erste eigene Treffer beendet sie', () {
      final welt = _welt(
        const <String>['schattenschritt'],
        level: _dicht,
        stats: _sanft,
      );
      welt.castAt('schattenschritt', welt.heroView.position + const Vec2(0, 1));
      expect(welt.isVanished, isTrue);
      // Neben dem Gegner schlägt der Grundangriff von selbst.
      welt.castAt('schattenschritt', welt.heroView.position);
      _laufe(welt, _schritte(1.5), const Vec2(0, -1));
      expect(welt.isVanished, isFalse);
    });
  });

  group('Kampfrausch', () {
    test('zählt eingesteckte Treffer, höchstens zehn', () {
      final welt = _welt(
        const <String>['kampfrausch'],
        level: _dicht,
        stats: const ActionStats(
          attack: 1,
          maxHp: 90000,
          defense: 0,
          energy: 10,
        ),
      );
      _laufe(welt, _schritte(3));
      expect(welt.rageStacks, greaterThan(0));
      _laufe(welt, _schritte(30));
      expect(welt.rageStacks, lessThanOrEqualTo(10));
    });
  });

  group('Die Grenze des Grundangriffs', () {
    test(
        'Bestform und Kriegsschrei zusammen bleiben auf dem Grundangriff '
        'bei einem Viertel', () {
      final welt = _welt(
        const <String>['kriegsschrei'],
        level: _dicht,
        ultimate: 'bestform',
      );
      welt.debugChargeUltimate(1);
      expect(welt.cast('bestform'), isTrue);
      expect(welt.cast('kriegsschrei'), isTrue);

      expect(
        welt.debugHeroFactor(fromWeapon: true),
        ActionBalance.weaponBuffCap,
      );
      // Fähigkeiten trifft die Grenze nicht.
      expect(welt.debugHeroFactor(fromWeapon: false), closeTo(1.2, 1e-9));
    });
  });

  group('Kriegsschrei', () {
    test('wer nah steht, steht still', () {
      final welt = _welt(
        const <String>['kriegsschrei'],
        level: _dicht,
        stats: _sanft,
      );
      expect(welt.cast('kriegsschrei'), isTrue);
      expect(_gegner(welt).isStunned, isTrue);
      expect(welt.isBuffed, isTrue);
    });
  });

  group('Spiegelbild', () {
    test('ein Abbild kämpft mit der Waffe', () {
      final welt = _welt(
        const <String>['spiegelbild'],
        level: _dicht,
        stats: _sanft,
      );
      expect(welt.cast('spiegelbild'), isTrue);
      expect(welt.companion?.mirror, isTrue);

      final ereignisse = _laufe(welt, _schritte(3));
      expect(ereignisse.whereType<CompanionStruck>(), isNotEmpty);
    });

    test('es erscheint neben dem Helden, nicht auf ihm', () {
      final welt = _welt(const <String>['spiegelbild']);
      welt.cast('spiegelbild');
      final abstand =
          welt.companion!.position.distanceTo(welt.heroView.position);
      expect(abstand, closeTo(ActionBalance.mirrorOffset, 1));
    });

    test('es bleibt stehen, wo es gerufen wurde', () {
      // AktivesBrett nach dem ersten Spielen: Es lief dem Helden nach.
      final welt = _welt(const <String>['spiegelbild']);
      welt.cast('spiegelbild');
      final dort = welt.companion!.position;
      _laufe(welt, _schritte(2), const Vec2(1, 0));
      expect(welt.heroView.position.distanceTo(dort), greaterThan(2 * _feld));
      expect(welt.companion!.position, dort);
      expect(welt.companion!.stationary, isTrue);
    });

    test('es schlägt von seinem Platz aus, nicht vom Helden', () {
      // Der Gegner steht neben dem Abbild; der Held ist weggegangen,
      // sieht ihn aber noch.
      final welt = _welt(
        const <String>['spiegelbild'],
        level: _dicht,
        stats: _sanft,
      );
      welt.cast('spiegelbild');
      final dort = welt.companion!.position;
      final ereignisse = _laufe(welt, _schritte(3));
      final schlaege = ereignisse.whereType<CompanionStruck>();
      expect(schlaege, isNotEmpty);
      for (final schlag in schlaege) {
        expect(schlag.from, dort);
      }
    });
  });

  group('Parade', () {
    test('fängt einen Schlag ab, und der Schläger steht', () {
      final welt = _welt(
        const <String>['parade'],
        level: _dicht,
        stats: _sanft,
      );
      AttackParried? pariert;
      var lebenDabei = 0;
      for (var i = 0; i < _schritte(10) && pariert == null; i++) {
        if (!welt.isParrying) {
          welt.debugResetCooldowns();
          welt.cast('parade');
        }
        final leben = welt.heroHp;
        welt.step(Vec2.zero);
        for (final e in welt.drainEvents()) {
          if (e is AttackParried) {
            pariert = e;
            lebenDabei = leben;
          }
        }
      }
      expect(pariert, isNotNull);
      expect(welt.heroHp, greaterThanOrEqualTo(lebenDabei));
      expect(_gegner(welt).isStunned, isTrue);
    });

    test('ohne Treffer läuft sie aus', () {
      final welt = _welt(const <String>['parade']);
      welt.cast('parade');
      expect(welt.isParrying, isTrue);
      _laufe(welt, _schritte(1));
      expect(welt.isParrying, isFalse);
    });
  });

  group('Ruhepuls', () {
    test('wer nicht schlägt, bekommt Mana schneller zurück', () {
      ActionWorld lauf(List<String> plaetze) {
        final welt = _welt(
          <String>['funkenstoss', ...plaetze],
          stats: const ActionStats(
            attack: 30,
            maxHp: 400,
            defense: 20,
            energy: 10,
          ),
        );
        // Erst eine Weile still, dann ein Funke ins Leere, damit Mana
        // fehlt — und eine Sekunde zum Nachfliessen.
        _laufe(welt, _schritte(2));
        welt.castAt('funkenstoss', welt.heroView.position + const Vec2(0, 1));
        _laufe(welt, _schritte(1));
        return welt;
      }

      final mit = lauf(const <String>['ruhepuls']);
      final ohne = lauf(const <String>[]);
      expect(mit.mana, greaterThan(ohne.mana));
    });
  });

  group('Kettenblitz', () {
    test('springt auf weitere Gegner, keinen zweimal, höchstens dreimal', () {
      final welt = _welt(
        const <String>['kettenblitz'],
        level: _reihe,
        stats: _sanft,
      );
      expect(welt.cast('kettenblitz'), isTrue);
      final ereignisse = _laufe(welt, _schritte(2));

      final getroffen = ereignisse
          .whereType<HitLanded>()
          .where((h) => h.targetFaction == Faction.gegner && !h.overTime)
          .map((h) => h.targetId)
          .toSet();
      final spruenge = ereignisse.whereType<ChainJumped>().length;
      expect(spruenge, inInclusiveRange(1, 3));
      expect(getroffen.length, greaterThanOrEqualTo(spruenge + 1));
    });
  });

  group('Rammbock', () {
    test('trifft, wirft zur Seite und hält fest', () {
      final welt = _welt(
        const <String>['rammbock'],
        level: _zwei,
        stats: _sanft,
      );
      final vorher = _gegner(welt).position;
      expect(
        welt.castAt('rammbock', welt.heroView.position + const Vec2(1, 0)),
        isTrue,
      );
      final ereignisse = _laufe(welt, _schritte(0.3));
      expect(
        ereignisse
            .whereType<HitLanded>()
            .any((h) => h.targetFaction == Faction.gegner),
        isTrue,
      );
      expect(_gegner(welt).isStunned, isTrue);
      expect((_gegner(welt).position.y - vorher.y).abs(), greaterThan(8));
    });
  });

  group('Zweiter Atem', () {
    test('greift einmal je Lauf unter einem Fünftel', () {
      final welt = _welt(const <String>['zweiter_atem']);
      final held = welt.heroView.id;
      welt.debugWound(held, 0.15);
      final erste = _laufe(welt, 1);
      expect(erste.whereType<LastStandTriggered>(), hasLength(1));
      expect(welt.heroHpRatio, greaterThan(0.35));
      expect(welt.isWarded, isTrue);

      welt.debugWound(held, 0.1);
      final zweite = _laufe(welt, 1);
      expect(zweite.whereType<LastStandTriggered>(), isEmpty);
    });
  });

  group('Bestform', () {
    test('kein Mana, und die Abklingzeit läuft doppelt so schnell', () {
      final welt = _welt(const <String>['steinhaut'], ultimate: 'bestform');
      welt.debugChargeUltimate(1);
      expect(welt.cast('bestform'), isTrue);
      expect(welt.isOverdriven, isTrue);

      final mana = welt.mana;
      expect(welt.cast('steinhaut'), isTrue);
      expect(welt.mana, mana);

      // Steinhaut klingt zwölf Sekunden ab, in Bestform in sechs.
      _laufe(welt, _schritte(6.1));
      expect(welt.canCast('steinhaut'), isTrue);
    });
  });

  group('Rückspulen', () {
    test('zurück an den Ort und auf das Leben von vor vier Sekunden', () {
      final welt = _welt(const <String>[], ultimate: 'rueckspulen');
      final start = welt.heroView.position;
      _laufe(welt, _schritte(4), const Vec2(1, 0));
      expect(welt.heroView.position.x, greaterThan(start.x + 2 * _feld));

      welt.debugWound(welt.heroView.id, 0.5);
      welt.debugChargeUltimate(1);
      expect(welt.cast('rueckspulen'), isTrue);

      expect(welt.heroView.position.distanceTo(start), lessThan(_feld));
      expect(welt.heroHpRatio, 1);
      expect(welt.isInvulnerable, isTrue);
    });

    test('nie mit weniger Leben als jetzt', () {
      final welt = _welt(const <String>[], ultimate: 'rueckspulen');
      welt.debugWound(welt.heroView.id, 0.3);
      _laufe(welt, _schritte(4));
      // Seitdem geheilt: Das Leben von damals wäre weniger.
      welt.debugWound(welt.heroView.id, 0.8);
      welt.debugChargeUltimate(1);
      welt.cast('rueckspulen');
      expect(welt.heroHpRatio, closeTo(0.8, 0.01));
    });
  });
}

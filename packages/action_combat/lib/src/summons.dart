part of 'world.dart';

/// Was der Held in die Welt setzt und was dort eine Weile bleibt:
/// Fallen, der Begleiter, der Fels (ADR-0073).
///
/// **Nichts davon ist eine Figur.** Ein Begleiter steht nicht in der
/// Liste der Figuren — so kann ihn niemand angreifen, schieben oder
/// zählen, und „12 / 14 erledigt“ bleibt richtig.

/// Eine Falle am Boden.
class _Trap {
  _Trap({
    required this.center,
    required this.power,
    required this.stunSeconds,
    required this.secondsLeft,
  });

  final Vec2 center;
  final double power;
  final double stunSeconds;
  double secondsLeft;
}

/// Eine Falle, wie der Renderer sie sieht.
class TrapView {
  const TrapView({required this.center, required this.radius});

  final Vec2 center;
  final double radius;
}

/// Der Begleiter, solange er da ist.
class _Companion {
  _Companion({
    required this.effect,
    required this.position,
    required this.tint,
  }) : secondsLeft = effect.seconds;

  final Companion effect;
  final PitTint tint;
  Vec2 position;
  double secondsLeft;
  double cooldownLeft = 0;
}

/// Der Begleiter, wie der Renderer ihn sieht.
class CompanionView {
  const CompanionView({
    required this.position,
    required this.tint,
    required this.stationary,
    required this.remaining,
    this.mirror = false,
  });

  final Vec2 position;
  final PitTint tint;

  /// Ein Abbild des Helden (Spiegelbild, ADR-0074) — der Renderer
  /// zeichnet dann den Helden, durchscheinend.
  final bool mirror;

  /// Steht still (die Pflanze) oder fliegt mit (der Falke).
  final bool stationary;

  /// Wie viel seiner Zeit noch übrig ist, 1 bis 0.
  final double remaining;
}

/// Ein liegender Fels und wie lange noch.
class _RockLeft {
  _RockLeft({required this.x, required this.y, required this.secondsLeft});

  final int x;
  final int y;
  double secondsLeft;
}

extension _Summons on ActionWorld {
  // --- Fallen ---

  /// Legt eine Falle — nur auf freien Boden, nie ins Tor. Die dritte
  /// lässt die älteste verschwinden.
  void _layTrap(Vec2 punkt, Trap t) {
    const size = ActionBalance.tileSize;
    final x = (punkt.x / size).floor();
    final y = (punkt.y / size).floor();
    if (_level.isWallAt(x, y) || _level.isGateAt(x, y)) return;
    if (_traps.length >= ActionBalance.maxTraps) _traps.removeAt(0);
    _traps.add(
      _Trap(
        center: punkt,
        power: t.power,
        stunSeconds: t.stunSeconds,
        secondsLeft: t.seconds,
      ),
    );
  }

  /// Lässt Fallen ablaufen und zuschnappen. **Gegner sehen sie nicht** und
  /// weichen nicht aus; der Wächter löst sie aus und füllt eine Kerbe.
  void _tickTraps(double dt) {
    for (final falle in _traps) {
      falle.secondsLeft -= dt;
      if (falle.secondsLeft <= 0) continue;
      for (final ziel in _entities) {
        if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
        final r = ActionBalance.trapRadius + ziel.radius;
        if (falle.center.distanceSquaredTo(ziel.position) > r * r) continue;
        _events.add(TrapSprung(at: falle.center));
        _hit(_hero, ziel, powerFactor: falle.power);
        _stun(ziel, falle.stunSeconds);
        falle.secondsLeft = 0;
        break;
      }
    }
    _traps.removeWhere((f) => f.secondsLeft <= 0);
  }

  // --- Der Begleiter ---

  /// Ruft einen Begleiter — **höchstens einer**: Kommt die Pflanze, geht
  /// der Falke.
  void _summon(Companion c, Vec2 wo, PitTint tint) {
    _companion = _Companion(
      effect: c,
      position: c.mirror ? _mirrorSpot() : (c.stationary ? wo : _hero.position),
      tint: tint,
    );
  }

  /// Wo das Spiegelbild erscheint: neben dem Helden, links von seinem
  /// Blick — und dort **bleibt es** (ADR-0074). Steht dort eine Wand,
  /// erscheint es auf ihm.
  Vec2 _mirrorSpot() {
    var blick = _hero.facing.normalized;
    if (blick.isZero) blick = const Vec2(1, 0);
    final links = Vec2(blick.y, -blick.x);
    final daneben = _hero.position + links * ActionBalance.mirrorOffset;
    return _hitsWall(daneben, _hero.radius) ? _hero.position : daneben;
  }

  /// Ein Schritt des Begleiters.
  ///
  /// **Er greift nur an, was der Held sieht** — er fliegt, weckt aber
  /// keinen Raum hinter der Wand. Eine stehende Pflanze braucht dazu
  /// den Gegner in ihrer Reichweite.
  void _tickCompanion(double dt) {
    final begleiter = _companion;
    if (begleiter == null) return;
    begleiter.secondsLeft -= dt;
    if (begleiter.secondsLeft <= 0) {
      _companion = null;
      return;
    }
    final c = begleiter.effect;
    if (!c.stationary) begleiter.position = _hero.position;
    begleiter.cooldownLeft -= dt;
    if (begleiter.cooldownLeft > 0) return;

    final ziel = _companionTarget(begleiter);
    if (ziel == null) return;
    // Das Spiegelbild schlägt im Takt der Waffe (ADR-0074).
    begleiter.cooldownLeft =
        c.mirror ? _hero.attackCooldown / _hasteBuff : c.interval;

    final fressen =
        c.devourBelow > 0 && ziel != _boss && ziel.hpRatio < c.devourBelow;
    _events.add(
      CompanionStruck(
        from: begleiter.position,
        at: ziel.position,
        devoured: fressen,
      ),
    );
    ziel.lastHitByCompanion = true;
    if (fressen) {
      final wirklich = ziel.takeDamage(ziel.hp);
      _events.add(
        HitLanded(
          targetId: ziel.id,
          targetFaction: ziel.faction,
          at: ziel.position,
          amount: wirklich,
          isCrit: true,
          overTime: false,
        ),
      );
      return;
    }
    final wucht = c.mirror ? c.power * weapon.power : c.power;
    _hit(_hero, ziel, powerFactor: wucht, byCompanion: true);
  }

  /// Wen der Begleiter angreift: den nächsten, den der Held sieht —
  /// bei der Pflanze in ihrer Reichweite, beim Falken in seiner.
  ActionEntity? _companionTarget(_Companion begleiter) {
    final c = begleiter.effect;
    // Das Spiegelbild reicht so weit wie die Waffe des Helden, gemessen
    // von dort, wo es steht.
    final reichweite = c.mirror ? weapon.range : c.reach;
    ActionEntity? bester;
    var besteDistanz = double.infinity;
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      final r = reichweite + ziel.radius;
      final d = begleiter.position.distanceSquaredTo(ziel.position);
      if (d > r * r || d >= besteDistanz) continue;
      if (!_canSee(_hero.position, ziel.position)) continue;
      if (c.stationary && !_canSee(begleiter.position, ziel.position)) {
        continue;
      }
      besteDistanz = d;
      bester = ziel;
    }
    return bester;
  }

  // --- Der Fels ---

  /// Lässt einen Fels auf das Feld unter [punkt] fallen.
  ///
  /// **Nie ins Tor oder daneben, nie auf den einzigen Weg** — geprüft,
  /// indem gezählt wird, wie viele Felder der Held vorher und nachher
  /// erreicht: Fehlt mehr als das eine, auf dem der Fels liegt, trennt er
  /// etwas ab. Wer darunter steht, wird an den Rand geschoben.
  void _dropRock(Vec2 punkt, double sekunden) {
    const size = ActionBalance.tileSize;
    final x = (punkt.x / size).floor();
    final y = (punkt.y / size).floor();
    if (_level.isWallAt(x, y)) return;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (_level.isGateAt(x + dx, y + dy)) return;
      }
    }
    final mitFels = _level.withRock(x, y, present: true);
    if (!_keepsEveryWay(mitFels)) return;

    _level = mitFels;
    _rocks.add(_RockLeft(x: x, y: y, secondsLeft: sekunden));
    _events.add(
      RockChanged(
        at: Vec2(x * size + size / 2, y * size + size / 2),
        present: true,
      ),
    );
    // Wer darunter stand, geht an den Rand — nicht auf eine andere Figur,
    // die Trennung schiebt sie danach auseinander.
    for (final figur in _entities) {
      if (!figur.isAlive || figur.untouchable) continue;
      if (!_hitsWall(figur.position, figur.radius)) continue;
      figur.position = _pushOut(figur.position, figur.radius) ??
          _edgeOf(x, y, figur.position, figur.radius);
    }
    _rebuildPath();
  }

  /// Der nächste Punkt neben dem Fels auf [x], [y], von [von] aus.
  Vec2 _edgeOf(int x, int y, Vec2 von, double radius) {
    const size = ActionBalance.tileSize;
    final mitte = Vec2(x * size + size / 2, y * size + size / 2);
    var weg = von - mitte;
    if (weg.isZero) weg = const Vec2(1, 0);
    return mitte + weg.normalized * (size / 2 + radius + 1);
  }

  /// Ob mit [neu] noch jedes Feld erreichbar ist, das vorher erreichbar
  /// war — bis auf das eine unter dem Fels.
  bool _keepsEveryWay(Level neu) {
    const size = ActionBalance.tileSize;
    final hx = (_hero.position.x / size).floor();
    final hy = (_hero.position.y / size).floor();
    final vorher = _reachable(_level, hx, hy);
    final nachher = _reachable(neu, hx, hy);
    return nachher >= vorher - 1;
  }

  int _reachable(Level karte, int x, int y) {
    final feld = FlowField.from(karte, x, y);
    var anzahl = 0;
    for (var ty = 0; ty < karte.height; ty++) {
      for (var tx = 0; tx < karte.width; tx++) {
        if (feld.distanceAt(tx, ty) != null) anzahl++;
      }
    }
    return anzahl;
  }

  /// Lässt Felsen verschwinden, deren Zeit um ist.
  void _tickRocks(double dt) {
    if (_rocks.isEmpty) return;
    var geaendert = false;
    for (final fels in _rocks) {
      fels.secondsLeft -= dt;
      if (fels.secondsLeft > 0) continue;
      _level = _level.withRock(fels.x, fels.y, present: false);
      const size = ActionBalance.tileSize;
      _events.add(
        RockChanged(
          at: Vec2(fels.x * size + size / 2, fels.y * size + size / 2),
          present: false,
        ),
      );
      geaendert = true;
    }
    _rocks.removeWhere((f) => f.secondsLeft <= 0);
    if (geaendert) _rebuildPath();
  }
}

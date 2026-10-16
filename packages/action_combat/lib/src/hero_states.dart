part of 'world.dart';

/// Was AktivesBretts Fähigkeiten am Helden verändern (ADR-0074): Rage,
/// Ruhepuls, zweiter Atem, Unsichtbarkeit, Parade, Bestform, Stacking,
/// Kettenblitz, Blink und Rückspulen.
///
/// **Eine eigene Datei**, weil `world.dart` über der 800-Zeilen-Grenze
/// liegt; die Ausführung der Wirkungen steht weiter in `effects.dart`,
/// hier nur, was sie am Helden an Zustand hinterlassen.

/// Wo der Held zu einem Zeitpunkt stand — für das Rückspulen.
class _Snapshot {
  const _Snapshot({
    required this.time,
    required this.position,
    required this.hp,
    required this.gatesClosed,
  });

  final double time;
  final Vec2 position;
  final int hp;
  final bool gatesClosed;
}

extension _HeroStates on ActionWorld {
  // --- Wucht ---

  /// Womit ein Schlag des Helden malgenommen wird: Self-Buff, Rage und
  /// Bestform.
  ///
  /// **Auf den Grundangriff höchstens [ActionBalance.weaponBuffCap]**,
  /// zusammen gerechnet (ADR-0009, ADR-0073). Fähigkeiten trifft die
  /// Grenze nicht; ihre Bestform-Wucht kommt beim Wirken dazu
  /// ([_boosted]).
  double _heroFactor({required bool fromWeapon}) {
    var faktor = _attackBuff * _rageFactor;
    final bestform = _overdrive;
    if (fromWeapon && _overdriveLeft > 0 && bestform != null) {
      faktor *= bestform.attackPower;
    }
    if (fromWeapon) return math.min(faktor, ActionBalance.weaponBuffCap);
    return faktor;
  }

  double get _rageFactor {
    for (final passiv in _passives) {
      if (passiv is RageOnHit) return 1 + passiv.perHit * _rageStacks;
    }
    return 1;
  }

  /// [ability], wie sie in diesem Wirken trifft: mit ihren Stapeln und in
  /// Bestform härter. Zählt die Stapel weiter.
  PitAbility _boosted(PitAbility ability) {
    var faktor = 1.0;
    for (final effect in ability.effects) {
      if (effect is! Stacking) continue;
      final stand = _stacking[ability.id];
      final gezaehlt = stand == null || stand.left <= 0 ? 0 : stand.stacks;
      faktor *= 1 + effect.step * gezaehlt;
      _stacking[ability.id] = (
        stacks: math.min(effect.maxStacks, gezaehlt + 1),
        left: effect.window,
      );
    }
    final bestform = _overdrive;
    if (_overdriveLeft > 0 && bestform != null && !ability.isUltimate) {
      faktor *= bestform.abilityPower;
    }
    if (faktor == 1) return ability;
    return PitModifiers.apply(
      ability,
      <PitModifier>[ScaleDamage(factor: faktor)],
    );
  }

  /// Der erste Treffer aus der Unsichtbarkeit: einmal [_ambush], dann ist
  /// sie vorbei.
  double _ambushOnce() {
    if (_vanishLeft <= 0) return 1;
    _vanishLeft = 0;
    return _ambush;
  }

  // --- Mana ---

  /// Ruhepuls: Mana kommt schneller, wer eine Weile nicht getroffen hat.
  double get _restFactor {
    for (final passiv in _passives) {
      if (passiv is RestMana && _sinceHeroStruck >= passiv.idleSeconds) {
        return passiv.factor;
      }
    }
    return 1;
  }

  // --- Was am Helden abläuft ---

  void _tickHeroStates(double dt) {
    _sinceHeroStruck += dt;
    if (_rageLeft > 0) {
      _rageLeft -= dt;
      if (_rageLeft <= 0) _rageStacks = 0;
    }
    if (_vanishLeft > 0) _vanishLeft -= dt;
    if (_parryLeft > 0) _parryLeft -= dt;
    if (_overdriveLeft > 0) _overdriveLeft -= dt;
    if (_invulnLeft > 0) _invulnLeft -= dt;
    for (final id in _stacking.keys.toList()) {
      final stand = _stacking[id]!;
      if (stand.left <= 0) continue;
      _stacking[id] = (stacks: stand.stacks, left: stand.left - dt);
    }
  }

  /// Der Held hat einen Treffer eingesteckt — für den Kampfrausch.
  void _heroStruck() {
    for (final passiv in _passives) {
      if (passiv is! RageOnHit) continue;
      _rageStacks = math.min(passiv.maxStacks, _rageStacks + 1);
      _rageLeft = passiv.decaySeconds;
    }
  }

  /// Zweiter Atem: einmal je Lauf, wenn das Leben unter die Schwelle fällt.
  void _checkLastStand() {
    if (_lastStandUsed || !_hero.isAlive) return;
    for (final passiv in _passives) {
      if (passiv is! LastStand) continue;
      if (_hero.hpRatio >= passiv.threshold) return;
      _lastStandUsed = true;
      _events.add(LastStandTriggered(at: _hero.position));
      _healHero((_hero.maxHp * passiv.heal).round());
      _wardFactor = _wardLeft > 0
          ? math.min(_wardFactor, passiv.wardFactor)
          : passiv.wardFactor;
      _wardLeft = math.max(_wardLeft, passiv.wardSeconds);
      return;
    }
  }

  // --- Parade ---

  /// Ob eine offene Parade den Schlag von [attacker] abfängt. Wenn ja,
  /// steht er still, und die Parade ist verbraucht.
  bool _parried(ActionEntity attacker) {
    if (_parryLeft <= 0) return false;
    _parryLeft = 0;
    _events.add(AttackParried(at: _hero.position));
    _stun(attacker, _parryStun);
    return true;
  }

  /// Dasselbe für ein Geschoss: Der Schütze steht still, falls er noch
  /// lebt.
  bool _parriedShot(Projectile geschoss) {
    if (_parryLeft <= 0) return false;
    final schuetze = _entities
        .where((e) => e.id == geschoss.ownerId && e.isAlive)
        .firstOrNull;
    if (schuetze != null) return _parried(schuetze);
    _parryLeft = 0;
    _events.add(AttackParried(at: _hero.position));
    return true;
  }

  // --- Kettenblitz ---

  /// Lässt [geschoss] von [getroffen] auf den nächsten springen, den es
  /// noch nicht traf und den man vom Einschlag aus sieht.
  void _chainFrom(ActionEntity getroffen, Projectile geschoss) {
    final getroffene = <int>{...geschoss.hitIds, getroffen.id};
    ActionEntity? naechster;
    var besteDistanz = double.infinity;
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      if (getroffene.contains(ziel.id)) continue;
      final weite = geschoss.chainRange + ziel.radius;
      final d = getroffen.position.distanceSquaredTo(ziel.position);
      if (d > weite * weite || d >= besteDistanz) continue;
      if (!_canSee(getroffen.position, ziel.position)) continue;
      besteDistanz = d;
      naechster = ziel;
    }
    if (naechster == null) return;

    _events.add(ChainJumped(from: getroffen.position, to: naechster.position));
    final richtung = (naechster.position - getroffen.position).normalized;
    final sprung = Projectile(
      id: _nextId++,
      faction: Faction.held,
      position: getroffen.position,
      velocity: richtung * ActionBalance.heroBoltSpeed,
      damage: 0,
      radius: ActionBalance.heroBoltRadius,
      heroPower: (geschoss.heroPower ?? 1) * geschoss.chainFalloff,
      maxAge: geschoss.chainRange * 1.5 / ActionBalance.heroBoltSpeed,
      chainJumps: geschoss.chainJumps - 1,
      chainRange: geschoss.chainRange,
      chainFalloff: geschoss.chainFalloff,
    );
    sprung.hitIds.addAll(getroffene);
    _projectiles.add(sprung);
  }

  // --- Blink und Rückspulen ---

  /// Der Held springt bis [weite] weit in die gezielte Richtung — beim
  /// kurzen Tippen auf den nächsten Gegner zu, den er sieht, und dann
  /// bis neben ihn. **Nie durch eine Wand oder das Tor**: Er landet vor
  /// dem ersten Hindernis.
  void _blink(_CastPlan plan, double weite) {
    final start = _hero.position;
    final richtung = plan.direction ?? _hero.facing.normalized;
    if (richtung.isZero) return;

    var strecke = weite;
    final ziel = _firstInLine(richtung, weite + _hero.radius * 2);
    if (ziel != null) {
      final bis = start.distanceTo(ziel.position) -
          _hero.radius -
          ziel.radius -
          ActionBalance.blinkGap;
      strecke = math.min(weite, math.max(0, bis));
    }

    const schritt = ActionBalance.tileSize / 8;
    var zuletzt = start;
    for (var d = schritt; d <= strecke + 1e-6; d += schritt) {
      final punkt = start + richtung * math.min(d, strecke);
      if (_hitsWall(punkt, _hero.radius)) break;
      if (_touches(punkt, _hero.radius, _level.isGateAt)) break;
      if (!_canSee(start, punkt)) break;
      zuletzt = punkt;
    }

    _hero.facing = richtung;
    _dashLeft = 0;
    if (zuletzt == start) return;
    _hero.position = zuletzt;
    _events.add(HeroBlinked(from: start, to: zuletzt));
  }

  /// Merkt sich alle [ActionBalance.rewindSampleSeconds], wo der Held
  /// steht — höchstens so lange zurück, wie ein Rückspulen reicht.
  void _recordHistory(double dt) {
    _sinceSnapshot += dt;
    if (_sinceSnapshot < ActionBalance.rewindSampleSeconds &&
        _history.isNotEmpty) {
      return;
    }
    _sinceSnapshot = 0;
    _history.add(
      _Snapshot(
        time: _elapsed,
        position: _hero.position,
        hp: _hero.hp,
        gatesClosed: _level.gatesClosed,
      ),
    );
    final aeltestes = _elapsed - _rewindReach;
    while (_history.length > 1 && _history.first.time < aeltestes) {
      _history.removeAt(0);
    }
  }

  /// Wie weit das längste Rückspulen auf den Plätzen zurückreicht.
  double get _rewindReach {
    var weite = 0.0;
    for (final effect in ultimate?.effects ?? const <PitEffect>[]) {
      if (effect is Rewind) weite = math.max(weite, effect.seconds);
    }
    return weite + ActionBalance.rewindSampleSeconds;
  }

  /// Zurück zu dem, wie es vor [r.seconds] war: Ort und Leben, nie
  /// weniger Leben als jetzt. **Nie über ein Tor zurück** — ist es
  /// seitdem zugefallen oder liegt dort jetzt ein Fels, bleibt der Held
  /// stehen.
  void _rewind(Rewind r) {
    _invulnLeft = math.max(_invulnLeft, r.invulnerableSeconds);
    if (_history.isEmpty) return;
    final zeitpunkt = _elapsed - r.seconds;
    final damals = _history.firstWhere(
      (bild) => bild.time >= zeitpunkt,
      orElse: () => _history.first,
    );

    if (damals.hp > _hero.hp) _healHero(damals.hp - _hero.hp);

    final darfZurueck = damals.gatesClosed == _level.gatesClosed &&
        !_hitsWall(damals.position, _hero.radius);
    if (!darfZurueck) return;
    final vorher = _hero.position;
    _hero.position = damals.position;
    _dashLeft = 0;
    _events.add(HeroBlinked(from: vorher, to: damals.position, rewind: true));
  }
}

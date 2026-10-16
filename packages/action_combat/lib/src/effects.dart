part of 'world.dart';

/// **Die eine Stelle, die jede Art von [PitEffect] ausführt** (ADR-0073:
/// mit der ersten neuen Art aus `world.dart` hierher gezogen).
///
/// Eine neue Art kommt in `pit_ability.dart` als Datum dazu; der
/// Analyzer zeigt danach auf den Schalter in [_apply], und nur dort.
extension _Effects on ActionWorld {
  /// Führt [effect] aus — dorthin, wohin [plan] zeigt.
  void _apply(
    PitEffect effect,
    PitAbility ability,
    _CastPlan plan,
    Map<double, _Zone> flaechen,
  ) {
    switch (effect) {
      case BoltAtNearest(:final power, :final range, :final leech):
        _boltFrom(plan, power: power, range: range, leech: leech);
      case FreezeBolt(:final power, :final range, :final stunSeconds):
        _boltFrom(plan, power: power, range: range, freeze: stunSeconds);
      case StrikeNearest(:final power, :final range):
        final richtung = plan.direction;
        final ziel = richtung != null
            ? _nearestInCone(richtung, range)
            : _nearestEnemyWithin(range);
        if (richtung != null) _hero.facing = richtung;
        if (ziel == null) return;
        _hero.facing = (ziel.position - _hero.position).normalized;
        _hit(_hero, ziel, powerFactor: power);
      case StrikeAround(:final power, :final radius):
        for (final ziel in _enemiesAround(plan.center, radius)) {
          _hit(_hero, ziel, powerFactor: power);
        }
      case HealSelf(:final share):
        _healHero((_hero.maxHp * share).round());
      case GainMana(:final amount):
        _mana = math.min(heroStats.maxMana.toDouble(), _mana + amount);
      case ReduceIncoming(:final factor, :final seconds):
        _wardFactor = _wardLeft > 0 ? math.min(_wardFactor, factor) : factor;
        _wardLeft = seconds;
      case ReflectIncoming(:final share, :final seconds):
        _reflectShare =
            _reflectLeft > 0 ? math.max(_reflectShare, share) : share;
        _reflectLeft = seconds;
      case SlowAround(:final radius, :final factor, :final seconds):
        if (plan.placed) {
          final zone = _zoneFor(flaechen, plan, ability, radius, seconds);
          zone.slowFactor = math.min(zone.slowFactor, factor);
          return;
        }
        for (final ziel in _enemiesWithin(radius)) {
          ziel.slowFactor =
              ziel.slowLeft > 0 ? math.min(ziel.slowFactor, factor) : factor;
          ziel.slowLeft = math.max(ziel.slowLeft, seconds);
        }
      case DamageOverTime(:final radius, :final perSecond, :final seconds):
        final jeSekunde = _heroPower * perSecond;
        if (plan.placed) {
          final zone = _zoneFor(flaechen, plan, ability, radius, seconds);
          zone.dotPerSecond = math.max(zone.dotPerSecond, jeSekunde);
          return;
        }
        for (final ziel in _enemiesWithin(radius)) {
          _applyDot(ziel, jeSekunde, seconds);
        }
      case Dash():
        _startDash(effect, plan, ability.tint);
      case HookNearest(:final range, :final power, :final stunSeconds):
        _hookNearest(plan, range: range, power: power, stun: stunSeconds);
      case PullToCenter(:final radius, :final stunSeconds):
        _pullToCenter(plan.center, radius, stunSeconds);
      case SelfBuff():
        _buff(effect);
      case RandomOf(:final outcomes):
        _rollOutcome(outcomes, ability, plan, flaechen);
      case Boomerang(:final power, :final range):
        _throwBoomerang(plan, power: power, range: range);
      case Trap():
        _layTrap(plan.center, effect);
      case Companion():
        _summon(effect, plan.center, ability.tint);
      case Rock(:final seconds):
        _dropRock(plan.center, seconds);
      case SweepCone(:final power, :final range, :final fling):
        _sweep(plan, power: power, range: range, fling: fling);
      // --- ADR-0074 ---
      case Blink(:final distance):
        _blink(plan, distance);
      case Vanish(:final seconds, :final ambush):
        _vanishLeft = math.max(_vanishLeft, seconds);
        _ambush = ambush;
      case StunAround(:final radius, :final seconds):
        for (final ziel in _enemiesAround(plan.center, radius)) {
          _stun(ziel, seconds);
        }
      case Parry(:final seconds, :final stunSeconds):
        _parryLeft = seconds;
        _parryStun = stunSeconds;
      case ChainBolt(
          :final power,
          :final range,
          :final jumps,
          :final jumpRange,
          :final falloff,
        ):
        _boltFrom(
          plan,
          power: power,
          range: range,
          chainJumps: jumps,
          chainRange: jumpRange,
          chainFalloff: falloff,
        );
      case Overdrive(:final seconds):
        _overdrive = effect;
        _overdriveLeft = seconds;
      case Rewind():
        _rewind(effect);
      // Stacking wirkt beim Wirken auf die anderen Wirkungen (`_boosted`),
      // Passives dauernd — hier gibt es für beide nichts zu tun.
      case Stacking() || PitPassive():
        return;
    }
  }

  /// Was ein Schlag des Helden gerade wiegt: Angriff mal Faktor mal
  /// Self-Buff. Dauerschaden und Begleiter rechnen damit.
  double get _heroPower =>
      _hero.attack * _hero.damageMultiplier * _heroFactor(fromWeapon: false);

  // --- Geschosse ---

  /// Ein Geschoss in die gezielte Richtung, beim kurzen Tippen auf den
  /// nächsten, den der Held sieht.
  void _boltFrom(
    _CastPlan plan, {
    required double power,
    required double range,
    double leech = 0,
    double freeze = 0,
    int chainJumps = 0,
    double chainRange = 0,
    double chainFalloff = 1,
  }) {
    var richtung = plan.direction;
    if (richtung == null) {
      final ziel = _nearestEnemyWithin(range, needsSight: true);
      if (ziel == null) return;
      richtung = (ziel.position - _hero.position).normalized;
    }
    _shootAlong(
      richtung,
      power: power,
      weite: range,
      leech: leech,
      freeze: freeze,
      chainJumps: chainJumps,
      chainRange: chainRange,
      chainFalloff: chainFalloff,
    );
  }

  /// Wirft den Bumerang. Er fliegt [range] weit hinaus, dann zurück.
  void _throwBoomerang(
    _CastPlan plan, {
    required double power,
    required double range,
  }) {
    var richtung = plan.direction;
    if (richtung == null) {
      final ziel = _nearestEnemyWithin(range, needsSight: true);
      if (ziel == null) return;
      richtung = (ziel.position - _hero.position).normalized;
    }
    _hero.facing = richtung;
    _projectiles.add(
      Projectile(
        id: _nextId++,
        faction: Faction.held,
        position: _hero.position,
        velocity: richtung * ActionBalance.heroBoltSpeed,
        damage: 0,
        radius: ActionBalance.heroBoltRadius * 1.5,
        heroPower: power,
        // Hin ist [range] weit; zurück dauert höchstens so lange noch
        // einmal, plus Luft, falls der Held davonläuft.
        maxAge: range / ActionBalance.heroBoltSpeed * 3,
        boomerang: true,
      )..returnAfter = range / ActionBalance.heroBoltSpeed,
    );
  }

  /// Ein Schritt eines Bumerangs. Gibt zurück, ob er weiterfliegt.
  ///
  /// **Jeder höchstens einmal je Weg**: Beim Umkehren wird die Liste der
  /// Getroffenen geleert. An einer Wand kehrt er um; auf dem Rückweg
  /// folgt er dem Helden, wo er gerade steht, und erlischt, wenn eine
  /// Wand dazwischen steht.
  bool _moveBoomerang(Projectile b, double dt) {
    if (!b.returning && b.age >= b.returnAfter) _turnBoomerang(b);
    if (b.returning) {
      final zumHelden = _hero.position - b.position;
      if (zumHelden.length <= _hero.radius + b.radius) return false;
      if (!_canSee(b.position, _hero.position)) return false;
      b.velocity = zumHelden.normalized * ActionBalance.heroBoltSpeed;
    }
    final weiter = b.position + b.velocity * dt;
    if (_hitsWall(weiter, b.radius)) {
      if (b.returning) return false;
      _turnBoomerang(b);
      return true;
    }
    b.position = weiter;

    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      if (b.hitIds.contains(ziel.id)) continue;
      final r = b.radius + ziel.radius;
      if (b.position.distanceSquaredTo(ziel.position) > r * r) continue;
      b.hitIds.add(ziel.id);
      _hit(_hero, ziel, powerFactor: b.heroPower ?? 1);
    }
    return true;
  }

  void _turnBoomerang(Projectile b) {
    b.returning = true;
    b.hitIds.clear();
  }

  // --- Stillstand ---

  /// Lässt [ziel] [sekunden] stillstehen — beim Wächter über die
  /// Stun-Leiste: Erst jeder dritte wirkt, halb so lang, und bricht seine
  /// laufende Ankündigung ab (ADR-0073).
  ///
  /// Bei zweien gilt der längere; sie addieren sich nicht.
  void _stun(ActionEntity ziel, double sekunden, {bool frozen = false}) {
    if (!ziel.isAlive || ziel.untouchable || sekunden <= 0) return;
    if (ziel == _boss) {
      _notchBoss(ziel, sekunden, frozen: frozen);
      return;
    }
    ziel.stunLeft = math.max(ziel.stunLeft, sekunden);
    if (frozen) ziel.frozen = true;
    // Wer steht, holt nicht aus: Schrei und Strahl brechen ab.
    ziel.windupLeft = 0;
  }

  void _notchBoss(ActionEntity boss, double sekunden, {required bool frozen}) {
    boss.stunNotches++;
    final voll = boss.stunNotches >= ActionBalance.bossStunNotches;
    _events.add(
      BossStunNotched(
        at: boss.position,
        notches: boss.stunNotches,
        stunned: voll,
      ),
    );
    if (!voll) return;
    boss.stunNotches = 0;
    boss.stunLeft = math.max(
      boss.stunLeft,
      sekunden * ActionBalance.bossStunShare,
    );
    if (frozen) boss.frozen = true;
    final zustand = _bossState;
    if (zustand != null) {
      zustand.windingUp = null;
      zustand.windupLeft = 0;
      zustand.chargeLeft = 0;
      zustand.targets = const <Vec2>[];
    }
  }

  /// Zerspringen: Ein Treffer des Helden auf einen Gefrorenen ist sicher
  /// kritisch und taut ihn auf. Gibt zurück, ob er gefroren war.
  bool _shatter(ActionEntity ziel) {
    if (!ziel.frozen || !ziel.isStunned) {
      ziel.frozen = false;
      return false;
    }
    ziel.frozen = false;
    ziel.stunLeft = 0;
    return true;
  }

  // --- Ziehen und Schleudern ---

  /// Bewegt [ziel] in [ActionBalance.shoveSeconds] nach [wohin]. Eine
  /// Wand hält es auf, denn bewegt wird über [_slide].
  void _shove(ActionEntity ziel, Vec2 wohin) {
    if (ziel == _boss || !ziel.isAlive) return;
    final weg = wohin - ziel.position;
    if (weg.isZero) return;
    ziel.shoveVelocity = weg * (1 / ActionBalance.shoveSeconds);
    ziel.shoveLeft = ActionBalance.shoveSeconds;
  }

  /// Der Haken: der Gegner in der Richtung, sonst der nächste, den der
  /// Held sieht — nie durch eine Wand.
  void _hookNearest(
    _CastPlan plan, {
    required double range,
    required double power,
    required double stun,
  }) {
    final richtung = plan.direction;
    final ziel = richtung != null
        ? _firstInLine(richtung, range)
        : _nearestEnemyWithin(range, needsSight: true);
    if (ziel == null) return;
    _events.add(HookThrown(from: _hero.position, to: ziel.position));
    _hero.facing = (ziel.position - _hero.position).normalized;
    final abstand = _hero.radius + ziel.radius + 2;
    _shove(ziel, _hero.position + _hero.facing * abstand);
    _hit(_hero, ziel, powerFactor: power);
    _stun(ziel, stun + ActionBalance.shoveSeconds);
  }

  /// Der erste Gegner, den eine Linie in [richtung] bis [weite] trifft,
  /// und nur, wenn der Held ihn sieht.
  ActionEntity? _firstInLine(Vec2 richtung, double weite) {
    ActionEntity? bester;
    var besteLaenge = double.infinity;
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      final weg = ziel.position - _hero.position;
      final laengs = weg.x * richtung.x + weg.y * richtung.y;
      if (laengs < 0 || laengs > weite + ziel.radius) continue;
      final quer = (weg - richtung * laengs).length;
      if (quer > ziel.radius + ActionBalance.heroBoltRadius * 2) continue;
      if (laengs >= besteLaenge) continue;
      if (!_canSee(_hero.position, ziel.position)) continue;
      besteLaenge = laengs;
      bester = ziel;
    }
    return bester;
  }

  /// Der Strudel: Wer im Umkreis die Mitte sieht, rutscht hinein und
  /// steht still.
  void _pullToCenter(Vec2 mitte, double radius, double stun) {
    for (final ziel in _enemiesAround(mitte, radius)) {
      if (!_canSee(mitte, ziel.position)) continue;
      // Nicht alle auf einen Punkt: Jeder bleibt ein Stück vor der Mitte,
      // aus seiner Richtung — sonst schöbe die Trennung sie gleich wieder
      // auseinander.
      final weg = ziel.position - mitte;
      final rest = math.min(weg.length, ziel.radius);
      _shove(ziel, weg.isZero ? mitte : mitte + weg.normalized * rest);
      _stun(ziel, stun + ActionBalance.shoveSeconds);
    }
  }

  /// Die Ranke: trifft alle im Kegel und schleudert sie nach rechts.
  void _sweep(
    _CastPlan plan, {
    required double power,
    required double range,
    required double fling,
  }) {
    var richtung = plan.direction;
    if (richtung == null) {
      final ziel = _nearestEnemyWithin(range);
      if (ziel == null) return;
      richtung = (ziel.position - _hero.position).normalized;
    }
    _hero.facing = richtung;
    final rechts = Vec2(-richtung.y, richtung.x);
    final grenze = math.cos(ActionBalance.strikeHalfAngle);
    for (final ziel in _entities.toList()) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      final weg = ziel.position - _hero.position;
      final abstand = weg.length;
      if (abstand > range + ziel.radius) continue;
      if (abstand > 0) {
        final n = weg * (1 / abstand);
        if (n.x * richtung.x + n.y * richtung.y < grenze) continue;
      }
      _hit(_hero, ziel, powerFactor: power);
      if (ziel.kind == EnemyKind.kreischer) continue;
      _shove(ziel, ziel.position + rechts * fling);
    }
  }

  /// Bewegt, wer gerade gezogen oder geschleudert wird.
  void _tickShoves(double dt) {
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.shoveLeft <= 0) continue;
      final schritt = math.min(dt, ziel.shoveLeft);
      ziel.shoveLeft -= dt;
      ziel.position = _slide(
        ziel.position,
        ziel.shoveVelocity * schritt,
        ziel.radius,
      );
    }
  }

  // --- Der Held selbst ---

  /// Ein Faktor auf Zeit. Bei zweien desselben Werts gilt der stärkere.
  void _buff(SelfBuff b) {
    if (b.attack != 1) {
      _buffAttack =
          _buffAttackLeft > 0 ? math.max(_buffAttack, b.attack) : b.attack;
      _buffAttackLeft = b.seconds;
    }
    if (b.haste != 1) {
      _buffHaste = _buffHasteLeft > 0 ? math.max(_buffHaste, b.haste) : b.haste;
      _buffHasteLeft = b.seconds;
    }
    if (b.moveSpeed != 1) {
      _buffSpeed =
          _buffSpeedLeft > 0 ? math.max(_buffSpeed, b.moveSpeed) : b.moveSpeed;
      _buffSpeedLeft = b.seconds;
    }
  }

  double get _attackBuff => _buffAttackLeft > 0 ? _buffAttack : 1;
  double get _hasteBuff => _buffHasteLeft > 0 ? _buffHaste : 1;
  double get _speedBuff => _buffSpeedLeft > 0 ? _buffSpeed : 1;

  void _tickBuffs(double dt) {
    if (_buffAttackLeft > 0) _buffAttackLeft -= dt;
    if (_buffHasteLeft > 0) _buffHasteLeft -= dt;
    if (_buffSpeedLeft > 0) _buffSpeedLeft -= dt;
  }

  /// Würfelt einen Ausgang — **mit dem Würfel des Laufs**, sonst wäre die
  /// Tagesgrube nicht mehr für alle gleich.
  void _rollOutcome(
    List<PitOutcome> outcomes,
    PitAbility ability,
    _CastPlan plan,
    Map<double, _Zone> flaechen,
  ) {
    final summe = outcomes.fold<int>(0, (s, o) => s + o.weight);
    if (summe <= 0) return;
    var wurf = _rng.nextInt(summe);
    for (var i = 0; i < outcomes.length; i++) {
      wurf -= outcomes[i].weight;
      if (wurf >= 0) continue;
      _events.add(LuckRolled(at: _hero.position, outcome: i));
      for (final effect in outcomes[i].effects) {
        _apply(effect, ability, plan, flaechen);
      }
      return;
    }
  }

  /// Startet den Sturm nach vorn.
  void _startDash(Dash d, _CastPlan plan, PitTint tint) {
    final richtung = plan.direction ?? _hero.facing.normalized;
    if (richtung.isZero) return;
    _hero.facing = richtung;
    _dashVelocity = richtung * (d.distance / ActionBalance.dashSeconds);
    _dashLeft = ActionBalance.dashSeconds;
    _ram = d.impactPower > 0 ? d : null;
    _rammed.clear();
    _trail = d.trailPerSecond <= 0
        ? null
        : _DashTrail(
            perSecond: _heroPower * d.trailPerSecond,
            seconds: d.trailSeconds,
            radius: d.trailRadius,
            tint: tint,
            lastDrop: null,
          );
    _dropTrail();
  }

  /// Ein Schritt des Sturms. Er geht durch Gegner, nicht durch Wände —
  /// bewegt wird über [_slide] wie jede Figur.
  void _tickDash(double dt) {
    if (_dashLeft <= 0) return;
    final schritt = math.min(dt, _dashLeft);
    _dashLeft -= dt;
    _hero.position = _slide(
      _hero.position,
      _dashVelocity * schritt,
      _hero.radius,
    );
    _dropTrail();
    _ramAlong();
    if (_dashLeft <= 0) {
      _trail = null;
      _ram = null;
    }
  }

  /// Der Rammbock (ADR-0074): Wen der Sturm streift, der wird getroffen,
  /// zur Seite geworfen — weg von der Bahn — und steht kurz still.
  /// Jeder höchstens einmal je Sturm.
  void _ramAlong() {
    final ramm = _ram;
    if (ramm == null) return;
    final richtung = _dashVelocity.normalized;
    final rechts = Vec2(-richtung.y, richtung.x);
    for (final ziel in _entities.toList()) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      if (_rammed.contains(ziel.id)) continue;
      final r = _hero.radius + ziel.radius + 2;
      if (_hero.position.distanceSquaredTo(ziel.position) > r * r) continue;
      _rammed.add(ziel.id);
      _hit(_hero, ziel, powerFactor: ramm.impactPower);
      final weg = ziel.position - _hero.position;
      final seite =
          weg.x * rechts.x + weg.y * rechts.y >= 0 ? rechts : rechts * -1;
      _shove(ziel, ziel.position + seite * ramm.impactFling);
      _stun(ziel, ramm.impactStun + ActionBalance.shoveSeconds);
    }
  }

  /// Legt ein Glied der Spur, sobald der Held einen Radius weiter ist.
  void _dropTrail() {
    final spur = _trail;
    if (spur == null) return;
    final zuletzt = spur.lastDrop;
    if (zuletzt != null && zuletzt.distanceTo(_hero.position) < spur.radius) {
      return;
    }
    spur.lastDrop = _hero.position;
    final zone = _Zone(
      center: _hero.position,
      radius: spur.radius,
      seconds: spur.seconds,
      tint: spur.tint,
    )..dotPerSecond = spur.perSecond;
    _zones.add(zone);
  }

  bool get _isDashing => _dashLeft > 0;
}

/// Die Spur eines Sturms, solange er läuft.
class _DashTrail {
  _DashTrail({
    required this.perSecond,
    required this.seconds,
    required this.radius,
    required this.tint,
    required this.lastDrop,
  });

  final double perSecond;
  final double seconds;
  final double radius;
  final PitTint tint;
  Vec2? lastDrop;
}

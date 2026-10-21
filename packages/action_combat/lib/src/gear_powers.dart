part of 'world.dart';

/// Was die Ausrüstung am Helden tut (ADR-0077): Lebensraub und Blutpakt,
/// Frostreif, Irrlichter, Flickwerk, Falkenblick, Hasenlauf,
/// Seelenernte, Echo — und die zwei neuen Grundangriffe Speer und
/// Sichel.
///
/// **Eine eigene Datei**, aus demselben Grund wie `hero_states.dart`:
/// `world.dart` liegt über der 800-Zeilen-Grenze. Die Kräfte kommen als
/// Passive in den Lauf ([GrantPassive]); hier steht, was sie tun.

/// Ein Irrlicht, solange es fliegt.
class _Wisp {
  _Wisp({required this.position});

  Vec2 position;

  /// Wen es gerade sucht — null heisst: es kreist um den Helden.
  int? targetId;
}

/// Ein Irrlicht, wie der Renderer es sieht.
class WispView {
  const WispView({required this.position, required this.seeking});

  final Vec2 position;

  /// Ob es gerade auf einen Gegner zufliegt.
  final bool seeking;
}

extension _GearPowers on ActionWorld {
  // --- Was getragen wird ---

  /// Das erste Passiv der Art [T], oder null.
  T? _gear<T extends PitPassive>() {
    for (final passiv in _passives) {
      if (passiv is T) return passiv;
    }
    return null;
  }

  /// Alle Stücke mit Lebensraub zusammen.
  double get _lifeSteal {
    var summe = 0.0;
    for (final passiv in _passives) {
      if (passiv is LifeSteal) summe += passiv.share;
    }
    return summe;
  }

  BloodPact? get _pact => _gear<BloodPact>();

  /// Mehr kritische Treffer aus der Ausrüstung.
  double get _critBonus => _gear<CritEdge>()?.chance ?? 0;

  /// Hasenlauf: wie viel schneller der Held gerade läuft.
  double get _rushFactor {
    if (_rushLeft <= 0) return 1;
    return _gear<KillRush>()?.speed ?? 1;
  }

  // --- Der Takt ---

  void _tickGearPowers(double dt) {
    if (_rushLeft > 0) _rushLeft -= dt;
    _tickDrain(dt);
    _tickShield(dt);
    _tickFrostAura(dt);
    _tickWisps(dt);
  }

  // --- Der Blutpakt ---

  /// Zieht dem Helden Leben ab — **immer**, auch ohne Gegner, auch
  /// unverwundbar: Das ist der Preis des vollen Sets, kein Treffer. Er
  /// zählt deshalb nicht für den Kampfrausch und füllt kein Flickwerk.
  void _tickDrain(double dt) {
    final pakt = _pact;
    if (pakt == null || !_hero.isAlive) return;
    _drainTick += dt;
    if (_drainTick < ActionBalance.bloodDrainTick) return;
    _drainTick -= ActionBalance.bloodDrainTick;

    final menge = math.max(
      1,
      (_hero.maxHp * pakt.drainShare * ActionBalance.bloodDrainTick).round(),
    );
    final wirklich = _hero.takeDamage(menge);
    _events.add(
      HitLanded(
        targetId: _hero.id,
        targetFaction: _hero.faction,
        at: _hero.position,
        amount: wirklich,
        isCrit: false,
        overTime: true,
      ),
    );
  }

  /// **Mit dem Blutpakt heilt nichts, was nicht Lebensraub ist.** [menge]
  /// trifft stattdessen den nächsten Gegner, den der Held sieht; steht
  /// keiner da, verpufft sie. Gibt zurück, ob umgeleitet wurde — dann
  /// heilt der Aufrufer nicht.
  bool _bloodRedirect(int menge) {
    if (_pact == null) return false;
    if (menge <= 0) return true;
    final ziel = _nearestEnemyWithin(
      ActionBalance.bloodLashRange,
      needsSight: true,
    );
    if (ziel == null) return true;
    final wirklich = ziel.takeDamage(menge);
    ziel.lastHitByCompanion = false;
    _events.add(BloodLashed(from: _hero.position, to: ziel.position));
    _events.add(
      HitLanded(
        targetId: ziel.id,
        targetFaction: ziel.faction,
        at: ziel.position,
        amount: wirklich,
        isCrit: false,
        overTime: false,
      ),
    );
    return true;
  }

  // --- Ein Treffer mit eigener Hand ---

  /// Was nach einem eigenen Treffer des Helden geschieht: Lebensraub, beim
  /// Blutpakt doppelt und mit Schaden, und Mana aus kritischen Treffern.
  /// [wirklich] ist der **ganze Schlag**, nicht gekappt am Leben des
  /// Ziels — ein Schlag für 2000 auf einen Gegner mit 200 raubt aus 2000.
  void _afterHeroHit(ActionEntity ziel, int wirklich, bool kritisch) {
    final falke = _gear<CritEdge>();
    if (kritisch && falke != null) _gainMana(falke.manaOnCrit.toDouble());

    final raub = _lifeSteal;
    if (raub <= 0 || wirklich <= 0) return;
    final pakt = _pact;
    final moeglich = wirklich * raub * (pakt?.stealFactor ?? 1);

    final vorher = _hero.hp;
    _hero.hp = math.min(_hero.maxHp, _hero.hp + moeglich.round());
    if (_hero.hp > vorher) {
      _events.add(HeroHealed(at: _hero.position, amount: _hero.hp - vorher));
    }

    // Gerechnet an dem, was er heilen **könnte** — auch bei vollem Leben.
    if (pakt == null || !ziel.isAlive) return;
    final extra = (moeglich * pakt.stealDamageShare).round();
    if (extra <= 0) return;
    final abgezogen = ziel.takeDamage(extra);
    _events.add(
      HitLanded(
        targetId: ziel.id,
        targetFaction: ziel.faction,
        at: ziel.position,
        amount: abgezogen,
        isCrit: false,
        overTime: false,
      ),
    );
  }

  void _gainMana(double menge) {
    _mana = math.min(heroStats.maxMana.toDouble(), _mana + menge);
  }

  // --- Ein Kill ---

  /// Was ein gefallener Gegner bringt: Blutdurst, Seelenernte, Hasenlauf.
  void _onKill() {
    final ernte = _gear<ManaOnKill>();
    if (ernte != null) _gainMana(ernte.amount.toDouble());
    final hase = _gear<KillRush>();
    if (hase != null) _rushLeft = hase.seconds;
    final durst = _gear<HealOnKill>();
    if (durst != null && _hero.isAlive) {
      _healHero((_hero.maxHp * durst.share).round());
    }
  }

  // --- Flickwerk ---

  /// Fängt [schaden] mit dem Schild ab, so weit er reicht, und gibt den
  /// Rest zurück. Jeder eingesteckte Schaden setzt die Uhr zurück.
  int _absorb(int schaden) {
    if (schaden <= 0) return schaden;
    _sinceHeroHurt = 0;
    if (_shield <= 0) return schaden;
    final gefangen = math.min(_shield, schaden);
    _shield -= gefangen;
    return schaden - gefangen;
  }

  void _tickShield(double dt) {
    _sinceHeroHurt += dt;
    final flick = _gear<IdleShield>();
    if (flick == null || _sinceHeroHurt < flick.idleSeconds) return;
    final voll = (_hero.maxHp * flick.share).round();
    if (_shield < voll) {
      if (_shield == 0) _events.add(ShieldRaised(at: _hero.position));
      _shield = voll;
    }
  }

  // --- Frostreif ---

  /// Bremst in jedem Schritt, was im Kreis steht, und friert es alle
  /// [ActionBalance.frostAuraTick] Sekunden an. **Der Wächter wird nur
  /// halb so stark gebremst** — sonst liefe sein Kampf in Zeitlupe.
  void _tickFrostAura(double dt) {
    final reif = _gear<FrostAura>();
    if (reif == null || !_hero.isAlive) return;

    final drin = _enemiesWithin(reif.radius);
    for (final ziel in drin) {
      final faktor = ziel.kind == EnemyKind.endgegner
          ? 1 - (1 - reif.slowFactor) / 2
          : reif.slowFactor;
      ziel.slowFactor =
          ziel.slowLeft > 0 ? math.min(ziel.slowFactor, faktor) : faktor;
      ziel.slowLeft = math.max(ziel.slowLeft, ActionBalance.frostAuraHold);
    }

    _auraTick += dt;
    if (_auraTick < ActionBalance.frostAuraTick) return;
    _auraTick -= ActionBalance.frostAuraTick;
    final menge = math.max(
      1,
      (_heroPower * reif.perSecond * ActionBalance.frostAuraTick).round(),
    );
    for (final ziel in drin) {
      if (!ziel.isAlive) continue;
      final wirklich = ziel.takeDamage(menge);
      _events.add(
        HitLanded(
          targetId: ziel.id,
          targetFaction: ziel.faction,
          at: ziel.position,
          amount: wirklich,
          isCrit: false,
          overTime: true,
        ),
      );
    }
  }

  // --- Irrlichter ---

  /// Ruft Irrlichter, lässt sie kreisen oder suchen und zerplatzen.
  ///
  /// **Sie suchen nur, was der Held sieht** — wie Falke und Pflanze
  /// (ADR-0073). Fliegen dürfen sie über Wände, sie sind Geister. Ihre
  /// Kills laden die Ultimate nicht, wie alles, was ein Begleiter tötet.
  void _tickWisps(double dt) {
    final licht = _gear<Wisps>();
    if (licht == null || !_hero.isAlive) return;

    if (_wisps.length < licht.maxCount) {
      _wispTimer += dt;
      if (_wispTimer >= licht.interval) {
        _wispTimer = 0;
        _wisps.add(_Wisp(position: _hero.position));
      }
    } else {
      _wispTimer = 0;
    }
    if (_wisps.isEmpty) return;
    _wispAngle += ActionBalance.wispOrbitSpeed * dt;

    // Jedes sucht einen anderen, solange es genug gibt.
    final ziele = <ActionEntity>[
      for (final ziel in _enemiesWithin(licht.seekRange))
        if (_canSee(_hero.position, ziel.position)) ziel,
    ]..sort(
        (a, b) => _hero.position
            .distanceSquaredTo(a.position)
            .compareTo(_hero.position.distanceSquaredTo(b.position)),
      );

    final geplatzt = <_Wisp>[];
    for (var i = 0; i < _wisps.length; i++) {
      final irrlicht = _wisps[i];
      final ziel = ziele.isEmpty ? null : ziele[i % ziele.length];
      irrlicht.targetId = ziel?.id;

      if (ziel == null) {
        final winkel = _wispAngle + i * 2 * math.pi / licht.maxCount;
        final platz = _hero.position +
            Vec2(math.cos(winkel), math.sin(winkel)) *
                ActionBalance.wispOrbitRadius;
        irrlicht.position = _toward(
          irrlicht.position,
          platz,
          ActionBalance.wispSpeed * 1.5 * dt,
        );
        continue;
      }

      irrlicht.position = _toward(
        irrlicht.position,
        ziel.position,
        ActionBalance.wispSpeed * dt,
      );
      final beruehrt = ActionBalance.wispRadius + ziel.radius;
      if (irrlicht.position.distanceSquaredTo(ziel.position) >
          beruehrt * beruehrt) {
        continue;
      }
      geplatzt.add(irrlicht);
      _events.add(
        WispBurst(at: irrlicht.position, radius: licht.blastRadius),
      );
      for (final getroffen
          in _enemiesAround(irrlicht.position, licht.blastRadius)) {
        _hit(_hero, getroffen, powerFactor: licht.power, byCompanion: true);
      }
    }
    _wisps.removeWhere(geplatzt.contains);
  }

  /// [von] höchstens [schritt] weit auf [nach] zu.
  Vec2 _toward(Vec2 von, Vec2 nach, double schritt) {
    final weg = nach - von;
    final laenge = weg.length;
    if (laenge <= schritt || laenge == 0) return nach;
    return von + weg * (schritt / laenge);
  }

  // --- Echo ---

  /// Jede [Echo.every]-te Fähigkeit, die Schaden macht, trifft noch
  /// einmal: **nur ihre Treffer**, mit [Echo.power] der Wucht. Heilung,
  /// Mana, Sprünge und Flächen wiederholen sich nicht — sonst wäre das
  /// Echo ein zweiter Atemzug umsonst.
  void _maybeEcho(PitAbility gewirkt, _CastPlan plan) {
    final echo = _gear<Echo>();
    if (echo == null || gewirkt.isUltimate) return;
    if (!gewirkt.effects.any(_echoes)) return;
    _echoCount++;
    if (_echoCount < echo.every) return;
    _echoCount = 0;

    final halb = PitModifiers.apply(
      gewirkt,
      <PitModifier>[ScaleDamage(factor: echo.power)],
    );
    _events.add(AbilityEchoed(id: gewirkt.id, at: plan.center));
    final flaechen = <double, _Zone>{};
    for (final effect in halb.effects) {
      if (_echoes(effect)) _apply(effect, halb, plan, flaechen);
    }
  }

  /// Ob [effect] ein Treffer ist, den das Echo wiederholt.
  bool _echoes(PitEffect effect) {
    return switch (effect) {
      BoltAtNearest() ||
      FreezeBolt() ||
      StrikeNearest() ||
      StrikeAround() ||
      SweepCone() ||
      ChainBolt() ||
      Boomerang() =>
        true,
      HealSelf() ||
      GainMana() ||
      ReduceIncoming() ||
      ReflectIncoming() ||
      SlowAround() ||
      DamageOverTime() ||
      Dash() ||
      HookNearest() ||
      PullToCenter() ||
      SelfBuff() ||
      RandomOf() ||
      Trap() ||
      Companion() ||
      Rock() ||
      Blink() ||
      Vanish() ||
      StunAround() ||
      Parry() ||
      Stacking() ||
      Overdrive() ||
      Rewind() ||
      PitPassive() =>
        false,
    };
  }

  // --- Die zwei neuen Grundangriffe ---

  /// Wen der Grundangriff trifft, wenn er auf [ziel] fällt: beim Speer
  /// alle in einer Linie, bei der Sichel alle im Bogen vor dem Helden.
  List<ActionEntity> _weaponTargets(ActionEntity ziel) {
    if (weapon.cleave) return _enemiesWithin(weapon.range);
    final richtung = (ziel.position - _hero.position).normalized;
    if (weapon.pierce) return _enemiesInLine(richtung, weapon.range);
    if (weapon.arcDegrees > 0) {
      return _enemiesInArc(richtung, weapon.range, weapon.arcDegrees);
    }
    return <ActionEntity>[ziel];
  }

  /// Alle, die die Linie von [weite] vor dem Helden berühren.
  List<ActionEntity> _enemiesInLine(Vec2 richtung, double weite) {
    return <ActionEntity>[
      for (final z in _entities)
        if (z.isAlive && !z.isHero && !z.untouchable)
          if (_onLine(z, richtung, weite)) z,
    ];
  }

  bool _onLine(ActionEntity z, Vec2 richtung, double weite) {
    final weg = z.position - _hero.position;
    final entlang = weg.x * richtung.x + weg.y * richtung.y;
    if (entlang < -z.radius || entlang > weite + z.radius) return false;
    final quer = (weg.x * richtung.y - weg.y * richtung.x).abs();
    return quer <= ActionBalance.spearHalfWidth + z.radius;
  }

  /// Alle in [weite], höchstens die Hälfte von [grad] neben [richtung].
  List<ActionEntity> _enemiesInArc(Vec2 richtung, double weite, double grad) {
    final grenze = math.cos(grad / 2 * math.pi / 180);
    return <ActionEntity>[
      for (final z in _entities)
        if (z.isAlive && !z.isHero && !z.untouchable)
          if (_inArc(z, richtung, weite, grenze)) z,
    ];
  }

  bool _inArc(ActionEntity z, Vec2 richtung, double weite, double grenze) {
    final weg = z.position - _hero.position;
    final abstand = weg.length;
    if (abstand > weite + z.radius) return false;
    if (abstand == 0) return true;
    final n = weg * (1 / abstand);
    return n.x * richtung.x + n.y * richtung.y >= grenze;
  }
}

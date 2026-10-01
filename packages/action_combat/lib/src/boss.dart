part of 'world.dart';

/// Was der Wächter gerade vorhat.
enum BossMove {
  /// Ein Ring um ihn füllt sich — wer dann noch drinsteht, wird getroffen.
  bodenstoss,

  /// Eine Linie zeigt die Richtung, dann rennt er los. Erst ab Wut.
  ansturm,

  /// Der zweite, grössere Ring des Ettins, gleich nach dem ersten.
  nachstoss,

  /// Der Slaad springt: Der Ring liegt dort, wo er landet.
  sprung,

  /// Der Sumpftroll wirft Gift: Der Ring liegt dort, wo es aufschlägt.
  pfuetze,
}

/// Eine Ankündigung, wie der Renderer sie zeichnet: ein Ring oder eine
/// Linie, die sich füllt.
///
/// **Die Ankündigung ist die halbe Fähigkeit.** Ohne sie wäre ein Angriff,
/// der doppelt trifft, einfach Pech. Mit ihr ist er eine Aufgabe: sehen,
/// laufen, zurückkommen.
class TelegraphView {
  const TelegraphView({
    required this.move,
    required this.origin,
    required this.radius,
    required this.direction,
    required this.length,
    required this.progress,
  });

  final BossMove move;

  /// Mitte des Rings, Anfang der Linie.
  final Vec2 origin;

  /// Beim Ring der Radius, bei der Linie die halbe Breite.
  final double radius;

  /// Nur bei der Linie: wohin sie zeigt.
  final Vec2 direction;

  /// Nur bei der Linie: wie weit er rennen wird.
  final double length;

  /// 0 bei Beginn, 1 im Moment des Treffers.
  final double progress;

  /// Alles ausser dem Ansturm ist ein Ring — um den Wächter oder dort,
  /// wo er oder sein Wurf landet.
  bool get isRing => move != BossMove.ansturm;

  /// Ob [point] mit einem Kreis von [pointRadius] in der Zone liegt.
  bool covers(Vec2 point, double pointRadius) {
    if (isRing) {
      final r = radius + pointRadius;
      return origin.distanceSquaredTo(point) <= r * r;
    }
    final weg = point - origin;
    final laengs = weg.x * direction.x + weg.y * direction.y;
    if (laengs < -pointRadius || laengs > length + pointRadius) return false;
    final quer = (weg - direction * laengs).length;
    return quer <= radius + pointRadius;
  }
}

/// Der Zustand des Wächters zwischen zwei Schritten.
///
/// **Veränderlich wie die Figuren**, aus demselben Grund: Er ändert sich
/// sechzigmal je Sekunde. Nach aussen gehen nur [TelegraphView]s.
class _BossState {
  BossMove? windingUp;
  double windupLeft = 0;
  double windupTotal = 1;

  double slamCooldown = ActionBalance.bossSlamCooldown / 2;

  /// Der erste Wurf kommt früh: Wer den Raum betritt, soll sofort sehen,
  /// dass hier jemand anderes wartet als Fussvolk.
  double throwCooldown = ActionBalance.bossFirstThrow;
  double chargeCooldown = 0;

  /// Der eigene Angriff von Slaad und Sumpftroll — Sprung und Pfütze.
  /// Auch er kommt früh, aus demselben Grund wie der erste Wurf.
  double signatureCooldown = ActionBalance.bossFirstThrow;

  Vec2 chargeDirection = Vec2.zero;
  double chargeLeft = 0;
  bool chargeHit = false;

  /// Wo die angekündigten Ringe liegen, wenn nicht um den Wächter:
  /// der Landeplatz des Sprungs, die Aufschläge der Pfützen.
  List<Vec2> targets = const <Vec2>[];

  /// Von wo der Slaad abgesprungen ist.
  Vec2 jumpFrom = Vec2.zero;

  /// Ob der laufende Sprung schon der zweite ist — sonst spränge er in
  /// Wut ohne Ende.
  bool secondJump = false;

  /// Wie lange noch, bis der zweite Kopf des Ettins wirft. Null oder
  /// weniger heisst: Es steht keiner aus.
  double secondThrowIn = 0;

  bool get isCharging => chargeLeft > 0;

  /// Wie weit die laufende Ankündigung ist, 0 bis 1.
  double get progress => (1 - windupLeft / windupTotal).clamp(0.0, 1.0);
}

extension _BossBrain on ActionWorld {
  /// Ein Schritt des Wächters.
  ///
  /// **Vorrang hat, was schon läuft:** ein Ansturm, dann eine Ankündigung.
  /// Erst danach wird neu gewählt — und was zur Wahl steht, hängt daran,
  /// welcher Wächter es ist ([BossKind]) und wie tief die Stufe liegt.
  /// Findet er nichts, läuft er heran und schlägt wie jeder andere.
  void _bossActs(ActionEntity boss, double abstand, double takt) {
    final zustand = _bossState ??= _BossState();
    final wut = boss.hpRatio <= ActionBalance.bossEnrageAt;
    if (wut && !_bossEnraged) {
      _bossEnraged = true;
      _events.add(BossEnraged(at: boss.position));
    }
    final uhr = takt * (wut ? ActionBalance.bossEnrageTempo : 1);
    zustand.slamCooldown -= uhr;
    zustand.throwCooldown -= uhr;
    zustand.chargeCooldown -= uhr;
    zustand.signatureCooldown -= uhr;

    if (zustand.isCharging) {
      _bossCharge(boss, zustand, takt);
      return;
    }

    if (zustand.secondThrowIn > 0) {
      zustand.secondThrowIn -= takt;
      if (zustand.secondThrowIn <= 0) {
        _bossThrow(boss, power: ActionBalance.ettinThrowPower);
      }
    }

    final geplant = zustand.windingUp;
    if (geplant != null) {
      zustand.windupLeft -= takt;
      if (geplant == BossMove.sprung) _bossFly(boss, zustand);
      if (zustand.windupLeft > 0) return;
      zustand.windingUp = null;
      _bossResolve(boss, zustand, geplant, wut);
      return;
    }

    final lage = _BossLage(
      abstand: abstand,
      sieht: _canSee(boss.position, _hero.position),
      wut: wut,
      // Ohne Stufe (Prototyp, Tests) kann er alles.
      stufe: stage?.number ?? PitStage.count,
    );
    final gewaehlt = switch (bossKind) {
      BossKind.zyklop => _zyklopWaehlt(boss, zustand, lage),
      BossKind.ettin => _ettinWaehlt(boss, zustand, lage),
      BossKind.slaad => _slaadWaehlt(boss, zustand, lage),
      BossKind.sumpftroll => _sumpftrollWaehlt(boss, zustand, lage),
    };
    if (!gewaehlt) _meleeActs(boss, abstand, takt);
  }

  // --- Was jeder wählt ---

  /// Bodenstoss, wenn der Held nah ist; Ansturm, wenn er wütend ist;
  /// Felswurf, wenn er weit weg ist.
  bool _zyklopWaehlt(ActionEntity boss, _BossState zustand, _BossLage lage) {
    if (_waehltStoss(zustand, lage)) return true;

    if (lage.wut &&
        lage.kenntDritten &&
        lage.sieht &&
        zustand.chargeCooldown <= 0 &&
        lage.abstand > ActionBalance.bossSlamRadius) {
      zustand.chargeCooldown = ActionBalance.bossChargeCooldown;
      zustand.chargeDirection = (_hero.position - boss.position).normalized;
      boss.facing = zustand.chargeDirection;
      _windUp(zustand, BossMove.ansturm, ActionBalance.bossChargeWindup);
      return true;
    }

    if (_darfWerfen(zustand, lage)) {
      zustand.throwCooldown = ActionBalance.bossThrowCooldown;
      _bossThrow(boss);
      return true;
    }
    return false;
  }

  /// Der Bodenstoss wie beim Zyklopen — der Nachstoss folgt von selbst
  /// ([_bossResolve]). Sein Wurf sind zwei Brocken, einer je Kopf: Der
  /// zweite kommt kurz danach und zielt neu.
  bool _ettinWaehlt(ActionEntity boss, _BossState zustand, _BossLage lage) {
    if (_waehltStoss(zustand, lage)) return true;

    if (_darfWerfen(zustand, lage)) {
      zustand.throwCooldown = ActionBalance.bossThrowCooldown;
      zustand.secondThrowIn = ActionBalance.ettinSecondThrowDelay;
      _bossThrow(boss, power: ActionBalance.ettinThrowPower);
      return true;
    }
    return false;
  }

  /// Springt, sobald er darf — auch aus der Nähe: Dann liegt der Ring
  /// auf dem Helden, und er muss weg. Dazwischen spuckt er.
  bool _slaadWaehlt(ActionEntity boss, _BossState zustand, _BossLage lage) {
    if (lage.sieht && zustand.signatureCooldown <= 0) {
      zustand.signatureCooldown = ActionBalance.slaadJumpCooldown;
      zustand.secondJump = false;
      _slaadSpringt(boss, zustand);
      return true;
    }

    if (_darfWerfen(zustand, lage)) {
      zustand.throwCooldown = ActionBalance.slaadSpitCooldown;
      _bossSpit(boss);
      return true;
    }
    return false;
  }

  /// Wirft Gift, sobald er darf; in Wut drei Pfützen statt einer. Aus der
  /// Nähe stampft er ab seiner zweiten Stufe.
  bool _sumpftrollWaehlt(
    ActionEntity boss,
    _BossState zustand,
    _BossLage lage,
  ) {
    if (lage.kenntZweiten && _waehltStoss(zustand, lage)) return true;

    if (lage.sieht && zustand.signatureCooldown <= 0) {
      zustand.signatureCooldown = ActionBalance.swampPuddleCooldown;
      final mitte = _hero.position;
      final ziele = <Vec2>[mitte];
      if (lage.wut && lage.kenntDritten) {
        // Zwei weitere quer zur Wurfrichtung — wer seitlich ausweicht,
        // muss sich für eine Lücke entscheiden.
        final hin = (mitte - boss.position).normalized;
        final quer = Vec2(-hin.y, hin.x) * ActionBalance.swampPuddleSpread;
        ziele
          ..add(mitte + quer)
          ..add(mitte - quer);
      }
      zustand.targets = List<Vec2>.unmodifiable(ziele);
      boss.facing = (mitte - boss.position).normalized;
      _windUp(zustand, BossMove.pfuetze, ActionBalance.swampPuddleWindup);
      return true;
    }
    return false;
  }

  bool _waehltStoss(_BossState zustand, _BossLage lage) {
    if (zustand.slamCooldown > 0 ||
        lage.abstand > ActionBalance.bossSlamRadius + _hero.radius) {
      return false;
    }
    zustand.slamCooldown = ActionBalance.bossSlamCooldown;
    _windUp(zustand, BossMove.bodenstoss, ActionBalance.bossSlamWindup);
    return true;
  }

  bool _darfWerfen(_BossState zustand, _BossLage lage) {
    return lage.kenntZweiten &&
        lage.sieht &&
        zustand.throwCooldown <= 0 &&
        lage.abstand >= ActionBalance.bossThrowMinRange;
  }

  void _windUp(_BossState zustand, BossMove move, double dauer) {
    zustand.windingUp = move;
    zustand.windupLeft = dauer;
    zustand.windupTotal = dauer;
  }

  // --- Was am Ende einer Ankündigung geschieht ---

  void _bossResolve(
    ActionEntity boss,
    _BossState zustand,
    BossMove move,
    bool wut,
  ) {
    switch (move) {
      case BossMove.bodenstoss:
        _ringHit(
          boss,
          boss.position,
          ActionBalance.bossSlamRadius,
          ActionBalance.bossSlamPower,
        );
        if (bossKind == BossKind.ettin) {
          _windUp(zustand, BossMove.nachstoss, ActionBalance.ettinSecondWindup);
        }
      case BossMove.nachstoss:
        _ringHit(
          boss,
          boss.position,
          ActionBalance.ettinSecondRadius,
          ActionBalance.ettinSecondPower,
        );
        zustand.throwCooldown = math.max(
          zustand.throwCooldown,
          ActionBalance.ettinBreathSeconds,
        );
      case BossMove.ansturm:
        zustand.chargeLeft = ActionBalance.bossChargeDuration;
        zustand.chargeHit = false;
      case BossMove.sprung:
        boss.position = zustand.targets.first;
        _ringHit(
          boss,
          boss.position,
          ActionBalance.slaadJumpRadius,
          ActionBalance.slaadJumpPower,
        );
        final stufe = stage?.number ?? PitStage.count;
        if (wut &&
            !zustand.secondJump &&
            stufe >= ActionBalance.bossChargeFromStage) {
          zustand.secondJump = true;
          // Die Pause zählt ab dem zweiten Sprung, nicht ab dem ersten —
          // sonst folgte auf zwei Sprünge fast sofort der nächste.
          zustand.signatureCooldown = ActionBalance.slaadJumpCooldown;
          _slaadSpringt(boss, zustand);
        }
      case BossMove.pfuetze:
        for (final ziel in zustand.targets) {
          _ringHit(
            boss,
            ziel,
            ActionBalance.swampPuddleRadius,
            ActionBalance.swampPuddleHitPower,
          );
          _zones.add(
            _Zone(
              center: ziel,
              radius: ActionBalance.swampPuddleRadius,
              seconds: ActionBalance.swampPuddleSeconds,
              tint: PitTint.gift,
              hostile: true,
            )..dotPerSecond = boss.attack * ActionBalance.swampPuddlePerSecond,
          );
        }
    }
  }

  /// Ein Ring schlägt ein: Wer drinsteht, wird getroffen.
  void _ringHit(ActionEntity boss, Vec2 mitte, double radius, double power) {
    _events.add(BossSlammed(at: mitte, radius: radius));
    final reichweite = radius + _hero.radius;
    if (mitte.distanceSquaredTo(_hero.position) <= reichweite * reichweite) {
      _hit(boss, _hero, powerFactor: power);
    }
  }

  /// Kündigt einen Sprung dorthin an, wo der Held gerade steht.
  ///
  /// **Der Landeplatz steht mit der Ankündigung fest** und wird schon
  /// hier aus der Wand gedrückt: Der Ring zeigt genau die Stelle, an der
  /// er aufkommt, nicht eine, die sich im Flug noch verschiebt.
  void _slaadSpringt(ActionEntity boss, _BossState zustand) {
    final landung = _pushOut(_hero.position, boss.radius) ?? boss.position;
    zustand.jumpFrom = boss.position;
    zustand.targets = <Vec2>[landung];
    final richtung = landung - boss.position;
    if (!richtung.isZero) boss.facing = richtung.normalized;
    _windUp(zustand, BossMove.sprung, ActionBalance.slaadJumpWindup);
  }

  /// Der Slaad in der Luft: Er rückt vom Absprung zum Landeplatz, über
  /// alles hinweg, was dazwischen steht. Die Höhe dazu kommt in
  /// [_hopHeight] — nur fürs Bild.
  void _bossFly(ActionEntity boss, _BossState zustand) {
    final ziel = zustand.targets.first;
    boss.position =
        zustand.jumpFrom + (ziel - zustand.jumpFrom) * zustand.progress;
  }

  /// Wie hoch der Wächter gerade springt — eine Parabel über die Dauer
  /// der Ankündigung, null ausserhalb eines Sprungs.
  double get _hopHeight {
    final zustand = _bossState;
    if (zustand == null || zustand.windingUp != BossMove.sprung) return 0;
    final t = zustand.progress;
    return ActionBalance.slaadJumpHeight * 4 * t * (1 - t);
  }

  /// Ein Felsbrocken auf den Helden.
  void _bossThrow(
    ActionEntity boss, {
    double power = ActionBalance.bossThrowPower,
  }) {
    final richtung = (_hero.position - boss.position).normalized;
    boss.facing = richtung;
    _events.add(
      AttackSwung(
        attackerId: boss.id,
        faction: Faction.gegner,
        from: boss.position,
        direction: richtung,
      ),
    );
    _projectiles.add(
      Projectile(
        id: _nextId++,
        faction: Faction.gegner,
        position: boss.position,
        velocity: richtung * ActionBalance.bossBoulderSpeed,
        damage: (boss.attack * power).round(),
        radius: ActionBalance.bossBoulderRadius,
        isBoulder: true,
      ),
    );
  }

  /// Der Slaad spuckt — kein Brocken, sondern ein schnelles Geschoss.
  void _bossSpit(ActionEntity boss) {
    final richtung = (_hero.position - boss.position).normalized;
    boss.facing = richtung;
    _events.add(
      AttackSwung(
        attackerId: boss.id,
        faction: Faction.gegner,
        from: boss.position,
        direction: richtung,
      ),
    );
    _projectiles.add(
      Projectile(
        id: _nextId++,
        faction: Faction.gegner,
        position: boss.position,
        velocity: richtung * ActionBalance.slaadSpitSpeed,
        damage: (boss.attack * ActionBalance.slaadSpitPower).round(),
        radius: ActionBalance.slaadSpitRadius,
      ),
    );
  }

  /// Rennt geradeaus, bis die Zeit um ist oder eine Wand bremst.
  void _bossCharge(ActionEntity boss, _BossState zustand, double takt) {
    zustand.chargeLeft -= takt;
    final vorher = boss.position;
    boss.position = _slide(
      boss.position,
      zustand.chargeDirection * (ActionBalance.bossChargeSpeed * takt),
      boss.radius,
    );

    if (!zustand.chargeHit) {
      final beruehrt = boss.radius + _hero.radius + 4;
      if (boss.position.distanceSquaredTo(_hero.position) <=
          beruehrt * beruehrt) {
        zustand.chargeHit = true;
        _hit(boss, _hero, powerFactor: ActionBalance.bossChargePower);
      }
    }

    // An der Wand ist Schluss — sonst schöbe er sich minutenlang dagegen.
    if (boss.position.distanceSquaredTo(vorher) < 0.01) {
      zustand.chargeLeft = 0;
    }
  }

  /// Was die Darstellung vom Wächter wissen muss.
  List<TelegraphView> _bossTelegraphs() {
    final zustand = _bossState;
    final geplant = zustand?.windingUp;
    final boss = _boss;
    if (zustand == null || geplant == null) return const <TelegraphView>[];
    if (boss == null || !boss.isAlive) return const <TelegraphView>[];

    TelegraphView ring(Vec2 mitte, double radius) => TelegraphView(
          move: geplant,
          origin: mitte,
          radius: radius,
          direction: Vec2.zero,
          length: 0,
          progress: zustand.progress,
        );

    return switch (geplant) {
      BossMove.bodenstoss => <TelegraphView>[
          ring(boss.position, ActionBalance.bossSlamRadius),
        ],
      BossMove.nachstoss => <TelegraphView>[
          ring(boss.position, ActionBalance.ettinSecondRadius),
        ],
      BossMove.sprung => <TelegraphView>[
          for (final ziel in zustand.targets)
            ring(ziel, ActionBalance.slaadJumpRadius),
        ],
      BossMove.pfuetze => <TelegraphView>[
          for (final ziel in zustand.targets)
            ring(ziel, ActionBalance.swampPuddleRadius),
        ],
      BossMove.ansturm => <TelegraphView>[
          TelegraphView(
            move: geplant,
            origin: boss.position,
            radius: boss.radius,
            direction: zustand.chargeDirection,
            length: ActionBalance.bossChargeSpeed *
                ActionBalance.bossChargeDuration,
            progress: zustand.progress,
          ),
        ],
    };
  }
}

/// Was der Wächter in diesem Schritt über seine Lage weiss — einmal
/// ausgerechnet, damit alle vier dieselben Fragen stellen.
class _BossLage {
  const _BossLage({
    required this.abstand,
    required this.sieht,
    required this.wut,
    required this.stufe,
  });

  final double abstand;
  final bool sieht;
  final bool wut;
  final int stufe;

  /// **Jeder lernt mit der Tiefe dazu**, auf denselben zwei Stufen: Der
  /// zweite Angriff kommt, wo der Zyklop zu werfen beginnt, der dritte,
  /// wo er anzustürmen beginnt.
  bool get kenntZweiten => stufe >= ActionBalance.bossThrowFromStage;
  bool get kenntDritten => stufe >= ActionBalance.bossChargeFromStage;
}

part of 'world.dart';

/// Was der Wächter gerade vorhat.
enum BossMove {
  /// Ein Ring um ihn füllt sich — wer dann noch drinsteht, wird getroffen.
  bodenstoss,

  /// Eine Linie zeigt die Richtung, dann rennt er los. Erst ab Wut.
  ansturm,
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

  bool get isRing => move == BossMove.bodenstoss;

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

  Vec2 chargeDirection = Vec2.zero;
  double chargeLeft = 0;
  bool chargeHit = false;

  bool get isCharging => chargeLeft > 0;
}

extension _BossBrain on ActionWorld {
  /// Ein Schritt des Wächters.
  ///
  /// Welche Angriffe er kennt, hängt an der Stufe
  /// ([ActionBalance.bossThrowFromStage], [ActionBalance.bossChargeFromStage]).
  ///
  /// **Vorrang hat, was schon läuft:** ein Ansturm, dann eine Ankündigung.
  /// Erst danach wird neu gewählt — Bodenstoss, wenn der Held nah ist;
  /// Felswurf, wenn er weit weg ist; Ansturm, wenn er wütend ist. Sonst
  /// läuft er heran und schlägt wie jeder andere.
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

    if (zustand.isCharging) {
      _bossCharge(boss, zustand, takt);
      return;
    }

    final geplant = zustand.windingUp;
    if (geplant != null) {
      zustand.windupLeft -= takt;
      if (zustand.windupLeft > 0) return;
      zustand.windingUp = null;
      switch (geplant) {
        case BossMove.bodenstoss:
          _bossSlam(boss);
        case BossMove.ansturm:
          zustand.chargeLeft = ActionBalance.bossChargeDuration;
          zustand.chargeHit = false;
      }
      return;
    }

    final sieht = _canSee(boss.position, _hero.position);
    // Ohne Stufe (Prototyp, Tests) kann er alles.
    final stufe = stage?.number ?? PitStage.count;
    final kannWerfen = stufe >= ActionBalance.bossThrowFromStage;
    final kannStuermen = stufe >= ActionBalance.bossChargeFromStage;

    if (zustand.slamCooldown <= 0 &&
        abstand <= ActionBalance.bossSlamRadius + _hero.radius) {
      zustand.slamCooldown = ActionBalance.bossSlamCooldown;
      _windUp(zustand, BossMove.bodenstoss, ActionBalance.bossSlamWindup);
      return;
    }

    if (wut &&
        kannStuermen &&
        sieht &&
        zustand.chargeCooldown <= 0 &&
        abstand > ActionBalance.bossSlamRadius) {
      zustand.chargeCooldown = ActionBalance.bossChargeCooldown;
      zustand.chargeDirection = (_hero.position - boss.position).normalized;
      boss.facing = zustand.chargeDirection;
      _windUp(zustand, BossMove.ansturm, ActionBalance.bossChargeWindup);
      return;
    }

    if (kannWerfen &&
        sieht &&
        zustand.throwCooldown <= 0 &&
        abstand >= ActionBalance.bossThrowMinRange) {
      zustand.throwCooldown = ActionBalance.bossThrowCooldown;
      _bossThrow(boss);
      return;
    }

    _meleeActs(boss, abstand, takt);
  }

  void _windUp(_BossState zustand, BossMove move, double dauer) {
    zustand.windingUp = move;
    zustand.windupLeft = dauer;
    zustand.windupTotal = dauer;
  }

  void _bossSlam(ActionEntity boss) {
    const radius = ActionBalance.bossSlamRadius;
    _events.add(BossSlammed(at: boss.position, radius: radius));
    final reichweite = radius + _hero.radius;
    if (boss.position.distanceSquaredTo(_hero.position) <=
        reichweite * reichweite) {
      _hit(boss, _hero, powerFactor: ActionBalance.bossSlamPower);
    }
  }

  void _bossThrow(ActionEntity boss) {
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
        damage: (boss.attack * ActionBalance.bossThrowPower).round(),
        radius: ActionBalance.bossBoulderRadius,
        isBoulder: true,
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
    if (zustand == null || geplant == null) return const <TelegraphView>[];

    ActionEntity? boss;
    for (final e in _entities) {
      if (e.kind == EnemyKind.endgegner && e.isAlive) boss = e;
    }
    if (boss == null) return const <TelegraphView>[];

    final fortschritt =
        (1 - zustand.windupLeft / zustand.windupTotal).clamp(0.0, 1.0);
    return <TelegraphView>[
      switch (geplant) {
        BossMove.bodenstoss => TelegraphView(
            move: geplant,
            origin: boss.position,
            radius: ActionBalance.bossSlamRadius,
            direction: Vec2.zero,
            length: 0,
            progress: fortschritt,
          ),
        BossMove.ansturm => TelegraphView(
            move: geplant,
            origin: boss.position,
            radius: boss.radius,
            direction: zustand.chargeDirection,
            length: ActionBalance.bossChargeSpeed *
                ActionBalance.bossChargeDuration,
            progress: fortschritt,
          ),
      },
    ];
  }
}

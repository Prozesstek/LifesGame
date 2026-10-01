part of 'world.dart';

/// Ein Kreischpilz, der gleich schreit — für einen Ring im Renderer.
///
/// **Keine [TelegraphView]:** Die kündigt an, was dem Helden schadet, und
/// der Bot läuft aus ihr hinaus. Ein Schrei schadet nicht; ihm entgeht
/// man nicht durch Weglaufen, sondern indem man den Pilz vorher fällt.
class AlarmView {
  const AlarmView({
    required this.origin,
    required this.radius,
    required this.progress,
  });

  final Vec2 origin;

  /// Wie weit der Schrei reichen wird.
  final double radius;

  /// 0 bei Beginn, 1 im Moment des Schreis.
  final double progress;
}

/// Was die Gegner der Besetzung tun (ADR-0062): Kreischpilz, Sporenpilz,
/// Wächterauge und der Schleim, der zerfällt.
///
/// In einer eigenen Datei, weil `world.dart` längst über der Grenze
/// liegt, die sich das Projekt gesetzt hat. Schleim und Grimlock stehen
/// hier nur mit ihren Werten: Sie laufen heran und schlagen wie Fussvolk
/// (`_meleeActs`); was sie besonders macht, geschieht beim Bemerken und
/// beim Sterben.
extension _Besetzung on ActionWorld {
  // --- Der Kreischpilz ---

  /// Hat er den Helden bemerkt, kündigt er seinen Schrei an. Einmal —
  /// danach ist er nur noch ein Pilz.
  void _shriekerActs(ActionEntity pilz, double takt) {
    if (pilz.spent) return;
    if (!pilz.isWindingUp) {
      pilz.windupTotal = ActionBalance.kreischerWindup;
      pilz.windupLeft = ActionBalance.kreischerWindup;
      return;
    }
    pilz.windupLeft -= takt;
    if (pilz.windupLeft > 0) return;

    pilz.spent = true;
    const radius = ActionBalance.kreischerRadiusOfScream;
    _events.add(EnemyScreamed(at: pilz.position, radius: radius));
    for (final gegner in _entities) {
      if (!gegner.isAlive || gegner.isHero || gegner.untouchable) continue;
      if (gegner.aggro) continue;
      // **Auch durch Wände.** Ein Schrei, den die Mauer schluckt, weckte
      // nur, wer den Helden ohnehin gleich sähe.
      if (gegner.position.distanceSquaredTo(pilz.position) > radius * radius) {
        continue;
      }
      gegner.aggro = true;
      _events.add(EnemyNoticed(id: gegner.id, at: gegner.position));
    }
  }

  /// Welche Kreischpilze gerade Luft holen.
  List<AlarmView> _alarms() {
    return <AlarmView>[
      for (final pilz in _entities)
        if (pilz.kind == EnemyKind.kreischer &&
            pilz.isAlive &&
            !pilz.spent &&
            pilz.isWindingUp)
          AlarmView(
            origin: pilz.position,
            radius: ActionBalance.kreischerRadiusOfScream,
            progress: pilz.windupProgress,
          ),
    ];
  }

  // --- Der Sporenpilz ---

  /// Hält Abstand und heilt im Takt, wer in seiner Nähe verletzt ist.
  ///
  /// **Nie sich selbst, nie einen anderen Sporenpilz, nie den Wächter.**
  /// Zwei, die einander heilen, wären ein Lauf ohne Ende; und der Wächter
  /// ist die eine Figur, deren Leben der Spieler als Balken liest.
  void _healerActs(ActionEntity pilz, double abstand, double takt) {
    _keepDistance(
      pilz,
      abstand,
      takt,
      preferred: ActionBalance.heilerPreferredRange,
      follow: ActionBalance.heilerFollowRange,
    );
    if (pilz.cooldownLeft > 0) return;

    const radius = ActionBalance.heilerHealRadius;
    var geheilt = false;
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      if (identical(ziel, pilz)) continue;
      if (ziel.kind == EnemyKind.heiler || ziel.kind == EnemyKind.endgegner) {
        continue;
      }
      if (ziel.hp >= ziel.maxHp) continue;
      if (ziel.position.distanceSquaredTo(pilz.position) > radius * radius) {
        continue;
      }
      final menge = math.max(
        1,
        (ziel.maxHp * ActionBalance.heilerHealShare).round(),
      );
      final vorher = ziel.hp;
      ziel.hp = math.min(ziel.maxHp, ziel.hp + menge);
      _events.add(
        EnemyHealed(
          targetId: ziel.id,
          at: ziel.position,
          amount: ziel.hp - vorher,
        ),
      );
      geheilt = true;
    }
    // Nur wenn es etwas zu heilen gab: Sonst wäre die Abklingzeit beim
    // ersten Treffer schon verbraucht.
    if (geheilt) pilz.cooldownLeft = pilz.attackCooldown;
  }

  // --- Das Wächterauge ---

  /// Auf Abstand bleiben, dann den Strahl aufladen. Während er lädt,
  /// steht es still, und die Linie steht fest.
  void _beamerActs(ActionEntity auge, double abstand, double takt) {
    if (auge.isWindingUp) {
      auge.windupLeft -= takt;
      if (auge.windupLeft <= 0) _fireBeam(auge);
      return;
    }

    _keepDistance(
      auge,
      abstand,
      takt,
      preferred: ActionBalance.archerPreferredRange,
      follow: ActionBalance.archerShootRange,
    );
    if (abstand > ActionBalance.archerShootRange) return;
    if (auge.cooldownLeft > 0) return;
    // Ein Strahl gegen die Wand wäre eine Ankündigung ohne Gefahr.
    if (!_canSee(auge.position, _hero.position)) return;

    auge.cooldownLeft = auge.attackCooldown;
    auge.aim = (_hero.position - auge.position).normalized;
    auge.windupTotal = ActionBalance.strahlerWindup;
    auge.windupLeft = ActionBalance.strahlerWindup;
  }

  void _fireBeam(ActionEntity auge) {
    final laenge = _beamLength(auge.position, auge.aim);
    final ende = auge.position + auge.aim * laenge;
    _events.add(
      BeamFired(
        from: auge.position,
        to: ende,
        width: ActionBalance.strahlerBeamHalfWidth * 2,
      ),
    );
    final linie = _beamView(auge, laenge);
    if (linie.covers(_hero.position, _hero.radius)) {
      _hit(auge, _hero, powerFactor: ActionBalance.strahlerBeamPower);
    }
  }

  /// Wie weit der Strahl von [from] in [richtung] kommt: bis zur ersten
  /// Wand, höchstens [ActionBalance.strahlerBeamLength].
  double _beamLength(Vec2 from, Vec2 richtung) {
    const schritt = ActionBalance.tileSize / 4;
    var weite = 0.0;
    while (weite < ActionBalance.strahlerBeamLength) {
      final naechste = math.min(
        weite + schritt,
        ActionBalance.strahlerBeamLength,
      );
      if (level.isWallAtPoint(from + richtung * naechste)) break;
      weite = naechste;
    }
    return weite;
  }

  TelegraphView _beamView(ActionEntity auge, double laenge) {
    return TelegraphView(
      move: BossMove.strahl,
      origin: auge.position,
      radius: ActionBalance.strahlerBeamHalfWidth,
      direction: auge.aim,
      length: laenge,
      progress: auge.windupProgress,
    );
  }

  /// Die Linien aller Augen, die gerade laden.
  List<TelegraphView> _beamTelegraphs() {
    return <TelegraphView>[
      for (final auge in _entities)
        if (auge.kind == EnemyKind.strahler && auge.isAlive && auge.isWindingUp)
          _beamView(auge, _beamLength(auge.position, auge.aim)),
    ];
  }

  // --- Der Schleim ---

  /// Die Schleimlinge, in die [schleim] zerfällt — schon wach, und sie
  /// hinterlassen nichts.
  List<ActionEntity> _splitOf(ActionEntity schleim) {
    final kinder = <ActionEntity>[];
    for (var i = 0; i < ActionBalance.schleimSplit; i++) {
      // Nebeneinander, quer zum Helden: So kommen sie von zwei Seiten.
      final zumHelden = (_hero.position - schleim.position).normalized;
      final quer =
          zumHelden.isZero ? const Vec2(1, 0) : Vec2(-zumHelden.y, zumHelden.x);
      final seite = i.isEven ? 1.0 : -1.0;
      final platz =
          schleim.position + quer * (seite * ActionBalance.schleimSplitOffset);
      final kind = _newEnemy(
        EnemyKind.schleimling,
        _pushOut(platz, ActionBalance.schleimlingRadius) ?? schleim.position,
      )
        ..aggro = true
        ..lootless = true;
      kinder.add(kind);
    }
    return kinder;
  }

  // --- Gemeinsames ---

  /// Bleibt auf Abstand zum Helden: weicht zurück, wenn er näher als
  /// [preferred] kommt, und läuft hinterher, wenn er weiter als [follow]
  /// weg ist. Dieselbe Bewegung wie beim Schützen (`_archerActs`).
  void _keepDistance(
    ActionEntity gegner,
    double abstand,
    double takt, {
    required double preferred,
    required double follow,
  }) {
    gegner.facing = (_hero.position - gegner.position).normalized;
    if (abstand < preferred * 0.8) {
      gegner.position = _slide(
        gegner.position,
        gegner.facing * (-gegner.speed * takt),
        gegner.radius,
      );
      return;
    }
    if (abstand <= follow) return;
    final richtung = _chaseDirection(gegner);
    if (richtung.isZero) return;
    gegner.position = _slide(
      gegner.position,
      richtung * (gegner.speed * takt),
      gegner.radius,
    );
    _trackProgress(gegner, takt);
  }

  /// Ein Gegner der Besetzung an [position], mit den Werten seiner Art.
  ActionEntity _newEnemy(EnemyKind kind, Vec2 position) {
    ActionEntity bauen({
      required int hp,
      required int attack,
      required int defense,
      required double radius,
      required double speed,
      required double range,
      required double cooldown,
    }) {
      return ActionEntity(
        id: _nextId++,
        faction: Faction.gegner,
        kind: kind,
        position: position,
        maxHp: _hp(hp),
        attack: _attack(attack),
        defense: _defense(defense),
        radius: radius,
        speed: speed,
        attackRange: range,
        attackCooldown: cooldown,
      );
    }

    return switch (kind) {
      EnemyKind.schleim => bauen(
          hp: ActionBalance.schleimHp,
          attack: ActionBalance.schleimAttack,
          defense: ActionBalance.schleimDefense,
          radius: ActionBalance.schleimRadius,
          speed: ActionBalance.schleimSpeed,
          range: ActionBalance.schleimAttackRange,
          cooldown: ActionBalance.schleimAttackCooldown,
        ),
      EnemyKind.schleimling => bauen(
          hp: ActionBalance.schleimlingHp,
          attack: ActionBalance.schleimlingAttack,
          defense: ActionBalance.schleimlingDefense,
          radius: ActionBalance.schleimlingRadius,
          speed: ActionBalance.schleimlingSpeed,
          range: ActionBalance.schleimlingAttackRange,
          cooldown: ActionBalance.schleimlingAttackCooldown,
        ),
      EnemyKind.grimlock => bauen(
          hp: ActionBalance.grimlockHp,
          attack: ActionBalance.grimlockAttack,
          defense: ActionBalance.grimlockDefense,
          radius: ActionBalance.grimlockRadius,
          speed: ActionBalance.grimlockSpeed,
          range: ActionBalance.grimlockAttackRange,
          cooldown: ActionBalance.grimlockAttackCooldown,
        ),
      // Er steht und schlägt nicht: Tempo und Reichweite null. Der
      // Angriff ist nie gefragt.
      EnemyKind.kreischer => bauen(
          hp: ActionBalance.kreischerHp,
          attack: 0,
          defense: ActionBalance.kreischerDefense,
          radius: ActionBalance.kreischerRadius,
          speed: 0,
          range: 0,
          cooldown: 1,
        ),
      EnemyKind.heiler => bauen(
          hp: ActionBalance.heilerHp,
          attack: 0,
          defense: ActionBalance.heilerDefense,
          radius: ActionBalance.heilerRadius,
          speed: ActionBalance.heilerSpeed,
          range: 0,
          cooldown: ActionBalance.heilerCooldown,
        ),
      EnemyKind.strahler => bauen(
          hp: ActionBalance.strahlerHp,
          attack: ActionBalance.strahlerAttack,
          defense: ActionBalance.strahlerDefense,
          radius: ActionBalance.strahlerRadius,
          speed: ActionBalance.strahlerSpeed,
          range: ActionBalance.archerShootRange,
          cooldown: ActionBalance.strahlerCooldown,
        ),
      EnemyKind.keiner ||
      EnemyKind.fussvolk ||
      EnemyKind.schuetze ||
      EnemyKind.endgegner ||
      EnemyKind.flink ||
      EnemyKind.brocken ||
      EnemyKind.flatterer =>
        throw ArgumentError('$kind entsteht in `_enemyFor`, nicht hier.'),
    };
  }
}

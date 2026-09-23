part of 'world.dart';

/// Was die Vorschau beim Halten zeigt — genau das, was beim Loslassen
/// geschieht. Die Welt rechnet es aus, der Renderer zeichnet es nur;
/// stünde die Rechnung zweimal da, zeigte die Vorschau irgendwann etwas
/// anderes, als dann passiert (`gotchas.md`, zwei Stellen für eine Frage).
sealed class AimPreview {
  const AimPreview({required this.tint});

  final PitTint tint;
}

/// Ein Geschoss: eine Bahn vom Helden bis zur Reichweite.
final class AimLine extends AimPreview {
  const AimLine({
    required super.tint,
    required this.from,
    required this.to,
    required this.width,
  });

  final Vec2 from;
  final Vec2 to;
  final double width;
}

/// Ein Schlag: ein Kegel vor dem Helden.
final class AimCone extends AimPreview {
  const AimCone({
    required super.tint,
    required this.origin,
    required this.direction,
    required this.range,
    required this.halfAngle,
  });

  final Vec2 origin;
  final Vec2 direction;
  final double range;

  /// Im Bogenmass, zu jeder Seite.
  final double halfAngle;
}

/// Ein Kreis — um den Helden oder dort, wo er abgesetzt wird.
final class AimCircle extends AimPreview {
  const AimCircle({
    required super.tint,
    required this.center,
    required this.radius,
    required this.castFrom,
    required this.castRange,
  });

  final Vec2 center;
  final double radius;

  /// Von wo und wie weit abgesetzt werden darf — der blasse Ring um den
  /// Helden. [castRange] 0 heisst: Der Kreis sitzt am Helden fest.
  final Vec2 castFrom;
  final double castRange;
}

/// Eine liegende Fläche, wie der Renderer sie sieht.
class ZoneView {
  const ZoneView({
    required this.center,
    required this.radius,
    required this.tint,
    required this.remaining,
  });

  final Vec2 center;
  final double radius;
  final PitTint tint;

  /// Wie viel ihrer Zeit noch übrig ist, 1 bis 0 — zum Ausblenden.
  final double remaining;
}

/// Eine abgesetzte Fläche, die liegen bleibt: Wer darin steht, wird
/// gebremst und nimmt Dauerschaden, solange sie liegt.
///
/// **Veränderlich**, wie Figuren und Geschosse — sie läuft ab.
class _Zone {
  _Zone({
    required this.center,
    required this.radius,
    required this.seconds,
    required this.tint,
  }) : secondsLeft = seconds;

  final Vec2 center;
  final double radius;
  final double seconds;
  final PitTint tint;
  double secondsLeft;

  /// 1 heisst: bremst nicht.
  double slowFactor = 1;

  /// Dauerschaden je Sekunde, schon in Punkten (Angriff eingerechnet).
  double dotPerSecond = 0;
}

/// Wohin eine Fähigkeit wirkt, einmal ausgerechnet.
class _CastPlan {
  const _CastPlan({required this.center, this.direction, this.placed = false});

  /// Der Mittelpunkt ihrer Flächen: der Held, oder der abgesetzte Punkt.
  final Vec2 center;

  /// Die Richtung bei [PitAim.richtung].
  final Vec2? direction;

  /// Ob sie abgesetzt wurde — dann bleiben Bremsen und Dauerschaden
  /// liegen, statt einmal zu wirken.
  final bool placed;
}

extension _Aim on ActionWorld {
  /// Wohin [ability] wirkt. [zielpunkt] null heisst: selbst zielen, wie
  /// beim kurzen Tippen. Null zurück heisst: Es gibt nichts, worauf sie
  /// von selbst zielen könnte — dann kostet sie nichts.
  _CastPlan? _plan(PitAbility ability, Vec2? zielpunkt) {
    final held = _hero.position;
    switch (ability.aim) {
      case PitAim.selbst:
      case PitAim.umDenHelden:
        return _CastPlan(center: held);

      case PitAim.richtung:
        if (zielpunkt != null && !(zielpunkt - held).isZero) {
          return _CastPlan(
            center: held,
            direction: (zielpunkt - held).normalized,
          );
        }
        final ziel = _autoTarget(ability);
        if (ziel == null) return null;
        return _CastPlan(center: held, direction: (ziel - held).normalized);

      case PitAim.bereich:
        final punkt = zielpunkt ?? _autoTarget(ability);
        if (punkt == null) return null;
        return _CastPlan(
          center: _placeable(punkt, ability.castRange),
          placed: true,
        );
    }
  }

  /// Wohin kurzes Tippen zielt: auf den nächsten Gegner, den der Held
  /// sieht und der in Reichweite liegt. Bei einem Schlag genügt die
  /// Reichweite, er geht nicht durch Wände.
  Vec2? _autoTarget(PitAbility ability) {
    final braucheSicht = ability.effects.any((e) => e is! StrikeNearest);
    // Ein Bereich darf auch einen Gegner erfassen, der knapp hinter der
    // Wurfweite steht — sein Rand reicht noch hin.
    final weite = ability.aim == PitAim.bereich
        ? ability.castRange + ability.areaRadius * 0.5
        : ability.reach;
    return _nearestEnemyWithin(weite, needsSight: braucheSicht)?.position;
  }

  /// [punkt], aber höchstens [weite] vom Helden entfernt. **Wände halten
  /// nichts auf**: Eine Fläche darf hinter Fels landen — gezielt ist
  /// gezielt, und ein Kreis, der vor der Wand hängen bleibt, fühlte sich
  /// wie ein verschluckter Wurf an.
  Vec2 _placeable(Vec2 punkt, double weite) {
    final held = _hero.position;
    var weg = punkt - held;
    if (weg.length > weite) weg = weg.normalized * weite;
    return held + weg;
  }

  /// Ein Geschoss des Helden in [richtung], das nach [weite] verlischt.
  void _shootAlong(
    Vec2 richtung, {
    required double power,
    required double weite,
    double leech = 0,
  }) {
    _hero.facing = richtung;
    _projectiles.add(
      Projectile(
        id: _nextId++,
        faction: Faction.held,
        position: _hero.position,
        velocity: richtung * ActionBalance.heroBoltSpeed,
        damage: 0,
        radius: ActionBalance.heroBoltRadius,
        heroPower: power,
        heroLeech: leech,
        maxAge: weite / ActionBalance.heroBoltSpeed,
      ),
    );
  }

  /// Der nächste Gegner in [weite], der vor dem Helden steht — höchstens
  /// [ActionBalance.strikeHalfAngle] neben [richtung].
  ActionEntity? _nearestInCone(Vec2 richtung, double weite) {
    ActionEntity? bester;
    var besteDistanz = double.infinity;
    final grenze = math.cos(ActionBalance.strikeHalfAngle);
    for (final ziel in _entities) {
      if (!ziel.isAlive || ziel.isHero || ziel.untouchable) continue;
      final weg = ziel.position - _hero.position;
      final abstand = weg.length;
      if (abstand > weite + ziel.radius || abstand >= besteDistanz) continue;
      if (abstand > 0) {
        final n = weg * (1 / abstand);
        if (n.x * richtung.x + n.y * richtung.y < grenze) continue;
      }
      besteDistanz = abstand;
      bester = ziel;
    }
    return bester;
  }

  /// Alle Gegner, deren Umriss den Kreis um [mitte] berührt.
  List<ActionEntity> _enemiesAround(Vec2 mitte, double radius) {
    return <ActionEntity>[
      for (final ziel in _entities)
        if (ziel.isAlive &&
            !ziel.isHero &&
            !ziel.untouchable &&
            mitte.distanceSquaredTo(ziel.position) <=
                (radius + ziel.radius) * (radius + ziel.radius))
          ziel,
    ];
  }

  /// Die liegende Fläche dieses Wirkens mit Umkreis [radius] — eine je
  /// Umkreis, damit Frost und Kälte desselben Nebels eine Fläche sind.
  _Zone _zoneFor(
    Map<double, _Zone> entwurf,
    _CastPlan plan,
    PitAbility ability,
    double radius,
    double sekunden,
  ) {
    final zone = entwurf.putIfAbsent(
      radius,
      () => _Zone(
        center: plan.center,
        radius: radius,
        seconds: sekunden,
        tint: ability.tint,
      ),
    );
    return zone;
  }

  /// Lässt die liegenden Flächen wirken und ablaufen.
  ///
  /// **Wer drinsteht, wird gerade eben gebremst und verbrannt** — kurz
  /// über den Takt hinaus, damit es nicht flackert, aber nicht länger:
  /// Wer herausläuft, ist es bald los. Das ist der Unterschied zu einem
  /// Kreis um den Helden, der einmal trifft und dann nachwirkt.
  void _tickZones(double dt) {
    for (final zone in _zones) {
      zone.secondsLeft -= dt;
      if (zone.secondsLeft <= 0) continue;
      _affect(zone);
    }
    _zones.removeWhere((z) => z.secondsLeft <= 0);
  }

  /// Bremst und verbrennt, wer gerade in [zone] steht.
  void _affect(_Zone zone) {
    for (final ziel in _enemiesAround(zone.center, zone.radius)) {
      if (zone.slowFactor < 1) {
        ziel.slowFactor = ziel.slowLeft > 0
            ? math.min(ziel.slowFactor, zone.slowFactor)
            : zone.slowFactor;
        ziel.slowLeft = math.max(ziel.slowLeft, ActionBalance.zoneLinger);
      }
      if (zone.dotPerSecond > 0) {
        _applyDot(ziel, zone.dotPerSecond, ActionBalance.zoneLinger);
      }
    }
  }

  /// Was beim Loslassen geschähe — für die Vorschau.
  AimPreview? _preview(PitAbility ability, Vec2? zielpunkt) {
    final held = _hero.position;
    switch (ability.aim) {
      case PitAim.selbst:
        return null;
      case PitAim.umDenHelden:
        return AimCircle(
          tint: ability.tint,
          center: held,
          radius: ability.areaRadius,
          castFrom: held,
          castRange: 0,
        );
      case PitAim.bereich:
        final plan = _plan(ability, zielpunkt);
        // Niemand in Reichweite und nicht gezielt: Der Kreis liegt
        // vorerst am Helden, damit man seine Grösse sieht.
        return AimCircle(
          tint: ability.tint,
          center: plan?.center ?? held,
          radius: ability.areaRadius,
          castFrom: held,
          castRange: ability.castRange,
        );
      case PitAim.richtung:
        final richtung =
            _plan(ability, zielpunkt)?.direction ?? _hero.facing.normalized;
        final istGeschoss = ability.effects.any((e) => e is BoltAtNearest);
        if (istGeschoss) {
          return AimLine(
            tint: ability.tint,
            from: held,
            to: held + richtung * ability.reach,
            width: ActionBalance.heroBoltRadius * 2,
          );
        }
        return AimCone(
          tint: ability.tint,
          origin: held,
          direction: richtung,
          range: ability.reach,
          halfAngle: ActionBalance.strikeHalfAngle,
        );
    }
  }
}

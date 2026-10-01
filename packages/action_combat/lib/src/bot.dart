import 'dart:math' as math;

import 'balance.dart';
import 'entity.dart';
import 'pit_ability.dart';
import 'vec2.dart';
import 'world.dart';

/// Ein Spieler ohne Bildschirm — für Simulationen, nicht fürs Spiel.
///
/// **Bewusst dumm.** Er läuft auf den nächsten Gegner zu und drückt seine
/// Plätze nach der Art ihrer Wirkung — Fläche bei einer Traube, Heilung
/// bei wenig Leben. Aus einer Ankündigung des Wächters läuft er heraus,
/// aus einer Giftpfütze ebenso; einem Felswurf weicht er nicht aus. Er weicht keinem Pfeil aus, er kitet
/// nicht, er sammelt Heilkugeln nur ein, wenn sie zufällig im Weg liegen.
/// Alles, was ein Mensch besser macht, fehlt — Zahlen aus seinen Läufen
/// sind eine **untere** Schranke, genau wie bei `tool/balance_sim.dart`.
///
/// Er liegt im Package statt in einem Beispiel, weil ihn zwei Stellen
/// brauchen: `example/headless_run.dart` und `tool/pit_sim.dart`.
abstract final class PitBot {
  /// Wie nah ein Gegner sein muss, damit der Bot ihn zur Traube zählt.
  static const double _nahe = 60;

  /// Höchstens so viele Sekunden je Lauf — ein Patt darf keine
  /// Simulation aufhängen.
  static const double timeLimit = 300;

  /// Spielt [world] bis zum Ende oder bis [timeLimit].
  static void play(ActionWorld world) {
    while (!world.isOver && world.elapsed < timeLimit) {
      _abilities(world);
      world.step(_input(world));
    }
  }

  static void _abilities(ActionWorld welt) {
    final held = welt.heroView;

    var nah = 0;
    for (final sicht in welt.views) {
      if (sicht.faction != Faction.gegner) continue;
      final reichweite = _nahe + sicht.radius;
      if (held.position.distanceSquaredTo(sicht.position) <=
          reichweite * reichweite) {
        nah++;
      }
    }

    _slots(welt, nah);
  }

  /// Die Plätze, nach der Art ihrer Wirkung — nicht nach Namen, damit
  /// eine neue Fähigkeit ohne Änderung hier mitgespielt wird.
  static void _slots(ActionWorld welt, int nah) {
    for (final ability in welt.slots) {
      if (!welt.canCast(ability.id)) continue;
      final lohnt = ability.effects.any(
        (effect) => switch (effect) {
          BoltAtNearest() => true,
          StrikeNearest() => nah >= 1,
          StrikeAround() => nah >= 2,
          HealSelf() => welt.heroHpRatio < 0.5,
          GainMana() => welt.manaRatio < 0.3,
          ReduceIncoming() => nah >= 3 || welt.heroHpRatio < 0.4,
          ReflectIncoming() => nah >= 3,
          SlowAround() => nah >= 2,
          DamageOverTime() => nah >= 2,
        },
      );
      if (lohnt) welt.cast(ability.id);
    }
  }

  /// Die Richtung aus einem Kreis um [mitte] mit [radius] hinaus.
  ///
  /// Geradewegs von der Mitte weg — es sei denn, auf dem Weg bis über den
  /// Rand steht eine Wand, oder der Held steht genau in der Mitte (der
  /// Ring eines Sprungs liegt auf ihm). Dann unter den acht Richtungen
  /// die freie, die am ehesten von der Mitte wegführt. Ohne das lief er
  /// vor einem Sprung zuverlässig in die nächste Wand und nahm ihn voll.
  static Vec2 _hinaus(
    ActionWorld welt,
    EntityView held,
    Vec2 mitte,
    double radius,
  ) {
    final weg = held.position - mitte;

    /// Ob der Weg in [richtung] bis über den Rand frei ist — abgetastet
    /// in halben Feldern, mit der Breite des Helden.
    bool frei(Vec2 richtung) {
      // Wie weit es in dieser Richtung bis zum Rand ist: die Sehne des
      // Kreises vom Helden aus.
      final laengs = weg.x * richtung.x + weg.y * richtung.y;
      final quer2 = weg.x * weg.x + weg.y * weg.y - laengs * laengs;
      final r = radius + held.radius;
      final sehne = -laengs + _wurzel(r * r - quer2);
      const schritt = ActionBalance.tileSize / 2;
      for (var d = schritt; d < sehne + schritt; d += schritt) {
        final punkt = held.position + richtung * d;
        for (final seite in <Vec2>[
          Vec2.zero,
          Vec2(-richtung.y, richtung.x) * held.radius,
          Vec2(richtung.y, -richtung.x) * held.radius,
        ]) {
          if (welt.level.isWallAtPoint(punkt + seite)) return false;
        }
      }
      return true;
    }

    if (weg.length > 1 && frei(weg.normalized)) return weg.normalized;

    const s = 0.7071;
    const richtungen = <Vec2>[
      Vec2(1, 0),
      Vec2(-1, 0),
      Vec2(0, 1),
      Vec2(0, -1),
      Vec2(s, s),
      Vec2(-s, s),
      Vec2(s, -s),
      Vec2(-s, -s),
    ];
    Vec2? beste;
    var besteNaehe = double.negativeInfinity;
    for (final richtung in richtungen) {
      if (!frei(richtung)) continue;
      // Unter den freien die, die am ehesten von der Mitte wegführt.
      final naehe = weg.x * richtung.x + weg.y * richtung.y;
      if (naehe > besteNaehe) {
        besteNaehe = naehe;
        beste = richtung;
      }
    }
    return beste ?? (weg.isZero ? const Vec2(1, 0) : weg.normalized);
  }

  static double _wurzel(double wert) => wert <= 0 ? 0 : math.sqrt(wert);

  /// Lauf auf den nächsten Gegner zu — **am Weg entlang**, nicht
  /// Luftlinie. Der erste Versuch ohne Wegfindung kam über zwei Gegner
  /// nicht hinaus.
  static Vec2 _input(ActionWorld welt) {
    final held = welt.heroView;

    // **Zuerst raus aus jeder Ankündigung des Wächters** — das Einzige,
    // was dieser Bot vorausschauend tut. Ohne das misst die Simulation
    // einen Spieler, der jeden Bodenstoss voll nimmt, und der Wächter
    // wäre für sie viel härter, als er für einen Menschen ist.
    for (final zone in welt.telegraphs) {
      if (!zone.covers(held.position, held.radius)) continue;
      if (zone.isRing) {
        return _hinaus(welt, held, zone.origin, zone.radius);
      }
      // Zur Seite, auf die kürzere.
      final quer = Vec2(-zone.direction.y, zone.direction.x);
      final seite = (held.position - zone.origin).x * quer.x +
          (held.position - zone.origin).y * quer.y;
      return seite >= 0 ? quer : quer * -1;
    }

    // Und raus aus allem, was liegt und schadet — die Pfütze des
    // Sumpftrolls. Wer darin stehen bleibt, misst nicht den Wächter,
    // sondern die eigene Sturheit.
    for (final flaeche in welt.zones) {
      if (!flaeche.hostile) continue;
      final r = flaeche.radius + held.radius;
      if (flaeche.center.distanceSquaredTo(held.position) > r * r) continue;
      return _hinaus(welt, held, flaeche.center, flaeche.radius);
    }

    Vec2? ziel;
    var beste = 1 << 29;

    for (final sicht in welt.views) {
      if (sicht.faction != Faction.gegner) continue;
      final distanz = welt.pathDistanceTo(sicht.position);
      if (distanz == null || distanz >= beste) continue;
      beste = distanz;
      ziel = sicht.position;
    }

    // Niemand zu sehen: dann zum Wächter, der in seinem Raum schläft.
    ziel ??= welt.sleepingBossAt;
    if (ziel == null) return Vec2.zero;

    final direkt = ziel - held.position;
    if (direkt.length <= ActionBalance.tileSize * 1.5) {
      return direkt.normalized;
    }
    return welt.fieldTo(ziel).directionFrom(held.position);
  }
}

import 'balance.dart';
import 'entity.dart';
import 'pit_ability.dart';
import 'vec2.dart';
import 'world.dart';

/// Ein Spieler ohne Bildschirm — für Simulationen, nicht fürs Spiel.
///
/// **Bewusst dumm.** Er läuft auf den nächsten Gegner zu und drückt seine
/// Plätze nach der Art ihrer Wirkung — Fläche bei einer Traube, Heilung
/// bei wenig Leben. Er weicht keinem Pfeil aus, er kitet
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

  /// Lauf auf den nächsten Gegner zu — **am Weg entlang**, nicht
  /// Luftlinie. Der erste Versuch ohne Wegfindung kam über zwei Gegner
  /// nicht hinaus.
  static Vec2 _input(ActionWorld welt) {
    final held = welt.heroView;
    Vec2? ziel;
    var beste = 1 << 29;

    for (final sicht in welt.views) {
      if (sicht.faction != Faction.gegner) continue;
      final distanz = welt.pathDistanceTo(sicht.position);
      if (distanz == null || distanz >= beste) continue;
      beste = distanz;
      ziel = sicht.position;
    }

    if (ziel == null) return Vec2.zero;

    final direkt = ziel - held.position;
    if (direkt.length <= ActionBalance.tileSize * 1.5) {
      return direkt.normalized;
    }
    return welt.fieldTo(ziel).directionFrom(held.position);
  }
}

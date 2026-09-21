import 'ability.dart';
import 'balance.dart';
import 'entity.dart';
import 'vec2.dart';
import 'world.dart';

/// Ein Spieler ohne Bildschirm — für Simulationen, nicht fürs Spiel.
///
/// **Bewusst dumm.** Er läuft auf den nächsten Gegner zu, drückt den
/// Rundumschlag, wenn drei in Reichweite stehen, und den Sturmschritt,
/// wenn es eng und knapp wird. Er weicht keinem Pfeil aus, er kitet
/// nicht, er sammelt Heilkugeln nur ein, wenn sie zufällig im Weg liegen.
/// Alles, was ein Mensch besser macht, fehlt — Zahlen aus seinen Läufen
/// sind eine **untere** Schranke, genau wie bei `tool/balance_sim.dart`.
///
/// Er liegt im Package statt in einem Beispiel, weil ihn zwei Stellen
/// brauchen: `example/headless_run.dart` und `tool/pit_sim.dart`.
abstract final class PitBot {
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
    final spec = ActionBalance.abilities[ActionAbility.rundumschlag]!;

    var nah = 0;
    for (final sicht in welt.views) {
      if (sicht.faction != Faction.gegner) continue;
      final reichweite = spec.radius + sicht.radius;
      if (held.position.distanceSquaredTo(sicht.position) <=
          reichweite * reichweite) {
        nah++;
      }
    }

    if (nah >= 3) welt.useAbility(ActionAbility.rundumschlag);
    if (nah >= 2 && welt.heroHpRatio < 0.35) {
      welt.useAbility(ActionAbility.sturmschritt);
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

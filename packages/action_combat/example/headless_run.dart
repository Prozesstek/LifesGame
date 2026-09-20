import 'package:action_combat/action_combat.dart';

/// Spielt die Halle **ohne Bildschirm** durch — mit drei Machtstufen.
///
/// Das ist der Grund, warum der Echtzeit-Kampf ein eigenes Package ist
/// und nicht in Flame lebt. Die Frage, die den Prototyp ausgelöst hat,
/// lautet: „Fühlt sich der Kampf belohnender an, wenn man stärker wird?"
/// Hier steht die Antwort als Zahl, bevor jemand sie als Gefühl behauptet.
///
/// ```bash
/// cd packages/action_combat
/// dart run example/headless_run.dart
/// ```
///
/// Der Bot ist bewusst dumm: Er läuft auf den nächsten Gegner zu und
/// lässt den Automatikschlag arbeiten. Er weicht nicht aus, er kitet
/// nicht. Alles, was ein Mensch besser macht, fehlt — die Zahlen sind
/// damit eine **untere** Schranke, genau wie bei `tool/balance_sim.dart`.
void main() {
  print('Die Grube — ${LevelCatalog.grube.spawns.length} Gegner\n');

  final stufen = <String, ActionStats>{
    'Tag 0': ActionStats.frisch,
    'Decke heute': ActionStats.gereift,
    'mit Potenz': ActionStats.mitPotenz,
  };

  print(
    '  ${'Stufe'.padRight(14)}'
    '${'ATK'.padLeft(5)}'
    '${'Ausgang'.padLeft(10)}'
    '${'Dauer'.padLeft(9)}'
    '${'je Gegner'.padLeft(11)}'
    '${'HP übrig'.padLeft(10)}',
  );

  for (final eintrag in stufen.entries) {
    final ergebnis = _lauf(eintrag.value);
    final jeGegner =
        ergebnis.kills == 0 ? 0.0 : ergebnis.sekunden / ergebnis.kills;

    print(
      '  ${eintrag.key.padRight(14)}'
      '${eintrag.value.attack.toString().padLeft(5)}'
      '${(ergebnis.gewonnen ? 'geschafft' : 'gefallen').padLeft(10)}'
      '${'${ergebnis.sekunden.toStringAsFixed(0)} s'.padLeft(9)}'
      '${'${jeGegner.toStringAsFixed(1)} s'.padLeft(11)}'
      '${'${(ergebnis.hpAnteil * 100).round()} %'.padLeft(10)}',
    );
  }

  print('''

  „je Gegner" ist die Zahl, um die es geht: Sie sagt, wie schnell etwas
  unter einem zerfällt. Steht sie über alle drei Zeilen fast gleich, dann
  fühlt sich Stärkerwerden nicht belohnend an — und daran ändert auch
  eine Echtzeit-Darstellung nichts.''');
}

class _Ergebnis {
  const _Ergebnis({
    required this.gewonnen,
    required this.sekunden,
    required this.kills,
    required this.hpAnteil,
  });

  final bool gewonnen;
  final double sekunden;
  final int kills;
  final double hpAnteil;
}

/// Höchstens fünf Minuten je Lauf — ein Patt darf die Ausgabe nicht
/// aufhängen. Dieselbe Vorsichtsmassnahme wie `_rundenDeckel` in
/// `tool/balance_sim.dart`.
const double _zeitDeckel = 300;

_Ergebnis _lauf(ActionStats stats) {
  final welt = ActionWorld(
    level: LevelCatalog.grube,
    heroStats: stats,
    seed: 7,
  );

  while (!welt.isOver && welt.elapsed < _zeitDeckel) {
    welt.step(_botEingabe(welt));
  }

  return _Ergebnis(
    gewonnen: welt.isWon,
    sekunden: welt.elapsed,
    kills: welt.kills,
    hpAnteil: welt.heroHpRatio,
  );
}

/// Lauf auf den nächsten Gegner zu. Mehr kann der Bot nicht.
///
/// „Nächster" heisst **am Weg entlang**, nicht Luftlinie: Sonst rennt er
/// gegen die Wand, hinter der jemand steht. Die Halle hat vier Räume —
/// der erste Versuch ohne Wegfindung kam über zwei Gegner nicht hinaus.
Vec2 _botEingabe(ActionWorld welt) {
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

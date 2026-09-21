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
/// Gespielt wird von [PitBot] — bewusst dumm, die Zahlen sind damit eine
/// **untere** Schranke. Wie hart die dreissig Stufen sind, misst
/// `tool/pit_sim.dart` in der App, mit der echten Werte-Kurve.
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
    '${'Kugeln'.padLeft(9)}'
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
      '${ergebnis.kugeln.toString().padLeft(9)}'
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
    required this.kugeln,
  });

  final bool gewonnen;
  final double sekunden;
  final int kills;
  final double hpAnteil;
  final int kugeln;
}

_Ergebnis _lauf(ActionStats stats) {
  final welt = ActionWorld(
    level: LevelCatalog.grube,
    heroStats: stats,
    seed: 7,
  );

  PitBot.play(welt);

  return _Ergebnis(
    gewonnen: welt.isWon,
    sekunden: welt.elapsed,
    kills: welt.kills,
    hpAnteil: welt.heroHpRatio,
    kugeln: welt.orbsCollected,
  );
}

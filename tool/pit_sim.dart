// Die Grube über alle dreissig Stufen, gespielt mit der echten
// Werte-Kurve (ADR-0039).
//
// Das Gegenstück zum Abschnitt „Die Reihe" in `tool/balance_sim.dart`:
// Dort stand, welche Sprosse ein Charakter nach N Tagen schlägt. Hier
// steht dasselbe für die Stufen der Grube. Der Spieler ist `PitBot` —
// bewusst dumm, die Quoten sind also eine **untere** Schranke.
//
// Reines Dart trotz Flutter-Projekt: kein Import zieht Flutter herein.
//
//     dart run tool/pit_sim.dart          # 12 Läufe je Feld
//     dart run tool/pit_sim.dart 40

import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';

void main(List<String> args) {
  final laeufe = args.isEmpty ? 12 : int.parse(args.first);

  // „+F" heisst: drei Fähigkeiten auf den Plätzen — Funkenstoß,
  // Steinhaut, Blütentau, also Schaden, Schutz und Heilung, alle drei über
  // den Baum früh erreichbar. Der Vergleich zur Spalte links daneben ist
  // ihr Beitrag.
  //
  // Die Waffe: ohne Laden der Kurzbogen, den jeder trägt (ADR-0016);
  // ausgerüstet die Waffe des besten Satzes.
  // Plätzen. Der Vergleich zur Spalte links daneben ist ihr Beitrag.
  const drei = <String>['funkenstoss', 'steinhaut', 'bluetentau'];
  const bogen = 'basic_attack';
  final gut = _besteWaffe();
  final spalten = <String, _Spalte>{
    'Tag 0': _Spalte(_statsNach(0), bogen),
    'Tag 14': _Spalte(_statsNach(14), bogen),
    'Tag 30': _Spalte(_statsNach(30), bogen),
    'Tag 30+F': _Spalte(_statsNach(30), bogen, drei),
    'Tag 60+G': _Spalte(
      _statsNach(60, bonus: _bestesGear()),
      gut,
      const <String>[],
      _legendaereKraefte(),
    ),
    'T60+G+F': _Spalte(
      _statsNach(60, bonus: _bestesGear()),
      gut,
      drei,
      _legendaereKraefte(),
    ),
  };

  print('Die Grube — $laeufe Läufe je Feld, jede Karte neu gebaut\n');
  for (final e in spalten.entries) {
    final s = e.value.stats;
    print(
      '  ${e.key.padRight(9)} ATK ${s.attack}  HP ${s.maxHp}  '
      'DEF ${s.defense}  EN ${s.energy}',
    );
  }
  print('');

  print(
    '  ${'Stufe'.padRight(7)}'
    '${spalten.keys.map((k) => k.padLeft(10)).join()}',
  );

  for (var stufe = 1; stufe <= PitStage.count; stufe++) {
    final zeile = StringBuffer('  ${stufe.toString().padRight(7)}');
    for (final spalte in spalten.values) {
      zeile.write('${_quote(stufe, spalte, laeufe)} %'.padLeft(10));
    }
    print(zeile);
  }
}

class _Spalte {
  const _Spalte(
    this.stats,
    this.weapon, [
    this.abilities = const <String>[],
    this.modifiers = const <PitModifier>[],
  ]);

  final ActionStats stats;
  final String weapon;
  final List<String> abilities;

  /// Die legendären Kräfte der getragenen Stücke.
  final List<PitModifier> modifiers;
}

int _quote(int stufe, _Spalte spalte, int laeufe) {
  var siege = 0;
  for (var seed = 0; seed < laeufe; seed++) {
    final stage = PitStage(stufe);
    final welt = ActionWorld(
      level: LevelBuilder.build(stage: stage, seed: seed),
      heroStats: spalte.stats,
      stage: stage,
      abilityIds: spalte.abilities,
      weaponMoveId: spalte.weapon,
      modifiers: spalte.modifiers,
      seed: seed,
    );
    PitBot.play(welt);
    if (welt.isWon) siege++;
  }
  return (siege * 100 / laeufe).round();
}

/// Derselbe Aufbau wie in `tool/balance_sim.dart`: die ersten fünf
/// Vorlagen, jeden Tag abgehakt.
ActionStats _statsNach(int tage, {GearBonus bonus = const GearBonus()}) {
  final gewaehlt = HabitCatalog.all
      .take(HabitRewards.maxActiveHabits)
      .map((t) => t.id)
      .toList();

  var tracker = const HabitTracker.empty();
  for (final id in gewaehlt) {
    tracker = tracker.activate(id);
  }

  var tag = const Day(2026, 1, 1);
  for (var i = 0; i < tage; i++) {
    for (final id in gewaehlt) {
      tracker = tracker.check(id, tag).tracker;
    }
    tag = tag.next;
  }

  final s = tracker.stats;
  return ActionStats(
    attack: s.attack + bonus.attack,
    maxHp: s.maxHp + bonus.maxHp,
    defense: s.defense + bonus.defense,
    energy: s.maxEnergy + bonus.maxEnergy,
  );
}

/// Das beste Stück je Platz — dieselbe grobe Rechnung wie in
/// `tool/balance_sim.dart`.
/// Das beste Stück je Platz — dieselbe grobe Rechnung wie in
/// `tool/balance_sim.dart`: die grösste Summe aus den vier Werten.
List<GearItem> _besteStuecke() {
  return <GearItem>[for (final slot in GearSlot.values) _bestesIn(slot)];
}

GearItem _bestesIn(GearSlot slot) {
  final stuecke = GearCatalog.forSlot(slot);
  var bestes = stuecke.first;
  var besteSumme = -1;
  for (final item in stuecke) {
    final wert =
        item.bonus.attack * 8 +
        item.bonus.maxHp +
        item.bonus.defense * 8 +
        item.bonus.maxEnergy * 8;
    if (wert > besteSumme) {
      besteSumme = wert;
      bestes = item;
    }
  }
  return bestes;
}

GearBonus _bestesGear() {
  var summe = const GearBonus();
  for (final item in _besteStuecke()) {
    summe = summe + item.bonus;
  }
  return summe;
}

/// Die legendären Kräfte der besten Stücke. Sets rechnet die Simulation
/// nicht: Die besten Stücke je Platz sind kein Set.
List<PitModifier> _legendaereKraefte() {
  return <PitModifier>[
    for (final item in _besteStuecke())
      ...?PitLegendaries.byId(item.legendaryPower)?.modifiers,
  ];
}

/// Der Waffenzug der Waffe, die `_besteStuecke` auf den Waffenplatz legt.
String _besteWaffe() {
  return AbilityCatalog.weaponMoveFor(_bestesIn(GearSlot.waffe).id);
}

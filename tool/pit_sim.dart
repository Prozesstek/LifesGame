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
//     dart run tool/pit_sim.dart mana     # nur: bremst Mana?
//     dart run tool/pit_sim.dart faehigkeiten   # nur: je Fähigkeit

import 'package:abilities/abilities.dart';
import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

void main(List<String> args) {
  // `mana` als erstes Argument rechnet nur die Mana-Tabelle (ADR-0073).
  if (args.isNotEmpty && args.first == 'mana') {
    _mana(args.length > 1 ? int.parse(args[1]) : 12);
    return;
  }
  // `faehigkeiten` rechnet nur die Tabelle je Fähigkeit (ADR-0074).
  if (args.isNotEmpty && args.first == 'faehigkeiten') {
    _jeFaehigkeit(args.length > 1 ? int.parse(args[1]) : 12);
    return;
  }
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
      _statsNach(60, bonus: _bestesGear(), mitSeltenheit: true),
      gut,
      const <String>[],
      _legendaereKraefte(),
    ),
    'T60+G+F': _Spalte(
      _statsNach(60, bonus: _bestesGear(), mitSeltenheit: true),
      gut,
      drei,
      _legendaereKraefte(),
    ),
  };

  print('Die Grube — $laeufe Läufe je Feld, jede Karte neu gebaut\n');
  for (final e in spalten.entries) {
    final s = e.value.stats;
    print(
      '  ${e.key.padRight(9)} ATK ${s.combatAttack}  HP ${s.combatMaxHp}  '
      'DEF ${s.combatDefense}  EN ${s.energy}  '
      '(×${s.damageMultiplier.toStringAsFixed(2)} Schaden)',
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

  _jeWaechter(spalten, laeufe);
  _jeBesetzung(spalten, laeufe);
  _mana(laeufe);
}

/// **Bremst Mana?** (ADR-0073) Je Tag und Satz: wie oft der Bot gewirkt
/// hat, und in welchem Anteil der Zeit ein Platz bereit war, sich gelohnt
/// hätte — und am Mana hing.
///
/// Zwei Sätze: die drei aus „+F“ (Schaden, Schutz, Heilung) und drei
/// Angriffe, die man im Takt drückt (Funkenstoß, Klingenwirbel,
/// Donnerkeil). Der zweite ist der, an dem sich zeigt, ob Mana bremst —
/// der erste wirkt zwei seiner drei nur in Not.
///
/// Gesucht ist, was ADR-0073 verlangt: Wer alle drei im Takt drückt, ist
/// nach 10 bis 15 Sekunden leer. „Am Mana“ also deutlich über null,
/// auch an Tag 60.
void _mana(int laeufe) {
  const drei = <String>['funkenstoss', 'steinhaut', 'bluetentau'];
  const angriff = <String>['funkenstoss', 'klingenwirbel', 'donnerkeil'];
  final tage = <(String, ActionStats, String, int)>[
    ('Tag 0', _statsNach(0), 'basic_attack', 1),
    ('Tag 30', _statsNach(30), 'basic_attack', 11),
    (
      'Tag 60+G',
      _statsNach(60, bonus: _bestesGear(), mitSeltenheit: true),
      _besteWaffe(),
      25,
    ),
  ];

  print('Mana — wie oft ein Platz am Mana hängt (ADR-0073)\n');
  print(
    '  ${''.padRight(10)}${'Mana'.padLeft(6)}${'/s'.padLeft(6)}'
    '${'Stufe'.padLeft(7)}'
    '${'+F am Mana'.padLeft(12)}${'Würfe/min'.padLeft(11)}'
    '${'Angr. am Mana'.padLeft(15)}${'Würfe/min'.padLeft(11)}',
  );
  for (final (name, stats, waffe, stufe) in tage) {
    final a = _manaLauf(stats, waffe, stufe, drei, laeufe);
    final b = _manaLauf(stats, waffe, stufe, angriff, laeufe);
    print(
      '  ${name.padRight(10)}${'${stats.maxMana}'.padLeft(6)}'
      '${stats.manaRegen.toStringAsFixed(1).padLeft(6)}'
      '${'$stufe'.padLeft(7)}'
      '${'${(a.starvedShare * 100).round()} %'.padLeft(12)}'
      '${a.castsPerMinute.toStringAsFixed(0).padLeft(11)}'
      '${'${(b.starvedShare * 100).round()} %'.padLeft(15)}'
      '${b.castsPerMinute.toStringAsFixed(0).padLeft(11)}',
    );
  }
  print('');
}

PitManaLog _manaLauf(
  ActionStats stats,
  String waffe,
  int stufe,
  List<String> faehigkeiten,
  int laeufe,
) {
  final log = PitManaLog();
  for (var seed = 0; seed < laeufe; seed++) {
    final stage = PitStage(stufe);
    final welt = ActionWorld(
      level: LevelBuilder.build(stage: stage, seed: seed),
      heroStats: stats,
      stage: stage,
      abilityIds: faehigkeiten,
      weaponMoveId: waffe,
      seed: seed,
    );
    PitBot.play(welt, mana: log);
    log.addRun(welt);
  }
  return log;
}

/// **Je Fähigkeit** (ADR-0074): Was trägt eine einzelne? Sie ersetzt den
/// Funkenstoß im Satz „+F“ — Steinhaut und Blütentau bleiben —, an Tag 30
/// auf Stufe 11 und 13. Darunter jede Ultimate, zusätzlich zu „+F“.
///
/// **Der Bot ist dumm**: Er springt nicht gezielt, pariert nicht im
/// richtigen Augenblick und spult nicht zurück, wenn es sich lohnt. Wer
/// zielt, liegt darüber; die Zahlen sind eine untere Schranke, und ein
/// Abstand zwischen zwei Zeilen sagt mehr als die Zeile selbst.
void _jeFaehigkeit(int laeufe) {
  final stats = _statsNach(30);
  const bogen = 'basic_attack';
  const rest = <String>['steinhaut', 'bluetentau'];
  const stufen = <int>[11, 13];

  print(
    'Je Fähigkeit — Tag 30, statt Funkenstoß neben Steinhaut und '
    'Blütentau, $laeufe Läufe je Feld\n',
  );
  final kopf = StringBuffer('  ${''.padRight(26)}');
  for (final stufe in stufen) {
    kopf.write('Stufe $stufe'.padLeft(10));
  }
  print(kopf);

  for (final ability in PitAbilities.all) {
    if (rest.contains(ability.id)) continue;
    final zeile = StringBuffer('  ${ability.name.padRight(26)}');
    for (final stufe in stufen) {
      final quote = _siegquote(
        stufe,
        stats,
        bogen,
        <String>[ability.id, ...rest],
        null,
        laeufe,
      );
      zeile.write('$quote %'.padLeft(10));
    }
    print(zeile);
  }

  print('\n  Ultimate, zusätzlich zu Funkenstoß, Steinhaut, Blütentau');
  for (final ult in <PitAbility?>[null, ...PitAbilities.ultimates]) {
    final zeile = StringBuffer('  ${(ult?.name ?? 'ohne').padRight(26)}');
    for (final stufe in stufen) {
      final quote = _siegquote(
        stufe,
        stats,
        bogen,
        const <String>['funkenstoss', ...rest],
        ult?.id,
        laeufe,
      );
      zeile.write('$quote %'.padLeft(10));
    }
    print(zeile);
  }
  print('');
}

int _siegquote(
  int stufe,
  ActionStats stats,
  String waffe,
  List<String> faehigkeiten,
  String? ultimate,
  int laeufe,
) {
  var siege = 0;
  for (var seed = 0; seed < laeufe; seed++) {
    final stage = PitStage(stufe);
    final welt = ActionWorld(
      level: LevelBuilder.build(stage: stage, seed: seed),
      heroStats: stats,
      stage: stage,
      abilityIds: faehigkeiten,
      ultimateId: ultimate,
      weaponMoveId: waffe,
      seed: seed,
    );
    PitBot.play(welt);
    if (welt.isWon) siege++;
  }
  return (siege * 100 / laeufe).round();
}

/// Dieselbe Rechnung mit **einer festen Rolle** der Besetzung (ADR-0062):
/// Die übrigen Rollen und der Wächter bleiben, wie der Startwert sie
/// würfelt. Eine Art, die deutlich unter ihren Nachbarn liegt, ist die,
/// wegen der man einen Lauf neu würfeln will.
void _jeBesetzung(Map<String, _Spalte> spalten, int laeufe) {
  final rollen = <String, List<(String, PitCast Function(PitCast))>>{
    'Nahkampf neben dem Fussvolk': <(String, PitCast Function(PitCast))>[
      for (final kind in PitCast.secondMelees)
        (
          kind?.name ?? 'niemand',
          (c) => PitCast(
            secondMelee: kind,
            ranged: c.ranged,
            swarm: c.swarm,
            special: c.special,
          ),
        ),
    ],
    'Wer schiesst': <(String, PitCast Function(PitCast))>[
      for (final kind in PitCast.rangeds)
        (
          kind.name,
          (c) => PitCast(
            secondMelee: c.secondMelee,
            ranged: kind,
            swarm: c.swarm,
            special: c.special,
          ),
        ),
    ],
    'Das Rudel': <(String, PitCast Function(PitCast))>[
      for (final kind in PitCast.swarms)
        (
          kind.name,
          (c) => PitCast(
            secondMelee: c.secondMelee,
            ranged: c.ranged,
            swarm: kind,
            special: c.special,
          ),
        ),
    ],
    'Der Sondergegner': <(String, PitCast Function(PitCast))>[
      for (final kind in <EnemyKind?>[null, ...PitCast.specials])
        (
          kind?.name ?? 'niemand',
          (c) => PitCast(
            secondMelee: c.secondMelee,
            ranged: c.ranged,
            swarm: c.swarm,
            special: kind,
          ),
        ),
    ],
  };
  // Je eine Spalte dort, wo sie etwas sagt: der frische Charakter oben,
  // der ausgerüstete unten.
  const felder = <(String, int)>[
    ('Tag 0', 1),
    ('Tag 0', 2),
    ('Tag 30+F', 11),
    ('T60+G+F', 30),
  ];

  print('Je Besetzung — eine Rolle fest, der Rest gewürfelt\n');
  print(
    '  ${''.padRight(30)}'
    '${felder.map((f) => '${f.$1} St.${f.$2}'.padLeft(16)).join()}',
  );
  for (final rolle in rollen.entries) {
    print('  ${rolle.key}');
    for (final (name, umbesetzen) in rolle.value) {
      final zeile = StringBuffer('    ${name.padRight(28)}');
      for (final (spalte, stufe) in felder) {
        final quote = _quote(
          stufe,
          spalten[spalte]!,
          laeufe,
          umbesetzen: umbesetzen,
        );
        zeile.write('$quote %'.padLeft(16));
      }
      print(zeile);
    }
  }
  print('');
}

/// Dieselbe Rechnung, aber mit **festem** Wächter (ADR-0062): Gewürfelt
/// wird er im Spiel, hier steht jeder einzeln da. Ein Wächter, der auf
/// einer Stufe deutlich unter den anderen liegt, ist dort der Lauf, den
/// man neu würfeln will — und das ist der Befund, den diese Tabelle
/// sichtbar machen soll.
///
/// Die Stufen sind die, an denen sich etwas ändert: 1 (nur der erste
/// Angriff), 4 (der zweite), 8 (der dritte, in Wut), dazu Mitte und Ende.
void _jeWaechter(Map<String, _Spalte> spalten, int laeufe) {
  const stufen = <int>[1, 4, 8, 15, 22, 30];
  const gezeigt = <String>['Tag 0', 'Tag 30+F', 'T60+G+F'];

  print('\nJe Wächter — derselbe Startwert, derselbe Bau, anderer Wächter\n');
  for (final name in gezeigt) {
    final spalte = spalten[name];
    if (spalte == null) continue;
    print('  $name');
    print(
      '  ${'Stufe'.padRight(7)}'
      '${BossKind.values.map((b) => b.name.padLeft(12)).join()}',
    );
    for (final stufe in stufen) {
      final zeile = StringBuffer('  ${stufe.toString().padRight(7)}');
      for (final boss in BossKind.values) {
        zeile.write(
          '${_quote(stufe, spalte, laeufe, boss: boss)} %'.padLeft(12),
        );
      }
      print(zeile);
    }
    print('');
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

int _quote(
  int stufe,
  _Spalte spalte,
  int laeufe, {
  BossKind? boss,
  PitCast Function(PitCast)? umbesetzen,
}) {
  var siege = 0;
  for (var seed = 0; seed < laeufe; seed++) {
    final stage = PitStage(stufe);
    final welt = ActionWorld(
      level: LevelBuilder.build(
        stage: stage,
        seed: seed,
        boss: boss,
        cast: umbesetzen?.call(PitCast.forSeed(seed)),
      ),
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

/// Was der Weg der Grundlagen an Erfahrung bringt, jede Seite fehlerfrei
/// (ADR-0070): neun Knoten, vom Start weg bezahlbar.
const int _grundlagenXp =
    TheoryPoints.atStart *
    (TheoryRewards.xpForPass + TheoryRewards.xpPerfectBonus);

/// Derselbe Aufbau wie in `tool/balance_sim.dart`: die ersten fünf
/// Vorlagen, jeden Tag abgehakt.
///
/// **Seit ADR-0042 mit Level und Seltenheit**, zusammengesetzt über
/// `PitPower.hero` wie in der App. Das Level zählt nur Gewohnheiten und
/// den Weg der Grundlagen — der übrige Baum, Reihe und Errungenschaften
/// brächten mehr. Die Quoten bleiben damit eine **untere** Schranke.
///
/// **An Tag 0 ist nichts gelesen** (ADR-0070). Bis dahin stand hier das
/// Handbuch mit 275 Erfahrung für jeden Tag, also Level 3 schon im
/// ersten Lauf. Seit ADR-0068 geht es aber nach dem ersten Häkchen
/// hinab, vor jeder Seite — „Tag 0" ist jetzt wirklich Level 1.
ActionStats _statsNach(
  int tage, {
  GearBonus bonus = const GearBonus(),
  bool mitSeltenheit = false,
}) {
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

  final gelesen = tage == 0 ? 0 : _grundlagenXp;
  final level = LevelCurve.levelFor(tracker.totalXp + gelesen).level;
  final waffe = _bestesIn(GearSlot.waffe).rarity.powerFactor;
  final ruestung = _bestesIn(GearSlot.ruestung).rarity.powerFactor;

  final s = tracker.stats;
  return PitPower.hero(
    attack: s.attack + bonus.attack,
    maxHp: s.maxHp + bonus.maxHp,
    defense: s.defense + bonus.defense,
    energy: s.maxEnergy + bonus.maxEnergy,
    levelFactor: PowerCurve.factorFor(level),
    weaponFactor: mitSeltenheit ? waffe : 1,
    armorFactor: mitSeltenheit ? ruestung : 1,
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

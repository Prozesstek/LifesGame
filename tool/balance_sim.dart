// Balance-Simulation über Package-Grenzen: Was passiert im Kampf mit einem
// Charakter, der seit N Tagen Gewohnheiten abhakt?
//
// Warum hier und nicht in packages/combat: Die Frage berührt zwei Packages,
// die einander bewusst nicht kennen. `packages/combat/example/balance_sim.dart`
// variiert deshalb nur den Angriffswert — und genau das war der Fehler im
// alten Befund. Das Spiel bewegt nie einen Wert allein, es bewegt vier
// gleichzeitig. Diese Datei liegt in der App, weil nur sie beide Packages
// sieht, und rechnet mit der echten Stat-Kurve statt mit abgeschriebenen
// Zahlen.
//
// Reines Dart trotz Flutter-Projekt: kein Import zieht Flutter herein.
//
//     dart run tool/balance_sim.dart
//     dart run tool/balance_sim.dart 3000

import 'dart:math';

import 'package:abilities/abilities.dart';
import 'package:combat/combat.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:lifes_game/gear/set_effects.dart';
import 'package:progression/progression.dart';

/// Spieler und Gegner nutzen dieselbe Policy — sie beschreibt nur
/// „wähle einen Move“ und ist nicht gegnerspezifisch.
const EnemyPolicy _policy = SimpleEnemyPolicy();

/// Wie viele Runden ein Kampf höchstens dauern darf, damit ein Patt die
/// Simulation nicht aufhängt. Ein Kampf, der diesen Deckel erreicht, gilt
/// als nicht gewonnen — genau daran wurde der Heal-Lock sichtbar.
const int _rundenDeckel = 200;

/// Die Punkte des Gewohnheits-Pfads, an denen gemessen wird.
const List<int> _tage = <int>[0, 7, 14, 21, 30, 60];

void main(List<String> args) {
  final fights = args.isEmpty ? 1500 : int.parse(args.first);
  print('$fights Kämpfe je Feld, gemischtes Timing\n');

  _siegquoten(fights);
  _rundenzahlen(fights);
  _timingSpanne(fights);
  _waffenvergleich(fights);
  _setvergleich(fights);
}

/// Ob ein volles Set im Kampf etwas ausmacht.
///
/// **Dieselbe Frage wie beim Waffenvergleich, und aus demselben Grund
/// gestellt:** „Das Set verstärkt Angriffs-Fähigkeiten" ist eine
/// Behauptung, solange niemand nachrechnet.
///
/// Gemessen wird ehrlich: Der Spieler trägt die vier Stücke des Sets (also
/// deren Werte **und** deren Waffe) und legt auf die freien Plätze
/// bevorzugt Fähigkeiten der passenden Art. Verglichen wird gegen genau
/// denselben Spieler ohne die Set-Wirkung — der Unterschied ist damit die
/// Wirkung allein, nicht die bessere Ausrüstung.
///
/// **Gemessen wird die Rundenzahl, nicht die Siegquote.** Wer vier
/// Set-Stücke trägt, hat rund 1880 Gold ausgegeben und gewinnt gegen alle
/// drei Gegner ohnehin — die Quote steht überall auf 100 % und sagt
/// nichts. Die Rundenzahl sättigt nicht: Sie zeigt, wie viel schneller
/// derselbe Kampf endet.
///
/// Dass die Quote sättigt, ist selbst ein Befund und steht in
/// `docs/context/state.md`: Gegen drei Gegner ist ein volles Set
/// Überfluss. Sein Platz ist der Dungeon (Ziel 6), wo HP zwischen den
/// Kämpfen nicht heilen und jede gesparte Runde zählt.
///
/// **Zwei der drei Sets kann diese Simulation nicht messen, und das liegt
/// an ihr, nicht an den Sets:**
///
/// - *Ruhiger Stand* macht die Leiste breiter und langsamer. Der
///   simulierte Spieler tippt aber nicht — sein Ergebnis kommt aus
///   [_roll], einer Münze mit `timingSkill` als Gewicht, und nie aus
///   [TimingSpec.judgeAt]. Eine breitere Leiste ändert für ihn nichts.
/// - *Eiserner Wille* verstärkt Angriffs-Fähigkeiten. Die drei, die dem
///   Spieler an Tag 30 zuerst zufallen, sind schwächer als sein Waffenzug
///   (Funkenstoß 0,75 gegen Hieb 1,3), und [SimpleEnemyPolicy] wählt sie
///   deshalb nicht. Verstärkt wird ein Zug, den niemand drückt — derselbe
///   Befund wie beim Waffenvergleich, aus einer dritten Richtung.
///
/// Beides wäre zu beheben, kostet aber die Vergleichbarkeit mit allen
/// Zahlen weiter oben. Solange Balancing zurückgestellt ist, steht die
/// Einschränkung lieber hier als ungenannt in einer Nullzeile.
void _setvergleich(int fights) {
  print('\n--- Was ein volles Set an Tag 30 ausmacht ---');
  print('(Runden im Schnitt; dieselben vier Stücke, ohne → mit Wirkung)\n');

  const tag = 30;
  final kopf = Enemies.all.map((e) => e.name.padLeft(20)).join();
  print('  ${'Set'.padRight(18)}$kopf');

  for (final set in GearSets.all) {
    final stuecke = GearCatalog.piecesOf(set.id);
    var bonus = const GearBonus();
    for (final stueck in stuecke) {
      bonus = bonus + stueck.bonus;
    }

    final waffe = stuecke.firstWhere((i) => i.slot == GearSlot.waffe);
    final loadout = _loadoutNach(
      tag,
      weaponMoveId: AbilityCatalog.weaponMoveFor(waffe.id),
      preferKind: moveKindFor(set.target),
    );
    final wirkung = setEffectsFor(<ActiveSet>[
      ActiveSet(set: set, pieces: GearSet.fullSize, perk: set.fourPiece),
    ]);

    final felder = Enemies.all.map((gegner) {
      double runden(List<SetEffect> sets) => _run(
        fights: fights,
        stats: _statsNach(tag),
        bonus: bonus,
        loadout: loadout,
        sets: sets,
        gegner: gegner,
        timingSkill: 0.5,
      ).averageRounds;

      final ohne = runden(const <SetEffect>[]).toStringAsFixed(1);
      final mit = runden(wirkung).toStringAsFixed(1);
      return '$ohne → $mit'.padLeft(20);
    }).join();

    print('  ${set.name.padRight(18)}$felder');
  }
}

/// Ob die Waffe im Laden wirklich etwas entscheidet (Ziel 3).
///
/// **Die Frage, die kein anderer Abschnitt beantwortet.** Bis zu den fünf
/// Waffen gaben beide Klingen denselben Zug; ein Waffenkauf war ein
/// Zahlenaufschlag. Seither trägt jede einen eigenen Rhythmus — und
/// „Rhythmus" ist eine Behauptung, solange niemand nachrechnet, ob die
/// Siegquoten auseinandergehen.
///
/// Gemessen wird mit Waffenbonus **und** Waffenzug, also so, wie ein
/// Spieler sie kauft. Liegen alle fünf Zeilen dicht beieinander, ist der
/// Waffenplatz weiter Dekoration, nur teurer.
void _waffenvergleich(int fights) {
  final waffen = GearCatalog.forSlot(GearSlot.waffe);

  for (final tag in <int>[21, 30]) {
    print('\n--- Siegquote je Waffe an Tag $tag ---');
    final kopf = Enemies.all.map((e) => e.name.padLeft(14)).join();
    print('  ${'Waffe'.padRight(22)}$kopf');

    for (final waffe in waffen) {
      final moveId = AbilityCatalog.weaponMoveFor(waffe.id);
      final felder = Enemies.all.map((gegner) {
        final ergebnis = _run(
          fights: fights,
          stats: _statsNach(tag),
          bonus: waffe.bonus,
          loadout: _loadoutNach(tag, weaponMoveId: moveId),
          gegner: gegner,
          timingSkill: 0.5,
        );
        return '${(ergebnis.winRate * 100).round()} %'.padLeft(14);
      }).join();
      print('  ${waffe.name.padRight(22)}$felder');
    }
  }
}

/// Siegquote je Gegner und Tag. Die Diagonale ist das Ziel: Zu jedem
/// Zeitpunkt soll genau ein Gegner knapp sein.
void _siegquoten(int fights) {
  print('--- Siegquote: Gegner gegen Tag auf dem Gewohnheits-Pfad ---');
  print('(fünf Gewohnheiten, jeden Tag abgehakt)\n');

  final kopf = _tage.map((t) => 'Tag $t'.padLeft(8)).join();
  print('  ${'Gegner'.padRight(14)}$kopf');

  for (final gegner in Enemies.all) {
    final felder = _tage.map((tag) {
      final ergebnis = _run(
        fights: fights,
        stats: _statsNach(tag),
        loadout: _loadoutNach(tag),
        gegner: gegner,
        timingSkill: 0.5,
      );
      return '${(ergebnis.winRate * 100).round()} %'.padLeft(8);
    }).join();
    print('  ${gegner.name.padRight(14)}$felder');
  }

  print('\n  Werte des Spielers an diesen Tagen:');
  for (final tag in _tage) {
    final stats = _statsNach(tag);
    print(
      '    Tag ${tag.toString().padLeft(2)}: '
      'ATK ${stats.attack}  HP ${stats.maxHp}  '
      'DEF ${stats.defense}  EN ${stats.maxEnergy}  '
      'Lv ${_levelNach(tag)}  '
      '${_loadoutNach(tag).length} Moves',
    );
  }
}

/// Kampflänge. Sehr hohe Werte bedeuten Kämpfe, die nicht enden.
void _rundenzahlen(int fights) {
  print('\n--- Runden im Schnitt ---');
  final kopf = _tage.map((t) => 'Tag $t'.padLeft(8)).join();
  print('  ${'Gegner'.padRight(14)}$kopf');

  for (final gegner in Enemies.all) {
    final felder = _tage.map((tag) {
      final ergebnis = _run(
        fights: fights,
        stats: _statsNach(tag),
        loadout: _loadoutNach(tag),
        gegner: gegner,
        timingSkill: 0.5,
      );
      return ergebnis.averageRounds.toStringAsFixed(1).padLeft(8);
    }).join();
    print('  ${gegner.name.padRight(14)}$felder');
  }
}

/// Was perfektes Timing gegenüber keinem Timing ausmacht.
///
/// Große Werte sind kein Fehler, solange sie nur dort stehen, wo der Kampf
/// ohnehin knapp ist: Dann entscheiden Gewohnheiten, *ob* ein Kampf knapp
/// wird, und Timing entscheidet den knappen Kampf. Stehen sie überall, ist
/// der Deckel zu hoch.
void _timingSpanne(int fights) {
  print('\n--- Spannweite perfektes gegen kein Timing, in Punkten ---');
  final kopf = _tage.map((t) => 'Tag $t'.padLeft(8)).join();
  print('  ${'Gegner'.padRight(14)}$kopf');

  for (final gegner in Enemies.all) {
    final felder = _tage.map((tag) {
      final stats = _statsNach(tag);
      final loadout = _loadoutNach(tag);
      final ohne = _run(
        fights: fights,
        stats: stats,
        gegner: gegner,
        timingSkill: 0.0,
        loadout: loadout,
      ).winRate;
      final perfekt = _run(
        fights: fights,
        stats: stats,
        gegner: gegner,
        timingSkill: 1.0,
        loadout: loadout,
      ).winRate;
      return ((perfekt - ohne) * 100).round().toString().padLeft(8);
    }).join();
    print('  ${gegner.name.padRight(14)}$felder');
  }
}

/// Die Charakterwerte nach [tage] Tagen, in denen alle fünf Gewohnheiten
/// abgehakt wurden.
///
/// Nutzt denselben Aufbau wie `packages/habits/example/curve_sim.dart`: die
/// ersten fünf Vorlagen des Katalogs. Damit sind beide Simulationen
/// vergleichbar.
HabitTracker _trackerNach(int tage) {
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

  return tracker;
}

CharacterStats _statsNach(int tage) => _trackerNach(tage).stats;

/// Das Level, das ein Charakter nach [tage] Tagen erreicht hat.
///
/// **Bewusst nur aus Gewohnheiten.** In der App speist auch die Theorie
/// die Erfahrung (`totalXpProvider`). Das Level faellt hier also eher zu
/// niedrig aus als zu hoch -- die Simulation ist an dieser Stelle
/// pessimistisch, nicht schoenrechnend.
int _levelNach(int tage) {
  return LevelCurve.levelFor(_trackerNach(tage).totalXp).level;
}

/// Die Moves, die an Tag [tage] tatsaechlich zur Verfuegung stehen.
///
/// **Seit ADR-0016/0017 haengt das Moveset am Level.** Auf Level 1 ist nur
/// der Waffenslot offen, die drei freien kommen auf 3, 6 und 10. Vier
/// Moves anzunehmen -- wie diese Simulation es bis dahin tat -- schrieb
/// dem Spieler an Tag 0 drei Knoepfe zu, die er nicht hat.
///
/// Gefuellt wird in Katalogreihenfolge: Der Spieler nimmt, was da ist.
/// Eine klug gewaehlte Zusammenstellung waere eine Annahme ueber sein
/// Verhalten; diese hier ist die anspruchsloseste.
///
/// **Ohne [weaponMoveId] kaempft der Spieler mit dem Rueckfall** aus
/// `AbilityCatalog`, also dem Kurzbogen -- so, wie jemand ohne gekaufte
/// Waffe dasteht. Die uebrigen Abschnitte messen absichtlich diesen Fall;
/// was eine gekaufte Waffe aendert, misst `_waffenvergleich`.
/// **[preferKind] steuert, was auf die freien Plaetze kommt.** Ohne
/// Angabe nimmt der Spieler, was zuerst im Katalog steht -- die
/// anspruchsloseste Annahme. Wer ein Set traegt, waehlt dagegen passend;
/// ein Umgebungs-Set neben drei Angriffs-Faehigkeiten zu messen waere ein
/// Strohmann.
List<Move> _loadoutNach(
  int tage, {
  String? weaponMoveId,
  MoveKind? preferKind,
}) {
  final offen = AbilitySlots.openAt(_levelNach(tage));
  final moves = <Move>[
    Moves.byId(weaponMoveId ?? AbilityCatalog.fallbackMoveId) ??
        Moves.basicAttack,
  ];

  final offene = AbilityCatalog.unlockedBy(
    _fortschrittNach(tage),
  ).map((a) => Moves.byId(a.moveId)).nonNulls.toList();
  if (preferKind != null) {
    offene.sort((a, b) {
      final aPasst = a.kind == preferKind ? 0 : 1;
      final bPasst = b.kind == preferKind ? 0 : 1;
      return aPasst.compareTo(bPasst);
    });
  }

  for (final move in offene) {
    if (moves.length >= offen) break;
    moves.add(move);
  }

  return moves;
}

/// Was ein Spieler nach [tage] Tagen freigeschaltet haette.
///
/// **Hier stecken zwei Annahmen, und sie stehen bewusst offen da.**
///
/// 1. *Die Kette reisst nie.* Die Simulation spielt einen Spieler, der
///    jeden Tag abhakt -- so entstehen auch die Charakterwerte weiter
///    oben. Streak-Faehigkeiten fallen ihm damit frueher zu als einem
///    Spieler mit Luecken.
/// 2. *Jeder Theoriepunkt landet in einem Knoten mit Faehigkeit.* Zwei
///    Punkte je Aufstieg (ADR-0019), und alle gehen in Kampfnutzen. Wer
///    stattdessen liest, was ihn interessiert, steht schlechter da.
///
/// Beides macht das Ergebnis zur **oberen** Schranke: So gut wird es
/// hoechstens. Das ist die richtige Richtung fuer eine Balance-Frage --
/// wenn schon der bestmoegliche Pfad an einem Gegner scheitert, scheitert
/// jeder.
///
/// Vorher stand hier `AbilityProgress.empty()`. Seit ADR-0019 haengt aber
/// jede waehlbare Faehigkeit an einem Knoten, und ein leerer Fortschritt
/// schaltet nichts frei -- die Simulation spielte damit an jedem Tag mit
/// einem einzigen Move und meldete entsprechend 0 %.
AbilityProgress _fortschrittNach(int tage) {
  final punkte = TheoryPoints.earnedAt(_levelNach(tage));

  final knoten = <String>{};
  for (final ability in AbilityCatalog.choosable) {
    if (knoten.length >= punkte) break;
    if (ability.source case FromTheory(:final nodeId)) knoten.add(nodeId);
  }

  return AbilityProgress(longestStreak: tage, passedNodeIds: knoten);
}

class _Ergebnis {
  const _Ergebnis(this.wins, this.fights, this.totalRounds);

  final int wins;
  final int fights;
  final int totalRounds;

  double get winRate => wins / fights;
  double get averageRounds => totalRounds / fights;
}

_Ergebnis _run({
  required int fights,
  required CharacterStats stats,
  required EnemyBlueprint gegner,
  required double timingSkill,
  required List<Move> loadout,

  /// Was eine angelegte Waffe obendrauf gibt. Leer heisst: keine Waffe.
  GearBonus bonus = const GearBonus(),

  /// Was vollstaendige Sets beitragen. Leer heisst: keins voll.
  List<SetEffect> sets = const <SetEffect>[],
}) {
  // Zwei getrennte Generatoren, und das ist keine Kosmetik: Mit einem
  // einzigen verschiebt die Timing-Spalte alle folgenden Kampf-Seeds, weil
  // längere Kämpfe mehr Würfe verbrauchen. Die Spalten vergleichen dann
  // verschiedene Kämpfe, und das Ergebnis kann sich umkehren — bei
  // gemischtem Timing 37 % Siegquote gegen 80 % ohne Timing, was
  // mechanisch unmöglich ist. So bekommt jede Spalte dieselben Kämpfe.
  final seeds = Random(20260817);
  final timing = Random(4711);
  var wins = 0;
  var rounds = 0;

  for (var i = 0; i < fights; i++) {
    final engine = CombatEngine(
      seed: seeds.nextInt(1 << 30),
      enemyLoadout: gegner.loadout,
      enemyUtilityChance: gegner.utilityChance,
      playerSets: sets,
    );
    var state = CombatState.start(
      player: Combatant.fresh(
        name: 'Du',
        maxHp: stats.maxHp + bonus.maxHp,
        attack: stats.attack + bonus.attack,
        defense: stats.defense + bonus.defense,
        maxEnergy: stats.maxEnergy + bonus.maxEnergy,
      ),
      enemy: gegner.spawn(),
    );

    for (var round = 0; round < _rundenDeckel && !state.isOver; round++) {
      final move = _policy.chooseMove(
        self: state.player,
        opponent: state.enemy,
        loadout: loadout,
      );
      state = engine
          .resolveRound(
            state,
            PlayerAction(move: move, timedHit: _roll(timing, timingSkill)),
          )
          .state;
      rounds++;
    }

    if (state.outcome == CombatOutcome.victory) wins++;
  }

  return _Ergebnis(wins, fights, rounds);
}

/// Übersetzt eine Fertigkeit von 0..1 in ein Timing-Ergebnis.
TimedHit _roll(Random random, double skill) {
  final value = random.nextDouble();
  if (value < skill * 0.6) return TimedHit.perfect;
  if (value < skill * 0.6 + 0.3) return TimedHit.good;
  return TimedHit.none;
}

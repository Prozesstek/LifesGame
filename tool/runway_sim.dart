// Wann geht einem fleissigen Spieler was aus?
//
//     dart run tool/runway_sim.dart
//
// Spielt 60 Tage durch: jeden Tag alle fünf Gewohnheiten und die Truhe,
// bis zu zwei Seiten, sobald Punkte da sind, eine Rückfrage, eine neue
// Stufe der Grube, soweit die Reichweite reicht, und vier Dailies. Seit
// ADR-0048 auch die Beute: Jeder Sieg über den Wächter setzt einen
// Schlüssel ein, der erste auf einer Stufe keinen.
//
// **Zwei Annahmen, die man kennen muss:** Die Reichweite in der Grube ist
// aus `pit_sim` abgelesen (siehe [reichweite]), also eine untere Schranke,
// denn der Bot ist dumm. Und Errungenschaften zählen nicht mit (über ein
// Spielerleben 1680 Erfahrung und 560 Gold).
import 'package:action_combat/action_combat.dart';
import 'package:gear/gear.dart';
import 'package:habits/habits.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

/// Reichweite in der Grube je Tag, aus pit_sim (Bot = untere Schranke):
/// Tag 0 -> 2, Tag 14 -> 6, Tag 30 -> 12 (mit Fähigkeiten), Tag 60 voll
/// ausgerüstet -> 30.
int reichweite(int tag) {
  const punkte = <(int, int)>[(0, 2), (14, 6), (30, 12), (60, 30)];
  for (var i = 1; i < punkte.length; i++) {
    final (t0, s0) = punkte[i - 1];
    final (t1, s1) = punkte[i];
    if (tag <= t1) return (s0 + (s1 - s0) * (tag - t0) / (t1 - t0)).floor();
  }
  return 30;
}

void main() {
  final chosen = HabitCatalog.all
      .take(HabitRewards.maxActiveHabits)
      .map((t) => t.id)
      .toList();
  var tracker = const HabitTracker.empty();
  for (final id in chosen) {
    tracker = tracker.activate(id);
  }

  const seiteXp = TheoryRewards.xpForPass + TheoryRewards.xpPerfectBonus;
  const seiteGold = TheoryRewards.goldForPass;
  final knoten = theoryGraph.nodes;
  final kostenpflichtig = knoten.where((n) => n.cost > 0).length;
  final freie = knoten.length - kostenpflichtig;

  var day = const Day(2026, 9, 21);
  var truhenGold = 0;
  var seiten = 5; // das Handbuch am ersten Tag
  var geoeffnet = 0; // bezahlte Knoten
  var graphSeiten = 0;
  var stufe = 0;
  var reiheXp = 0, reiheGold = 0, dailyXp = 0, dailyGold = 0;
  var rueckXp = 0, rueckGold = 0;
  final ereignisse = <String>[];
  var baumVoll = false, ladenLeer = false, deckel = false;

  final alle = GearCatalog.all;

  // Beute (ADR-0048): Schlüssel aus Häkchen, Seiten und Rückfragen,
  // eingesetzt bei jedem Sieg über den Wächter — der neuen Stufe und den
  // vier Dailies. Der erste Sieg auf einer Stufe bringt ohne Schlüssel.
  var schluesselVerdient = 0;
  var schluesselVerbraucht = 0;
  var beuteNr = 0;
  final beuteJeSeltenheit = <GearRarity, int>{};
  final erstesMal = <String, int>{};
  void merke(String was, int tag) => erstesMal.putIfAbsent(was, () => tag);
  final gesamtPreis = alle.fold<int>(0, (s, i) => s + i.price);

  print('Tag  Lvl  TP  Knoten  Seiten  Stufe  Gold ges.  Laden offen');
  for (var tag = 1; tag <= 60; tag++) {
    for (final id in chosen) {
      tracker = tracker.check(id, day).tracker;
    }
    truhenGold += DailyChest.forDay(day).gold;

    // Stand vor dem Lesen, um Punkte zu kennen.
    int xpGesamt() =>
        tracker.totalXp + seiten * seiteXp + reiheXp + dailyXp + rueckXp;
    var level = LevelCurve.levelFor(xpGesamt()).level;

    // Lesen: bis zu zwei Seiten am Tag, freie Wurzeln zuerst.
    for (var i = 0; i < 2; i++) {
      final punkte = TheoryPoints.earnedAt(level) - geoeffnet;
      if (graphSeiten < freie) {
        graphSeiten++;
        seiten++;
      } else if (geoeffnet < kostenpflichtig && punkte > 0) {
        geoeffnet++;
        graphSeiten++;
        seiten++;
      }
      level = LevelCurve.levelFor(xpGesamt()).level;
    }

    // Rückfrage des Tages.
    if (tag > 1) {
      rueckXp += TheoryRewards.xpForReview;
      rueckGold += TheoryRewards.goldForReview;
    }

    // Grube: höchstens eine neue Stufe am Tag, bis zur Reichweite.
    schluesselVerdient = tracker.totalChecks + seiten + (tag - 1);
    final dayIndex = 20355 + tag;
    void beute(int s, {required bool frei}) {
      if (!frei) {
        final da = GearKeys.available(
          earned: schluesselVerdient,
          consumed: schluesselVerbraucht,
        );
        if (da <= 0) return;
        schluesselVerbraucht = GearKeys.consume(
          earned: schluesselVerdient,
          consumed: schluesselVerbraucht,
        );
      }
      final r = GearLoot.drop(
        stage: s,
        dayIndex: dayIndex,
        nth: ++beuteNr,
      ).item!.rarity;
      beuteJeSeltenheit[r] = (beuteJeSeltenheit[r] ?? 0) + 1;
      merke('Beute ${r.label}', tag);
    }

    if (stufe < reichweite(tag)) {
      stufe++;
      reiheXp += LadderRewards.xpFor(stufe);
      reiheGold += LadderRewards.goldFor(stufe);
      beute(stufe, frei: true);
    }
    for (final a in DailyShop.offersFor(dayIndex, highestRung: stufe)) {
      merke('Laden ${a.item!.rarity.label}', tag);
    }
    // Vier Dailies aus dem Geschafften, jede mit einem Schlüssel.
    if (stufe > 0) {
      for (final r in <int>[
        1,
        (stufe / 2).ceil(),
        (stufe * 0.75).ceil(),
        stufe,
      ]) {
        dailyXp += LadderRewards.dailyXpFor(r);
        dailyGold += LadderRewards.dailyGoldFor(r);
        beute(r, frei: false);
      }
    }

    level = LevelCurve.levelFor(xpGesamt()).level;
    final gold =
        tracker.totalGold +
        truhenGold +
        seiten * seiteGold +
        reiheGold +
        dailyGold +
        rueckGold;
    final offen = alle
        .where((i) => stufe >= GearGates.rungFor(i.rarity))
        .fold<int>(0, (s, i) => s + i.price);

    if (!deckel && tracker.stats.attack >= 20 && tracker.stats.maxHp >= 224) {
      deckel = true;
      ereignisse.add('Tag $tag: Charakterwerte am Deckel');
    }
    if (!baumVoll && geoeffnet == kostenpflichtig) {
      baumVoll = true;
      ereignisse.add('Tag $tag: ganzer Baum gelesen (Level $level)');
    }
    if (!ladenLeer && gold >= gesamtPreis) {
      ladenLeer = true;
      ereignisse.add('Tag $tag: der ganze Laden bezahlbar ($gesamtPreis)');
    }
    if (tag == 1 || tag % 5 == 0) {
      print(
        '${tag.toString().padLeft(3)}  ${level.toString().padLeft(3)}  '
        '${TheoryPoints.earnedAt(level).toString().padLeft(2)}  '
        '${(geoeffnet + freie).toString().padLeft(3)}/${knoten.length}  '
        '${seiten.toString().padLeft(5)}   ${stufe.toString().padLeft(4)}  '
        '${gold.toString().padLeft(8)}   $offen von $gesamtPreis',
      );
    }
    day = day.next;
  }
  print('');
  ereignisse.forEach(print);
  print('');
  print(
    'Beute über 60 Tage: $beuteNr Stück — '
    '${GearRarity.values.map((r) => '${beuteJeSeltenheit[r] ?? 0} ${r.label}').join(', ')}',
  );
  for (final r in <GearRarity>[
    GearRarity.rare,
    GearRarity.epic,
    GearRarity.legendary,
  ]) {
    print(
      'Erstes ${r.label}: Beute Tag ${erstesMal['Beute ${r.label}'] ?? '–'}, '
      'im Laden Tag ${erstesMal['Laden ${r.label}'] ?? '–'}',
    );
  }
  for (final (stufe, name) in <(int, String)>[
    (GearGates.epicRung, 'Episch'),
    (GearGates.legendaryRung, 'Legendär'),
  ]) {
    var t = 1;
    while (reichweite(t) < stufe) {
      t++;
    }
    print('Stufe $stufe ($name) erreicht am Tag $t');
  }
}

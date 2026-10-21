import 'catalog.dart';
import 'copy.dart';
import 'gates.dart';
import 'item.dart';

/// Wie gewürfelt wird: Werte, Seltenheit, der Tagesladen und die Beute
/// des Wächters (ADR-0048). **Alle Stellschrauben dazu stehen hier.**
abstract final class GearRolls {
  /// Die Spanne eines Werts, als Anteil des Katalogwerts. **Immer
  /// dieselbe**, egal wie tief — die perfekte Zahl ist Glück, nicht
  /// Fleiss.
  static const double rollMin = 0.85;
  static const double rollMax = 1.15;

  /// Wie selten die Beute ist, je nach Stufe. Dieselbe Tabelle gilt im
  /// Laden, dort nach der tiefsten geschafften Stufe.
  ///
  /// **Die Sperren aus ADR-0034 stecken darin:** Episch gibt es erst ab
  /// [GearGates.epicRung], Legendär ab [GearGates.legendaryRung].
  /// `rolls_test.dart` hält beides fest.
  ///
  /// Die Zahlen sind ein Anfang, nicht gemessen.
  static Map<GearRarity, int> weightsFor(int stage) {
    if (stage >= GearGates.legendaryRung) {
      return const <GearRarity, int>{
        GearRarity.common: 20,
        GearRarity.uncommon: 35,
        GearRarity.rare: 25,
        GearRarity.epic: 15,
        GearRarity.legendary: 5,
      };
    }
    if (stage >= GearGates.epicRung) {
      return const <GearRarity, int>{
        GearRarity.common: 40,
        GearRarity.uncommon: 35,
        GearRarity.rare: 18,
        GearRarity.epic: 7,
      };
    }
    return const <GearRarity, int>{
      GearRarity.common: 70,
      GearRarity.uncommon: 25,
      GearRarity.rare: 5,
    };
  }

  /// Würfelt die Werte eines Exemplars: jeden einzeln, zwischen
  /// [rollMin] und [rollMax] des Katalogwerts im Kampfmassstab.
  static GearBonus rollBonus(GearItem item, GearDice dice) {
    final katalog = item.bonus.scaled;
    int wurf(int wert) {
      if (wert == 0) return 0;
      final anteil = rollMin + (rollMax - rollMin) * dice.next();
      final ergebnis = (wert * anteil).round();
      // Ein positiver Wert bleibt positiv, auch bei kleinem Katalogwert.
      return wert > 0 && ergebnis < 1 ? 1 : ergebnis;
    }

    return GearBonus(
      attack: wurf(katalog.attack),
      maxHp: wurf(katalog.maxHp),
      defense: wurf(katalog.defense),
      maxEnergy: wurf(katalog.maxEnergy),
    );
  }

  /// Welche Seltenheit fällt — gewichtet nach [weightsFor].
  static GearRarity rollRarity(int stage, GearDice dice) {
    final gewichte = weightsFor(stage);
    final gesamt = gewichte.values.fold<int>(0, (s, g) => s + g);
    var rest = dice.next() * gesamt;
    for (final eintrag in gewichte.entries) {
      if (rest < eintrag.value) return eintrag.key;
      rest -= eintrag.value;
    }
    return gewichte.keys.first;
  }

  /// Ein Katalogstück dieser Seltenheit auf diesem Platz.
  ///
  /// Gibt es auf dem Platz keines dieser Seltenheit, geht es eine Stufe
  /// nach unten — der Katalog hat heute auf jedem Platz jede Seltenheit,
  /// aber ein Würfel soll nicht an einer Lücke scheitern.
  static GearItem pick(GearSlot slot, GearRarity rarity, GearDice dice) {
    for (var r = rarity.index; r >= 0; r--) {
      final kandidaten =
          GearCatalog.forSlotAndRarity(slot, GearRarity.values[r]);
      if (kandidaten.isEmpty) continue;
      final index = (dice.next() * kandidaten.length).floor();
      return kandidaten[index.clamp(0, kandidaten.length - 1)];
    }
    return GearCatalog.forSlot(slot).first;
  }

  /// Wie oft jeder Platz fällt — die zweite Stufe der Kaskade
  /// (ADR-0083). Heute alle gleich; wer einen Platz seltener machen
  /// will, dreht hier.
  static const Map<GearSlot, int> slotWeights = <GearSlot, int>{
    GearSlot.waffe: 1,
    GearSlot.ruestung: 1,
    GearSlot.helm: 1,
    GearSlot.schuhe: 1,
    GearSlot.ring: 1,
    GearSlot.talisman: 1,
  };

  /// Welcher Platz fällt — gewichtet nach [slotWeights].
  static GearSlot rollSlot(GearDice dice) {
    final gesamt = slotWeights.values.fold<int>(0, (s, g) => s + g);
    var rest = dice.next() * gesamt;
    for (final eintrag in slotWeights.entries) {
      if (rest < eintrag.value) return eintrag.key;
      rest -= eintrag.value;
    }
    return slotWeights.keys.first;
  }

  /// [rarity] eine Stufe seltener — aber nur, wenn es die auf [stage]
  /// überhaupt gibt (ADR-0034): Der Wächter von Ebene 5 wirft kein
  /// Episches.
  static GearRarity oneUp(GearRarity rarity, int stage) {
    final hoeher = rarity.index + 1;
    if (hoeher >= GearRarity.values.length) return rarity;
    final naechste = GearRarity.values[hoeher];
    return weightsFor(stage).containsKey(naechste) ? naechste : rarity;
  }
}

/// Die sechs Angebote des Tages — eins je Platz, aus dem Datum gewürfelt.
///
/// **Nichts davon wird gespeichert.** Wer heute ein Angebot kauft, hat
/// ein Exemplar mit der Uid `laden-<tag>-<platz>`; morgen gibt es neue.
/// Die Seltenheit richtet sich nach der tiefsten geschafften Stufe, also
/// sehen zwei Spieler denselben Laden nur, solange sie gleich weit sind.
abstract final class DailyShop {
  /// [dayIndex] zählt die Tage seit dem 1.1.1970 — so rechnet auch die
  /// Tagestruhe. [highestRung] ist die tiefste geschaffte Stufe.
  static List<GearCopy> offersFor(int dayIndex, {required int highestRung}) {
    return List<GearCopy>.unmodifiable(<GearCopy>[
      for (final slot in GearSlot.values) _offer(dayIndex, slot, highestRung),
    ]);
  }

  static GearCopy _offer(int dayIndex, GearSlot slot, int highestRung) {
    final dice = GearDice(dayIndex * 31 + slot.index * 7919 + 17);
    final rarity = GearRolls.rollRarity(highestRung, dice);
    final item = GearRolls.pick(slot, rarity, dice);
    return GearCopy(
      uid: 'laden-$dayIndex-${slot.name}',
      itemId: item.id,
      bonus: GearRolls.rollBonus(item, dice),
      paid: item.price,
    );
  }
}

/// Was der Wächter fallen lässt (ADR-0048).
abstract final class GearLoot {
  /// Ein Exemplar als Beute der Stufe [stage].
  ///
  /// [dayIndex] und [nth] (die wievielte Beute insgesamt) machen den Wurf
  /// eindeutig und wiederholbar. Der Platz ist so zufällig wie die
  /// Seltenheit — ein Set-Teil will erjagt sein.
  static GearCopy drop({
    required int stage,
    required int dayIndex,
    required int nth,
  }) {
    final dice = GearDice(dayIndex * 131 + stage * 7727 + nth * 104729 + 3);
    final slot = GearSlot
        .values[(dice.next() * GearSlot.values.length).floor().clamp(0, 5)];
    final rarity = GearRolls.rollRarity(stage, dice);
    final item = GearRolls.pick(slot, rarity, dice);
    return GearCopy(
      uid: 'beute-$stage-$dayIndex-$nth',
      itemId: item.id,
      bonus: GearRolls.rollBonus(item, dice),
      paid: 0,
    );
  }

  /// **Die Kaskade** (ADR-0083): was ein Gegner in der Grube fallen
  /// lässt, gewürfelt in Stufen, jede mit eigener Tabelle.
  ///
  /// 1. **Ob** etwas fällt — das entscheidet die Grube
  ///    (`ActionBalance.itemDropChance`), denn dort steht, wer zäh ist.
  /// 2. **Welcher Platz** — [GearRolls.slotWeights].
  /// 3. **Welche Seltenheit** — [GearRolls.weightsFor] nach der Ebene;
  ///    beim Wächter ([boss]) eine Stufe höher, soweit die Ebene sie
  ///    erlaubt ([GearRolls.oneUp]).
  /// 4. **Welches Stück** mit welchen Werten — [GearRolls.pick] und
  ///    [GearRolls.rollBonus].
  ///
  /// [run] ist der Startwert des Laufs, [nth] der wievielte Fund darin;
  /// beide zusammen machen den Wurf wiederholbar und die Uid eindeutig,
  /// auch wenn dieselbe Ebene am selben Tag zweimal gespielt wird.
  static GearCopy cascade({
    required int stage,
    required int run,
    required int nth,
    bool boss = false,
  }) {
    final dice = GearDice(run * 31 + stage * 7727 + nth * 104729 + 11);
    final slot = GearRolls.rollSlot(dice);
    var rarity = GearRolls.rollRarity(stage, dice);
    if (boss) rarity = GearRolls.oneUp(rarity, stage);
    final item = GearRolls.pick(slot, rarity, dice);
    return GearCopy(
      uid: 'beute-$stage-r$run-$nth',
      itemId: item.id,
      bonus: GearRolls.rollBonus(item, dice),
      paid: 0,
    );
  }
}

/// Ein kleiner, vorhersagbarer Würfel (Park–Miller) — derselbe wie für
/// die Tagestruhe in `package:habits` und die Stufen des Tages in
/// `package:action_combat`, die dieses Package nicht kennen darf.
///
/// **Nicht `dart:math`:** Dessen Folge zu einem Startwert ist zwischen
/// Plattformen nicht zugesagt. Diese Rechnung bleibt unter 2⁵³ und ergibt
/// im Browser und im Test dasselbe Angebot.
///
/// **Der Startwert wird erst gemischt** ([_mische]). Ohne das ist der
/// Würfel linear: Startwerte im gleichen Abstand — Fund 1, 2, 3 eines
/// Laufs, die sechs Plätze eines Tages — ergeben erste Würfe im gleichen
/// Abstand. Die Funde eines Laufs fielen dadurch gemeinsam: auf Ebene 22
/// in jedem zwölften Lauf drei Legendäre, fast nie eins oder zwei
/// (AktivesBrett, 21.10.; `rolls_test.dart`, „Funde hängen nicht
/// zusammen“).
class GearDice {
  GearDice(int seed) : _zustand = (_mische(seed) * 6007 + 7727) % _m {
    if (_zustand == 0) _zustand = 1;
    for (var i = 0; i < 3; i++) {
      next();
    }
  }

  /// Xorshift über 32 Bit — mit Masken, damit Browser (32 Bit) und VM
  /// (64 Bit) dasselbe rechnen. Höhere Bits des Startwerts werden vorher
  /// hineingefaltet; `%` und `~/` sind unter 2⁵³ auf beiden genau.
  static int _mische(int seed) {
    const voll = 0xFFFFFFFF;
    final betrag = seed.abs();
    var x = (betrag % 0x100000000) ^ (betrag ~/ 0x100000000);
    for (var i = 0; i < 3; i++) {
      x = (x ^ (x << 13)) & voll;
      x = (x ^ (x >> 17)) & voll;
      x = (x ^ (x << 5)) & voll;
    }
    return x;
  }

  static const int _m = 2147483647;
  static const int _a = 48271;
  int _zustand;

  /// Eine Zahl in [0, 1).
  double next() {
    _zustand = (_zustand * _a) % _m;
    return (_zustand - 1) / (_m - 1);
  }
}

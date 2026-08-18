import 'item.dart';
import 'prices.dart';

/// Alles, was der Shop führt.
///
/// Zwei Stufen. Die erste belegt alle sechs Plätze und ist nach etwa einer
/// Woche tragbar; die zweite ersetzt drei davon und braucht etwa einen
/// Monat. Dass die Preise zum Gold-Zufluss passen, prüft
/// `test/prices_test.dart` — nicht das Gefühl.
///
/// **Warum die Energie-Stücke die interessanten sind.** Das Konzept
/// (Abschnitt 3.1) warnt ausdrücklich davor, dass Ausrüstung nur Zahlen
/// erhöht: „Ein Ring, der Energie schneller füllt, erzeugt eine
/// Entscheidung. +3 Angriff nicht." Energie ist im Kampf die einzige
/// taktische Ressource — ein Punkt mehr heißt, dass der Wuchtschlag eine
/// Runde früher bezahlbar ist. Deshalb sitzt Energie auf Ring und
/// Talisman, den beiden Plätzen ohne Rüstungsfunktion.
abstract final class GearCatalog {
  static const List<GearItem> all = <GearItem>[
    // --- Stufe 1: Grundversorgung ---
    GearItem(
      id: 'gear-uebungsklinge',
      name: 'Übungsklinge',
      slot: GearSlot.waffe,
      price: GearPrices.stufe1Waffe,
      bonus: GearBonus(attack: 1),
      why: 'Ein Angriffspunkt klingt nach wenig und ist es nicht: Der '
          'Unterschied zwischen knapp verlieren und knapp gewinnen liegt '
          'im Kampf genau in dieser Größenordnung.',
    ),
    GearItem(
      id: 'gear-lederwams',
      name: 'Lederwams',
      slot: GearSlot.ruestung,
      price: GearPrices.stufe1Ruestung,
      bonus: GearBonus(maxHp: 16, defense: 1),
      why: 'Lebenspunkte verlängern den Kampf, und ein längerer Kampf gibt '
          'der Energieleiste Zeit, überhaupt eine Rolle zu spielen.',
    ),
    GearItem(
      id: 'gear-lederkappe',
      name: 'Lederkappe',
      slot: GearSlot.helm,
      price: GearPrices.stufe1Helm,
      bonus: GearBonus(maxHp: 8),
      why: 'Der billigste Platz, und der erste, den man belegen sollte: '
          'Lebenspunkte wirken gegen jeden Gegner gleich gut.',
    ),
    GearItem(
      id: 'gear-feste-stiefel',
      name: 'Feste Stiefel',
      slot: GearSlot.schuhe,
      price: GearPrices.stufe1Schuhe,
      bonus: GearBonus(defense: 1),
      why: 'Verteidigung senkt jeden eingehenden Treffer prozentual. Gegen '
          'starke Gegner ist sie deshalb mehr wert als gegen schwache.',
    ),
    GearItem(
      id: 'gear-schlichter-ring',
      name: 'Schlichter Ring',
      slot: GearSlot.ring,
      price: GearPrices.stufe1Ring,
      bonus: GearBonus(maxEnergy: 1),
      why: 'Ein Punkt Energie mehr heißt: Der Wuchtschlag ist eine Runde '
          'früher bezahlbar. Das teuerste Stück der ersten Stufe, weil es '
          'nicht eine Zahl erhöht, sondern eine Entscheidung ändert.',
    ),
    GearItem(
      id: 'gear-glasperle',
      name: 'Glasperle',
      slot: GearSlot.talisman,
      price: GearPrices.stufe1Talisman,
      bonus: GearBonus(attack: 1, maxHp: 4),
      why: 'Der Platz für kleine Vielseitigkeit. Wer nicht weiß, was fehlt, '
          'nimmt hier etwas von beidem.',
    ),

    // --- Stufe 2: ersetzt Stufe 1 ---
    GearItem(
      id: 'gear-geschliffene-klinge',
      name: 'Geschliffene Klinge',
      slot: GearSlot.waffe,
      price: GearPrices.stufe2Waffe,
      bonus: GearBonus(attack: 3),
      why: 'Drei Angriffspunkte sind etwa zehn Tage Gewohnheiten. Deshalb '
          'kostet die Klinge auch etwa so viel wie zehn Tage Gold.',
    ),
    GearItem(
      id: 'gear-schuppenpanzer',
      name: 'Schuppenpanzer',
      slot: GearSlot.ruestung,
      price: GearPrices.stufe2Ruestung,
      bonus: GearBonus(maxHp: 32, defense: 3),
      why: 'Das Stück, mit dem der Bergwaechter kippt: Er schlägt hart, und '
          'genau dagegen wirkt Verteidigung am stärksten.',
    ),
    GearItem(
      id: 'gear-taktring',
      name: 'Taktring',
      slot: GearSlot.ring,
      price: GearPrices.stufe2Ring,
      bonus: GearBonus(maxEnergy: 2),
      why: 'Zwei Punkte Energie machen aus „Wuchtschlag, wenn es reicht" '
          'ein „Wuchtschlag, wann ich will". Das teuerste Stück im Laden, '
          'und das einzige, das die Reihenfolge der Züge verändert.',
    ),
  ];

  static GearItem? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Alles, was auf einen Platz passt, günstigstes zuerst.
  static List<GearItem> forSlot(GearSlot slot) {
    final items = all.where((item) => item.slot == slot).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return List<GearItem>.unmodifiable(items);
  }

  /// Was ein kompletter Satz der günstigsten Stufe kostet — der Maßstab
  /// für „nach etwa einer Woche tragbar".
  static int get cheapestFullSetPrice {
    var sum = 0;
    for (final slot in GearSlot.values) {
      final items = forSlot(slot);
      if (items.isNotEmpty) sum += items.first.price;
    }
    return sum;
  }
}

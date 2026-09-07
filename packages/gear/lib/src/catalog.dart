import 'item.dart';
import 'prices.dart';

/// Alles, was der Shop führt.
///
/// **Fünf Stücke je Platz, drei Seltenheiten** (ADR-0029): zwei
/// gewöhnliche, zwei ungewöhnliche, ein seltenes. Der Laden soll dreißig
/// Tage lang etwas zu entscheiden geben; mit neun Stücken war nach zwei
/// Wochen alles gesehen.
///
/// **Die Waffe ist noch nicht gefüllt.** Jede Waffe im Laden muss eine
/// Fähigkeit mitbringen — `test/abilities_seam_test.dart` in der App
/// besteht darauf, und zu Recht: Der Waffenslot ist auf Level 1 der
/// einzige offene (ADR-0016). Die fehlenden Waffen kommen deshalb
/// zusammen mit ihren Fähigkeiten (Ziel 3).
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
    // ---------------------------------------------------------------
    // Waffe — die übrigen zwei kommen mit ihren Fähigkeiten (Ziel 3)
    // ---------------------------------------------------------------
    GearItem(
      id: 'gear-uebungsklinge',
      name: 'Übungsklinge',
      slot: GearSlot.waffe,
      rarity: GearRarity.common,
      price: GearPrices.waffeCommon1,
      bonus: GearBonus(attack: 1),
      why: 'Ein Angriffspunkt klingt nach wenig und ist es nicht: Der '
          'Unterschied zwischen knapp verlieren und knapp gewinnen liegt '
          'im Kampf genau in dieser Größenordnung.',
    ),
    GearItem(
      id: 'gear-geschliffene-klinge',
      name: 'Geschliffene Klinge',
      slot: GearSlot.waffe,
      rarity: GearRarity.uncommon,
      price: GearPrices.waffeUncommon1,
      bonus: GearBonus(attack: 3),
      why: 'Drei Angriffspunkte sind etwa zehn Tage Gewohnheiten. Deshalb '
          'kostet die Klinge auch etwa so viel wie zehn Tage Gold.',
    ),

    // ---------------------------------------------------------------
    // Rüstung — Leben und Verteidigung, der Platz zum Aushalten
    // ---------------------------------------------------------------
    GearItem(
      id: 'gear-lederwams',
      name: 'Lederwams',
      slot: GearSlot.ruestung,
      rarity: GearRarity.common,
      price: GearPrices.ruestungCommon1,
      bonus: GearBonus(maxHp: 16, defense: 1),
      why: 'Lebenspunkte verlängern den Kampf, und ein längerer Kampf gibt '
          'der Energieleiste Zeit, überhaupt eine Rolle zu spielen.',
    ),
    GearItem(
      id: 'gear-gestepptes-wams',
      name: 'Gestepptes Wams',
      slot: GearSlot.ruestung,
      rarity: GearRarity.common,
      price: GearPrices.ruestungCommon2,
      bonus: GearBonus(maxHp: 24, defense: 1),
      why: 'Mehr Polster bei gleicher Verteidigung. Acht Lebenspunkte sind '
          'grob eine Runde länger stehen bleiben — und eine Runde reicht '
          'für einen teuren Zug.',
    ),
    GearItem(
      id: 'gear-schuppenpanzer',
      name: 'Schuppenpanzer',
      slot: GearSlot.ruestung,
      rarity: GearRarity.uncommon,
      price: GearPrices.ruestungUncommon1,
      bonus: GearBonus(maxHp: 32, defense: 3),
      why: 'Das Stück, mit dem der Bergwaechter kippt: Er schlägt hart, und '
          'genau dagegen wirkt Verteidigung am stärksten.',
    ),
    GearItem(
      id: 'gear-kettenpanzer',
      name: 'Kettenpanzer',
      slot: GearSlot.ruestung,
      rarity: GearRarity.uncommon,
      price: GearPrices.ruestungUncommon2,
      bonus: GearBonus(maxHp: 40, defense: 3),
      why: 'Der Schuppenpanzer mit acht Lebenspunkten mehr. Wer den '
          'Bergwaechter knapp verliert, gewinnt ihn damit knapp.',
    ),
    GearItem(
      id: 'gear-plattenharnisch',
      name: 'Plattenharnisch',
      slot: GearSlot.ruestung,
      rarity: GearRarity.rare,
      price: GearPrices.ruestungRare,
      bonus: GearBonus(maxHp: 44, defense: 4),
      why: 'Vier Punkte Verteidigung gibt es sonst auf keinem Platz. Sie '
          'senken jeden eingehenden Treffer anteilig — gegen harte Gegner '
          'wirken sie deshalb stärker als gegen weiche.',
    ),

    // ---------------------------------------------------------------
    // Helm — der billigste Einstieg, später Leben und Verteidigung
    // ---------------------------------------------------------------
    GearItem(
      id: 'gear-lederkappe',
      name: 'Lederkappe',
      slot: GearSlot.helm,
      rarity: GearRarity.common,
      price: GearPrices.helmCommon1,
      bonus: GearBonus(maxHp: 8),
      why: 'Der billigste Platz, und der erste, den man belegen sollte: '
          'Lebenspunkte wirken gegen jeden Gegner gleich gut.',
    ),
    GearItem(
      id: 'gear-eisenhaube',
      name: 'Eisenhaube',
      slot: GearSlot.helm,
      rarity: GearRarity.common,
      price: GearPrices.helmCommon2,
      bonus: GearBonus(maxHp: 14),
      why: 'Sechs Lebenspunkte mehr als die Lederkappe, zum immer noch '
          'zweitbilligsten Preis im Laden. Wer nicht weiß, wo er anfangen '
          'soll, fängt hier an.',
    ),
    GearItem(
      id: 'gear-schuppenhaube',
      name: 'Schuppenhaube',
      slot: GearSlot.helm,
      rarity: GearRarity.uncommon,
      price: GearPrices.helmUncommon1,
      bonus: GearBonus(maxHp: 18, defense: 1),
      why: 'Der erste Helm, der auch Verteidigung mitbringt. Ab hier zählt '
          'der Platz gegen starke Gegner doppelt.',
    ),
    GearItem(
      id: 'gear-visierhelm',
      name: 'Visierhelm',
      slot: GearSlot.helm,
      rarity: GearRarity.uncommon,
      price: GearPrices.helmUncommon2,
      bonus: GearBonus(maxHp: 24, defense: 1),
      why: 'Sechs Lebenspunkte über der Schuppenhaube. Ein ruhiger Kauf für '
          'alle, die lieber lange stehen als schnell treffen.',
    ),
    GearItem(
      id: 'gear-turnierhelm',
      name: 'Turnierhelm',
      slot: GearSlot.helm,
      rarity: GearRarity.rare,
      price: GearPrices.helmRare,
      bonus: GearBonus(maxHp: 26, defense: 2),
      why: 'Zwei Punkte Verteidigung auf dem Kopf. Zusammen mit einem '
          'Panzer ist das der Unterschied zwischen zehn und dreizehn '
          'Runden gegen den Bergwaechter.',
    ),

    // ---------------------------------------------------------------
    // Schuhe — der Platz für Verteidigung
    // ---------------------------------------------------------------
    GearItem(
      id: 'gear-feste-stiefel',
      name: 'Feste Stiefel',
      slot: GearSlot.schuhe,
      rarity: GearRarity.common,
      price: GearPrices.schuheCommon1,
      bonus: GearBonus(defense: 1),
      why: 'Verteidigung senkt jeden eingehenden Treffer prozentual. Gegen '
          'starke Gegner ist sie deshalb mehr wert als gegen schwache.',
    ),
    GearItem(
      id: 'gear-genagelte-stiefel',
      name: 'Genagelte Stiefel',
      slot: GearSlot.schuhe,
      rarity: GearRarity.common,
      price: GearPrices.schuheCommon2,
      bonus: GearBonus(maxHp: 6, defense: 1),
      why: 'Dieselbe Verteidigung wie die festen Stiefel, dazu etwas '
          'Polster. Der billigste Weg zu beidem auf einem Platz.',
    ),
    GearItem(
      id: 'gear-schienbeinschutz',
      name: 'Schienbeinschutz',
      slot: GearSlot.schuhe,
      rarity: GearRarity.uncommon,
      price: GearPrices.schuheUncommon1,
      bonus: GearBonus(defense: 2),
      why: 'Zwei Punkte Verteidigung senken jeden Treffer spürbar — gegen '
          'den Söldner deutlich mehr als gegen den Wegelagerer.',
    ),
    GearItem(
      id: 'gear-stahlbeinlinge',
      name: 'Stahlbeinlinge',
      slot: GearSlot.schuhe,
      rarity: GearRarity.uncommon,
      price: GearPrices.schuheUncommon2,
      bonus: GearBonus(maxHp: 10, defense: 2),
      why: 'Verteidigung und Leben auf demselben Platz. Wer beides will, '
          'zahlt hier weniger als für zwei getrennte Stücke.',
    ),
    GearItem(
      id: 'gear-schwere-schienen',
      name: 'Schwere Schienen',
      slot: GearSlot.schuhe,
      rarity: GearRarity.rare,
      price: GearPrices.schuheRare,
      bonus: GearBonus(maxHp: 6, defense: 3),
      why: 'Drei Punkte Verteidigung auf dem billigsten Platz des Ladens. '
          'Zusammen mit einem Panzer stehen damit sieben zusammen — mehr '
          'geht im Spiel nicht.',
    ),

    // ---------------------------------------------------------------
    // Ring — Energie, und damit die Reihenfolge der Züge
    // ---------------------------------------------------------------
    GearItem(
      id: 'gear-schlichter-ring',
      name: 'Schlichter Ring',
      slot: GearSlot.ring,
      rarity: GearRarity.common,
      price: GearPrices.ringCommon1,
      bonus: GearBonus(maxEnergy: 1),
      why: 'Ein Punkt Energie mehr heißt: Der Wuchtschlag ist eine Runde '
          'früher bezahlbar. Das teuerste der gewöhnlichen Stücke, weil es '
          'nicht eine Zahl erhöht, sondern eine Entscheidung ändert.',
    ),
    GearItem(
      id: 'gear-kupferring',
      name: 'Kupferring',
      slot: GearSlot.ring,
      rarity: GearRarity.common,
      price: GearPrices.ringCommon2,
      bonus: GearBonus(maxHp: 6, maxEnergy: 1),
      why: 'Derselbe Energiepunkt wie der schlichte Ring, dazu etwas Leben. '
          'Der ruhigere von beiden — und der bessere, wenn Kämpfe zu früh '
          'enden.',
    ),
    GearItem(
      id: 'gear-taktring',
      name: 'Taktring',
      slot: GearSlot.ring,
      rarity: GearRarity.uncommon,
      price: GearPrices.ringUncommon1,
      bonus: GearBonus(maxEnergy: 2),
      why: 'Zwei Punkte Energie machen aus „Wuchtschlag, wenn es reicht" '
          'ein „Wuchtschlag, wann ich will". Das Stück, das die '
          'Reihenfolge der Züge verändert.',
    ),
    GearItem(
      id: 'gear-siegelring',
      name: 'Siegelring',
      slot: GearSlot.ring,
      rarity: GearRarity.uncommon,
      price: GearPrices.ringUncommon2,
      bonus: GearBonus(maxHp: 10, maxEnergy: 2),
      why: 'Der Taktring mit zehn Lebenspunkten obendrauf. Für alle, denen '
          'der Kampf endet, bevor die zwei Punkte Energie sich auszahlen.',
    ),
    GearItem(
      id: 'gear-aderring',
      name: 'Aderring',
      slot: GearSlot.ring,
      rarity: GearRarity.rare,
      price: GearPrices.ringRare,
      bonus: GearBonus(maxHp: 8, maxEnergy: 3),
      why: 'Drei Punkte Energie ändern nicht einen Zug, sondern den ganzen '
          'Rhythmus. Sternenfall kostet zehn — mit diesem Ring wird er '
          'überhaupt erst erreichbar.',
    ),

    // ---------------------------------------------------------------
    // Talisman — Vielseitigkeit, später die zweite Energiequelle
    // ---------------------------------------------------------------
    GearItem(
      id: 'gear-glasperle',
      name: 'Glasperle',
      slot: GearSlot.talisman,
      rarity: GearRarity.common,
      price: GearPrices.talismanCommon1,
      bonus: GearBonus(attack: 1, maxHp: 4),
      why: 'Der Platz für kleine Vielseitigkeit. Wer nicht weiß, was fehlt, '
          'nimmt hier etwas von beidem.',
    ),
    GearItem(
      id: 'gear-flusskiesel',
      name: 'Flusskiesel',
      slot: GearSlot.talisman,
      rarity: GearRarity.common,
      price: GearPrices.talismanCommon2,
      bonus: GearBonus(attack: 1, maxHp: 12),
      why: 'Mehr Leben als die Glasperle bei gleichem Angriff. Der Talisman '
          'für alle, die erst einmal überleben wollen.',
    ),
    GearItem(
      id: 'gear-bernsteinamulett',
      name: 'Bernsteinamulett',
      slot: GearSlot.talisman,
      rarity: GearRarity.uncommon,
      price: GearPrices.talismanUncommon1,
      bonus: GearBonus(maxHp: 8, maxEnergy: 1),
      why: 'Der erste Talisman mit Energie. Ab hier ist der Platz keine '
          'Kleinigkeit mehr, sondern eine Entscheidung.',
    ),
    GearItem(
      id: 'gear-silberamulett',
      name: 'Silberamulett',
      slot: GearSlot.talisman,
      rarity: GearRarity.uncommon,
      price: GearPrices.talismanUncommon2,
      bonus: GearBonus(attack: 2, maxHp: 10, maxEnergy: 1),
      why: 'Energie, Angriff und Leben auf einem Platz. Nichts davon viel, '
          'alles davon nützlich — der vielseitigste Kauf im Laden.',
    ),
    GearItem(
      id: 'gear-runenamulett',
      name: 'Runenamulett',
      slot: GearSlot.talisman,
      rarity: GearRarity.rare,
      price: GearPrices.talismanRare,
      bonus: GearBonus(attack: 2, maxHp: 6, maxEnergy: 2),
      why: 'Zwei Punkte Energie außerhalb des Rings. Wer beide Plätze auf '
          'Energie legt, spielt einen sichtbar anderen Kampf als jemand '
          'mit denselben Werten in Angriff.',
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

  /// Alles einer Seltenheit auf einem Platz, günstigstes zuerst.
  static List<GearItem> forSlotAndRarity(GearSlot slot, GearRarity rarity) {
    return List<GearItem>.unmodifiable(
      forSlot(slot).where((item) => item.rarity == rarity),
    );
  }

  /// Was ein kompletter Satz der günstigsten Stufe kostet — der Maßstab
  /// für „nach etwa einem Monat tragbar".
  static int get cheapestFullSetPrice {
    var sum = 0;
    for (final slot in GearSlot.values) {
      final items = forSlot(slot);
      if (items.isNotEmpty) sum += items.first.price;
    }
    return sum;
  }
}

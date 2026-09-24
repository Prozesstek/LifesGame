/// Sämtliche Stellschrauben der Ausrüstung an einem Ort.
///
/// Gleiche Regel wie bei `combat/balance.dart`, `theory/rewards.dart`,
/// `habits/rewards.dart` und `progression/level_curve.dart`: Steht eine
/// dieser Zahlen irgendwo anders im Code, ist das ein Bug.
///
/// **Der Maßstab ist der Gold-Zufluss, nicht das Gefühl.** Fünf
/// Gewohnheiten bringen 25 Gold am Tag (`HabitRewards.goldPerCheck`), der
/// ganze Skillbaum einmalig ein paar Hundert. `test/catalog_test.dart`
/// rechnet das nach, statt es zu behaupten — und zwar an zwei Grenzen:
/// Ein voller Satz der billigsten Stücke muss in etwa einem Monat tragbar
/// sein, und das teuerste Einzelstück ebenso.
///
/// **Seit ADR-0047 ein Drittel billiger.** Die 25 Gold sind nur noch der
/// Sockel: Truhe, Dailies und Rückfrage bringen einen fleissigen Spieler
/// auf rund 80 am Tag (`tool/runway_sim.dart`), und trotzdem kam im Test
/// tagelang kein Kauf. Die Grenzen oben rechnen weiter mit dem Sockel —
/// wer nur abhakt, soll den Laden auch erreichen.
///
/// **Fünf Stücke je Platz, drei Seltenheiten** (ADR-0029). Die Preise
/// steigen durchgehend, und die Wirkung steigt mit — auch über die
/// Seltenheiten hinweg. Dass sie das *dürften*, ohne es zu müssen, ist der
/// Punkt von ADR-0029; dass sie es hier trotzdem tun, ist eine bewusste
/// Wahl: Solange kein Set und keine Fähigkeit am Stück hängt, wäre ein
/// teureres und schwächeres Stück nichts als eine Falle.
///
/// | Platz | Gewöhnlich | Ungewöhnlich | Selten | Episch | Legendär |
/// |---|---|---|---|---|---|
/// | Waffe | 90 · 160 | 410 · 510 | 650 | 770 · 900 | 1200 |
/// | Rüstung | 110 · 190 | 450 · 560 | 690 | 830 · 970 | 1300 |
/// | Helm | 70 · 130 | 280 · 370 | 510 | 630 · 730 | 1000 |
/// | Schuhe | 70 · 130 | 270 · 350 | 480 | 600 · 700 | 970 |
/// | Ring | 120 · 210 | 490 · 590 | 700 | 870 · 1000 | 1330 |
/// | Talisman | 100 · 180 | 350 · 440 | 590 | 730 · 870 | 1170 |
///
/// **Episch und Legendär sind nicht über den Preis knapp, sondern über die
/// Gegnerreihe** (`GearGates`, ADR-0034). Deshalb liegen sie nur mäßig
/// über Selten: Die Sperre ist die Hürde, der Preis nur der zweite Schritt.
/// Wären sie zusätzlich unbezahlbar, sähe sie im 30-Tage-Lauf niemand.
///
/// **Die Waffen sind der eine Platz, auf dem der Preis am wenigsten sagt.**
/// Man kauft die zweite Waffe nicht für mehr Zahlen, sondern für einen
/// anderen Rhythmus (Ziel 3). Die Klinge für 510 richtet je Treffer
/// *weniger* an als die für 160 und zahlt das mit Energie zurück — genau
/// der Fall, den ADR-0029 zwischen den Seltenheiten erlaubt.
abstract final class GearPrices {
  /// Wie viel ein Verkauf zurückbringt — ein Viertel des Katalogpreises,
  /// egal ob gekauft oder erbeutet (ADR-0048).
  ///
  /// **Bis dahin die Hälfte** (ADR-0031), als jedes Stück teuer bezahlt
  /// war. Seit es Beute gibt, wäre die Hälfte eine Goldquelle aus dem
  /// Spielen: fünf bis acht Stücke am Tag, mehr als die Gewohnheiten
  /// bringen, und der Laden wäre Nebensache. Ein Viertel ist Aufräumen
  /// mit Taschengeld. Alte Verkäufe behalten ihren alten Satz
  /// (`Loadout.legacyRefundShare`).
  static const double refundShare = 0.25;

  // --- Waffe ---
  static const int waffeCommon1 = 90;
  static const int waffeCommon2 = 160;
  static const int waffeUncommon1 = 410;
  static const int waffeUncommon2 = 510;

  /// Die teuerste Waffe bleibt unter dem Aderring (700). Wer seinen
  /// ganzen Rhythmus umstellen will, zahlt weniger als für das teuerste
  /// Einzelstück des Ladens — sonst wäre ein Waffenwechsel eine
  /// Lebensentscheidung statt eines Versuchs.
  static const int waffeRare = 650;
  static const int waffeEpic1 = 770;
  static const int waffeEpic2 = 900;
  static const int waffeLegendary = 1200;

  // --- Rüstung ---
  static const int ruestungCommon1 = 110;
  static const int ruestungCommon2 = 190;
  static const int ruestungUncommon1 = 450;
  static const int ruestungUncommon2 = 560;
  static const int ruestungRare = 690;
  static const int ruestungEpic1 = 830;
  static const int ruestungEpic2 = 970;
  static const int ruestungLegendary = 1300;

  // --- Helm ---
  static const int helmCommon1 = 70;
  static const int helmCommon2 = 130;
  static const int helmUncommon1 = 280;
  static const int helmUncommon2 = 370;
  static const int helmRare = 510;
  static const int helmEpic1 = 630;
  static const int helmEpic2 = 730;
  static const int helmLegendary = 1000;

  // --- Schuhe ---
  static const int schuheCommon1 = 70;
  static const int schuheCommon2 = 130;
  static const int schuheUncommon1 = 270;
  static const int schuheUncommon2 = 350;
  static const int schuheRare = 480;
  static const int schuheEpic1 = 600;
  static const int schuheEpic2 = 700;
  static const int schuheLegendary = 970;

  // --- Ring ---
  static const int ringCommon1 = 120;
  static const int ringCommon2 = 210;
  static const int ringUncommon1 = 490;
  static const int ringUncommon2 = 590;

  /// Das teuerste **frei zugängliche** Stück im Laden. Bei 25 Gold am Tag
  /// sind das 28 Tage, bei einem fleissigen Spieler knapp neun.
  static const int ringRare = 700;
  static const int ringEpic1 = 870;
  static const int ringEpic2 = 1000;

  /// Das teuerste Stück überhaupt. 53 Tage Gewohnheiten allein — aber wer
  /// es kaufen darf, hat zwanzig Sprossen geschafft und deren Gold dazu.
  static const int ringLegendary = 1330;

  // --- Talisman ---
  static const int talismanCommon1 = 100;
  static const int talismanCommon2 = 180;
  static const int talismanUncommon1 = 350;
  static const int talismanUncommon2 = 440;
  static const int talismanRare = 590;
  static const int talismanEpic1 = 730;
  static const int talismanEpic2 = 870;
  static const int talismanLegendary = 1170;
}

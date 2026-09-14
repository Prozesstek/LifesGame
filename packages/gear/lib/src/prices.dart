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
/// **Fünf Stücke je Platz, drei Seltenheiten** (ADR-0029). Die Preise
/// steigen durchgehend, und die Wirkung steigt mit — auch über die
/// Seltenheiten hinweg. Dass sie das *dürften*, ohne es zu müssen, ist der
/// Punkt von ADR-0029; dass sie es hier trotzdem tun, ist eine bewusste
/// Wahl: Solange kein Set und keine Fähigkeit am Stück hängt, wäre ein
/// teureres und schwächeres Stück nichts als eine Falle.
///
/// | Platz | Gewöhnlich | Ungewöhnlich | Selten | Episch | Legendär |
/// |---|---|---|---|---|---|
/// | Waffe | 140 · 240 | 620 · 760 | 980 | 1150 · 1350 | 1800 |
/// | Rüstung | 160 · 280 | 680 · 840 | 1040 | 1250 · 1450 | 1950 |
/// | Helm | 110 · 200 | 420 · 560 | 760 | 950 · 1100 | 1500 |
/// | Schuhe | 100 · 190 | 400 · 530 | 720 | 900 · 1050 | 1450 |
/// | Ring | 180 · 320 | 740 · 880 | 1050 | 1300 · 1500 | 2000 |
/// | Talisman | 150 · 270 | 520 · 660 | 880 | 1100 · 1300 | 1750 |
///
/// **Episch und Legendär sind nicht über den Preis knapp, sondern über die
/// Gegnerreihe** (`GearGates`, ADR-0034). Deshalb liegen sie nur mäßig
/// über Selten: Die Sperre ist die Hürde, der Preis nur der zweite Schritt.
/// Wären sie zusätzlich unbezahlbar, sähe sie im 30-Tage-Lauf niemand.
///
/// **Die Waffen sind der eine Platz, auf dem der Preis am wenigsten sagt.**
/// Man kauft die zweite Waffe nicht für mehr Zahlen, sondern für einen
/// anderen Rhythmus (Ziel 3). Die Klinge für 760 richtet je Treffer
/// *weniger* an als die für 240 und zahlt das mit Energie zurück — genau
/// der Fall, den ADR-0029 zwischen den Seltenheiten erlaubt.
abstract final class GearPrices {
  /// Wie viel ein Verkauf zurückbringt — die Hälfte des Preises.
  ///
  /// **Die Zahl ist der ganze Verkauf** ([ADR-0031](../../../../docs/decisions/0031-verkauf-als-versenkte-kosten.md)).
  /// Bei 1,0 wäre der Laden folgenlos: kaufen, ansehen, zurückgeben,
  /// nächstes ansehen — und die Entscheidung, um die es geht, gäbe es
  /// nicht mehr. Bei 0,0 gäbe es keinen Verkauf, sondern eine
  /// Löschtaste.
  ///
  /// Die Hälfte lässt einen Irrtum korrigieren und kostet dafür etwa fünf
  /// Tage Gewohnheiten je Stück. `catalog_test.dart` hält beide Grenzen
  /// fest.
  static const double refundShare = 0.5;

  // --- Waffe ---
  static const int waffeCommon1 = 140;
  static const int waffeCommon2 = 240;
  static const int waffeUncommon1 = 620;
  static const int waffeUncommon2 = 760;

  /// Die teuerste Waffe bleibt unter dem Aderring (1050). Wer seinen
  /// ganzen Rhythmus umstellen will, zahlt weniger als für das teuerste
  /// Einzelstück des Ladens — sonst wäre ein Waffenwechsel eine
  /// Lebensentscheidung statt eines Versuchs.
  static const int waffeRare = 980;
  static const int waffeEpic1 = 1150;
  static const int waffeEpic2 = 1350;
  static const int waffeLegendary = 1800;

  // --- Rüstung ---
  static const int ruestungCommon1 = 160;
  static const int ruestungCommon2 = 280;
  static const int ruestungUncommon1 = 680;
  static const int ruestungUncommon2 = 840;
  static const int ruestungRare = 1040;
  static const int ruestungEpic1 = 1250;
  static const int ruestungEpic2 = 1450;
  static const int ruestungLegendary = 1950;

  // --- Helm ---
  static const int helmCommon1 = 110;
  static const int helmCommon2 = 200;
  static const int helmUncommon1 = 420;
  static const int helmUncommon2 = 560;
  static const int helmRare = 760;
  static const int helmEpic1 = 950;
  static const int helmEpic2 = 1100;
  static const int helmLegendary = 1500;

  // --- Schuhe ---
  static const int schuheCommon1 = 100;
  static const int schuheCommon2 = 190;
  static const int schuheUncommon1 = 400;
  static const int schuheUncommon2 = 530;
  static const int schuheRare = 720;
  static const int schuheEpic1 = 900;
  static const int schuheEpic2 = 1050;
  static const int schuheLegendary = 1450;

  // --- Ring ---
  static const int ringCommon1 = 180;
  static const int ringCommon2 = 320;
  static const int ringUncommon1 = 740;
  static const int ringUncommon2 = 880;

  /// Das teuerste **frei zugängliche** Stück im Laden. Bei 25 Gold am Tag
  /// sind das rund 42 Tage — knapp unter der Grenze, die
  /// `catalog_test.dart` zieht.
  static const int ringRare = 1050;
  static const int ringEpic1 = 1300;
  static const int ringEpic2 = 1500;

  /// Das teuerste Stück überhaupt. 80 Tage Gewohnheiten — aber wer es
  /// kaufen darf, hat zwanzig Sprossen geschafft und deren Gold dazu.
  static const int ringLegendary = 2000;

  // --- Talisman ---
  static const int talismanCommon1 = 150;
  static const int talismanCommon2 = 270;
  static const int talismanUncommon1 = 520;
  static const int talismanUncommon2 = 660;
  static const int talismanRare = 880;
  static const int talismanEpic1 = 1100;
  static const int talismanEpic2 = 1300;
  static const int talismanLegendary = 1750;
}

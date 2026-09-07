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
/// | Platz | Gewöhnlich | Ungewöhnlich | Selten |
/// |---|---|---|---|
/// | Waffe | 140 | 620 | — |
/// | Rüstung | 160 · 280 | 680 · 840 | 1040 |
/// | Helm | 110 · 200 | 420 · 560 | 760 |
/// | Schuhe | 100 · 190 | 400 · 530 | 720 |
/// | Ring | 180 · 320 | 740 · 880 | 1050 |
/// | Talisman | 150 · 270 | 520 · 660 | 880 |
///
/// Die Waffe ist bewusst noch nicht gefüllt: Jede Waffe im Laden muss eine
/// Fähigkeit mitbringen (`test/abilities_seam_test.dart` in der App), und
/// die kommen mit Ziel 3.
abstract final class GearPrices {
  // --- Waffe ---
  static const int waffeCommon1 = 140;
  static const int waffeUncommon1 = 620;

  // --- Rüstung ---
  static const int ruestungCommon1 = 160;
  static const int ruestungCommon2 = 280;
  static const int ruestungUncommon1 = 680;
  static const int ruestungUncommon2 = 840;
  static const int ruestungRare = 1040;

  // --- Helm ---
  static const int helmCommon1 = 110;
  static const int helmCommon2 = 200;
  static const int helmUncommon1 = 420;
  static const int helmUncommon2 = 560;
  static const int helmRare = 760;

  // --- Schuhe ---
  static const int schuheCommon1 = 100;
  static const int schuheCommon2 = 190;
  static const int schuheUncommon1 = 400;
  static const int schuheUncommon2 = 530;
  static const int schuheRare = 720;

  // --- Ring ---
  static const int ringCommon1 = 180;
  static const int ringCommon2 = 320;
  static const int ringUncommon1 = 740;
  static const int ringUncommon2 = 880;

  /// Das teuerste Stück im Laden. Bei 25 Gold am Tag sind das rund 42
  /// Tage — knapp unter der Grenze, die `catalog_test.dart` zieht.
  static const int ringRare = 1050;

  // --- Talisman ---
  static const int talismanCommon1 = 150;
  static const int talismanCommon2 = 270;
  static const int talismanUncommon1 = 520;
  static const int talismanUncommon2 = 660;
  static const int talismanRare = 880;
}

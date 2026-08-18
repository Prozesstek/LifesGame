/// Sämtliche Stellschrauben der Ausrüstung an einem Ort.
///
/// Gleiche Regel wie bei `combat/balance.dart`, `theory/rewards.dart`,
/// `habits/rewards.dart` und `progression/level_curve.dart`: Steht eine
/// dieser Zahlen irgendwo anders im Code, ist das ein Bug.
///
/// **Der Maßstab ist der Gold-Zufluss, nicht das Gefühl.** Fünf
/// Gewohnheiten bringen 25 Gold am Tag (`HabitRewards.goldPerCheck`), der
/// ganze Skillbaum einmalig ein paar Hundert. Daran hängen die beiden
/// Stufen: Die erste soll nach etwa einer Woche komplett tragbar sein, die
/// zweite nach etwa einem Monat. `dart run example/price_sim.dart` rechnet
/// das nach, statt es zu behaupten.
abstract final class GearPrices {
  /// Erste Stufe: Grundversorgung. Das Konzept nennt den Shop
  /// „verlässlich, planbar, Mittelmaß" (Abschnitt 4) — diese Stufe ist
  /// genau das.
  static const int stufe1Waffe = 140;
  static const int stufe1Ruestung = 160;
  static const int stufe1Helm = 110;
  static const int stufe1Schuhe = 100;
  static const int stufe1Ring = 180;
  static const int stufe1Talisman = 150;

  /// Zweite Stufe: ersetzt die erste. Zusammen mit einem Monat
  /// Gewohnheiten reicht sie gegen den Bergwaechter.
  static const int stufe2Waffe = 620;
  static const int stufe2Ruestung = 680;
  static const int stufe2Ring = 740;
}

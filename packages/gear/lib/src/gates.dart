import 'item.dart';

/// Ab welcher Sprosse der Gegnerreihe eine Seltenheit kaufbar wird.
///
/// **Episch und Legendär sind im Laden nicht teurer, sondern verdient**
/// (ADR-0034). Bis dahin galt: Im Laden gibt es nichts zu erreichen, nur zu
/// kaufen — und deshalb drei Stufen. Mit der Gegnerreihe (ADR-0032) gibt es
/// jetzt etwas zu erreichen, und die beiden oberen Stufen hängen daran.
///
/// **Die Zahlen stehen hier und nicht in `package:combat`.** Dieses Package
/// kennt die Reihe nicht; es hält nur die Sprosse als Zahl. Dass sie zu
/// einer echten Sprosse gehört und die Reihe lang genug ist, prüft
/// `test/gear_gates_seam_test.dart` in der App — die einzige Stelle, die
/// beide sieht.
///
/// **Warum 10 und 20, nicht 15 und 30.** Die dreißigste Sprosse ist der
/// letzte Gegner. Wer dort Legendäres freischaltet, hat nichts mehr, wogegen
/// er es tragen könnte. Ab Sprosse 20 bleiben zehn Gegner, die den Kauf
/// rechtfertigen — und Sprosse 20 ist der Bergwächter, der Gegner, an dem
/// die alte Dreierreihe endete.
abstract final class GearGates {
  /// Ab hier gibt es Episches.
  static const int epicRung = 10;

  /// Ab hier gibt es Legendäres.
  static const int legendaryRung = 20;

  /// Welche Sprosse ein Stück dieser Seltenheit verlangt. 0 heißt: keine.
  static int rungFor(GearRarity rarity) {
    return switch (rarity) {
      GearRarity.common || GearRarity.uncommon || GearRarity.rare => 0,
      GearRarity.epic => epicRung,
      GearRarity.legendary => legendaryRung,
    };
  }

  /// Ob ein Stück dieser Seltenheit bei [highestRung] geschlagenen
  /// Sprossen kaufbar ist.
  static bool isOpen(GearRarity rarity, {required int highestRung}) {
    return highestRung >= rungFor(rarity);
  }
}

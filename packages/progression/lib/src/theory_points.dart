import 'level_curve.dart';

/// Wie viele Theoriepunkte ein Level eingebracht hat.
///
/// Steht neben der Levelkurve, weil ein Theoriepunkt das ist, was ein
/// *Levelaufstieg gibt* — nicht, was der Theoriebaum verlangt. Was ein
/// Knoten kostet, weiß `packages/theory`; wie viel im Beutel ist, weiß
/// dieses Package. Die beiden treffen sich erst in der App.
///
/// **Zwei Punkte je Aufstieg** (ADR-0019). ADR-0012 hatte einen
/// vorgesehen; Issue #16 hat die Zahl verdoppelt.
abstract final class TheoryPoints {
  /// Was ein Levelaufstieg einbringt.
  ///
  /// Steht diese Zahl irgendwo anders im Code, ist das ein Bug — dieselbe
  /// Regel wie bei der Kurve und den Slots.
  static const int perLevel = 2;

  /// Alle Punkte, die ein Spielerleben hergibt.
  ///
  /// **98 für einen Startbaum aus 20 kostenpflichtigen Knoten.** Der
  /// Vorrat übersteigt den Baum damit um ein Vielfaches, und ab Level 11
  /// ist jeder weitere Punkt wertlos. Das ist in ADR-0019 bewusst in Kauf
  /// genommen: Ein Baum, der offensteht, ist besser als einer, der leer
  /// ist. Zum Nachjustieren ist es ab 40 Knoten vorgemerkt.
  static const int lifetimeTotal = (LevelCurve.maxLevel - 1) * perLevel;

  /// Wie viele Punkte ein Charakter auf [level] insgesamt verdient hat.
  ///
  /// Level 1 gibt nichts: Der Punkt kommt für den *Aufstieg*, nicht für
  /// den Start.
  static int earnedAt(int level) {
    if (level <= LevelCurve.minLevel) return 0;

    final capped = level > LevelCurve.maxLevel ? LevelCurve.maxLevel : level;
    return (capped - LevelCurve.minLevel) * perLevel;
  }

  /// Was auf [level] noch übrig ist, nachdem [spent] ausgegeben wurde.
  ///
  /// Nie negativ. Ein Spielstand, der mehr ausgegeben hat als er haben
  /// dürfte, ist ein Fehler — aber keiner, der die Anzeige kaputt machen
  /// darf (ADR-0010: nachsichtig lesen).
  static int availableAt({required int level, required int spent}) {
    final left = earnedAt(level) - spent;
    return left < 0 ? 0 : left;
  }

  /// Ob [cost] auf [level] noch bezahlbar ist.
  static bool canAfford({
    required int level,
    required int spent,
    required int cost,
  }) {
    return availableAt(level: level, spent: spent) >= cost;
  }
}

import 'level_curve.dart';

/// Wie viele Theoriepunkte ein Level eingebracht hat.
///
/// Steht neben der Levelkurve, weil ein Theoriepunkt das ist, was ein
/// *Levelaufstieg gibt* — nicht, was der Theoriebaum verlangt. Was ein
/// Knoten kostet, weiß `packages/theory`; wie viel im Beutel ist, weiß
/// dieses Package. Die beiden treffen sich erst in der App.
///
/// **Ein Punkt je Aufstieg** (ADR-0035). ADR-0012 hatte einen
/// vorgesehen, ADR-0019 hat die Zahl auf zwei verdoppelt, ADR-0035 hat
/// sie zurückgenommen.
abstract final class TheoryPoints {
  /// Was ein Levelaufstieg einbringt.
  ///
  /// Steht diese Zahl irgendwo anders im Code, ist das ein Bug — dieselbe
  /// Regel wie bei der Kurve und den Slots.
  static const int perLevel = 1;

  /// Alle Punkte, die ein Spielerleben hergibt.
  ///
  /// **49 für einen Startbaum aus 20 kostenpflichtigen Knoten.** Der
  /// Baum steht damit ab Level 21 ganz offen statt ab Level 11 — lange
  /// genug, dass die Reihenfolge eine Wahl ist (ADR-0035).
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

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

  /// Die Punkte, mit denen jeder anfängt (ADR-0070).
  ///
  /// **Neun: so viel, wie die Grundlagen kosten.** Seit das Handbuch im
  /// Baum steht, kosten seine fünf Seiten wie alles einen Punkt, und der
  /// Weg zu ihnen — Geist, Selbstentwicklung, Gewohnheiten, Die vier
  /// Regeln — vier weitere (`theoryBasicsPath` in `package:theory`).
  /// Vorher gab es einen Punkt (ADR-0051), und das Handbuch war
  /// kostenlos.
  ///
  /// **Niemand muss sie dort ausgeben.** Wer sie in ein anderes Gebiet
  /// steckt, hat die Grundlagen nicht gelesen; das ist die Wahl, die
  /// diese Zahl kauft. Dass sie zum Weg passt, prüft
  /// `test/abilities_seam_test.dart` in der App — dieses Package kennt
  /// den Baum nicht.
  static const int atStart = 9;

  /// Alle Punkte, die ein Spielerleben hergibt.
  ///
  /// **58: die neun vom Start und einer je Aufstieg.** Der Baum ist seit
  /// ADR-0050 größer, als diese Zahl je öffnen kann — die Knappheit ist
  /// der Zweck (ADR-0037).
  static const int lifetimeTotal =
      atStart + (LevelCurve.maxLevel - 1) * perLevel;

  /// Wie viele Punkte ein Charakter auf [level] insgesamt verdient hat.
  ///
  /// Level 1 hat nur die Startpunkte ([atStart]); jeder weitere kommt
  /// für einen *Aufstieg*.
  static int earnedAt(int level) {
    if (level < LevelCurve.minLevel) return 0;

    final capped = level > LevelCurve.maxLevel ? LevelCurve.maxLevel : level;
    return atStart + (capped - LevelCurve.minLevel) * perLevel;
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

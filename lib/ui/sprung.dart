import 'dart:math' as math;

/// **Wie etwas aufspringt** — eine gedämpfte Feder, reine Rechnung.
///
/// Für alles, was nach einem Tipp sichtbar *passieren* soll: der Kreis
/// eines Häkchens, die Flamme der Tageskette. Eine Feder statt einer
/// Kurve aus `Curves`, weil sie über das Ziel hinausschiesst und
/// zurückpendelt — genau das unterscheidet ein Aufspringen von einem
/// Einblenden.
///
/// [t] läuft jeweils von 0 bis 1 über die ganze Dauer.
abstract final class Sprung {
  /// Wächst von [von] auf 1, schiesst darüber hinaus und pendelt aus.
  /// Bei `t = 1` steht es **genau** auf 1, damit nach dem Sprung nichts
  /// um einen Hauch zu gross bleibt.
  static double feder(
    double t, {
    double von = 0.3,
    double daempfung = 5,
    double schwingung = 16,
  }) {
    if (t <= 0) return von;
    if (t >= 1) return 1;
    return 1 - (1 - von) * math.exp(-daempfung * t) * math.cos(schwingung * t);
  }

  /// Steht auf 1, springt um [hoehe] hinauf und pendelt zurück auf 1 —
  /// für etwas, das schon da ist und aufflammt.
  static double stoss(
    double t, {
    double hoehe = 0.7,
    double daempfung = 5,
    double schwingung = 14,
  }) {
    if (t <= 0 || t >= 1) return 1;
    return 1 + hoehe * math.exp(-daempfung * t) * math.sin(schwingung * t);
  }

  /// Von 1 auf 0 bis [bis], danach 0.
  static double vergeht(double t, double bis) {
    if (t >= bis) return 0;
    if (t <= 0) return 1;
    return 1 - t / bis;
  }

  /// Wie weit ein Abschnitt von [ab] bis [bis] gelaufen ist, 0 bis 1.
  static double abschnitt(double t, double ab, double bis) {
    if (t <= ab) return 0;
    if (t >= bis) return 1;
    return (t - ab) / (bis - ab);
  }
}

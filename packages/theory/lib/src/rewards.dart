/// Alle Stellschrauben der Theorie-Belohnung an einem Ort.
///
/// Gleiche Regel wie bei der Kampfbalance: Steht eine dieser Zahlen
/// irgendwo anders im Code, ist das ein Bug.
abstract final class TheoryRewards {
  /// Ab wie viel Prozent richtiger Antworten eine Lektion als bestanden gilt.
  ///
  /// 60 % heißt bei drei Fragen: zwei richtige reichen. Eine Lektion soll
  /// Verständnis prüfen, nicht Wortlaut abfragen.
  static const int passPercent = 60;

  /// Erfahrung für das erste Bestehen einer Lektion.
  static const int xpForPass = 40;

  /// Zusatz, wenn alle Fragen richtig sind.
  ///
  /// Bewusst klein gehalten: Theorie ist laut Konzept 30 % des Fortschritts,
  /// perfektes Raten soll den Habit-Teil nicht überholen.
  static const int xpPerfectBonus = 15;

  /// Gold für das erste Bestehen einer Lektion.
  static const int goldForPass = 25;

  /// Ob [correct] von [total] Fragen zum Bestehen reicht.
  static bool passes(int correct, int total) {
    if (total <= 0) return false;
    return correct * 100 >= total * passPercent;
  }

  /// Erfahrung, die für dieses Ergebnis insgesamt zusteht.
  ///
  /// „Insgesamt“, nicht „zusätzlich“: Wiederholt jemand eine Lektion und
  /// wird besser, bekommt er nur die Differenz zum bereits Gutgeschriebenen.
  /// Damit kann man dieselbe Lektion nicht mehrfach abgrasen.
  static int xpFor(int correct, int total) {
    if (!passes(correct, total)) return 0;
    return correct == total ? xpForPass + xpPerfectBonus : xpForPass;
  }

  static int goldFor(int correct, int total) {
    return passes(correct, total) ? goldForPass : 0;
  }
}

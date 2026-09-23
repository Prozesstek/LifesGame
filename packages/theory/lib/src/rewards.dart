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

  /// **Die Rückfrage des Tages** (ADR-0045): Erfahrung für eine richtige
  /// Antwort, einmal je Tag. Bewusst klein — gut ein Zehntel dessen, was
  /// fünf Gewohnheiten am Tag bringen. Sie ist die erste Theorie-Quelle,
  /// die sich jeden Tag wiederholt.
  static const int xpForReview = 10;

  /// Gold dafür. Knapp: Der Laden verkraftet seit ADR-0044 schon die
  /// Tagestruhe.
  static const int goldForReview = 3;

  /// Nach wie vielen Tagen eine Lektion wiederkommt, je nachdem, wie oft
  /// sie in Folge richtig beantwortet wurde. Darüber hinaus bleibt es beim
  /// letzten Abstand. Eine falsche Antwort beginnt die Reihe von vorn.
  static const List<int> reviewIntervals = <int>[1, 3, 7, 21];

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

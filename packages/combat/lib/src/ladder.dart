import 'enemy.dart';

/// Was ein erstmals besiegter Gegner einbringt.
///
/// **Der Kampf gibt etwas, aber nur einmal je Gegner** -- die Entscheidung
/// aus ADR-0032. Bis dahin gab er gar nichts, weil `konzept.md` Abschnitt 2
/// ihn zur *Auszahlung* des Fortschritts erklaert und nicht zu seiner
/// Quelle. Der Einwand galt jedoch nur wiederholbarer Belohnung: Eine
/// Lektion in `package:theory` zahlt ebenfalls, und ebenfalls genau
/// einmal.
///
/// **Die Menge ist damit gedeckelt und nachrechenbar** -- siehe
/// [lifetimeXp] und [lifetimeGold]. Wer an diesen Zahlen dreht, laesst
/// `flutter test test/progression_test.dart` laufen: Dort haengen
/// Belohnungs-, Habit-, Level- und Preiskurve zusammen.
abstract final class LadderRewards {
  /// Erfahrung fuer Sprosse 1.
  static const int baseXp = 20;

  /// Wie viel Erfahrung je Sprosse dazukommt.
  static const int xpPerRung = 5;

  /// Gold fuer Sprosse 1.
  static const int baseGold = 8;

  /// Wie viel Gold je Sprosse dazukommt.
  ///
  /// **Bewusst flacher als die Erfahrung.** Gold hat mit dem Laden einen
  /// Abfluss, der auf den Zufluss aus Gewohnheiten ausgelegt ist (25 am
  /// Tag, siehe `package:gear`). Eine Reihe, die mehr einbringt als ein
  /// Monat Haekchen, machte den Laden zur Formsache.
  static const int goldPerRung = 2;

  static int xpFor(int rung) => baseXp + xpPerRung * (rung - 1);

  static int goldFor(int rung) => baseGold + goldPerRung * (rung - 1);

  /// Alles, was die ganze Reihe ueber ein Spielerleben hergibt.
  static int get lifetimeXp => _summe(xpFor);

  static int get lifetimeGold => _summe(goldFor);

  static int _summe(int Function(int) je) {
    var summe = 0;
    for (var rung = 1; rung <= Enemies.rungs; rung++) {
      summe += je(rung);
    }
    return summe;
  }
}

/// Wie weit jemand in der Gegnerreihe gekommen ist.
///
/// **Eine einzige Zahl, und das ist der ganze Punkt.** Die Reihe wird von
/// unten nach oben gegangen: Wer auf Sprosse 7 steht, hat 1 bis 6
/// geschlagen. Eine Liste besiegter Ids waere dieselbe Information in
/// laenger -- und eine zweite Wahrheit, sobald sie von der Zahl abweicht.
///
/// Erfahrung und Gold stehen deshalb auch hier nicht: Sie werden aus
/// [highestDefeated] **gerechnet** (ADR-0008, ADR-0011). Ein gespeicherter
/// Betrag koennte von der Rechnung abweichen, eine Sprossenzahl *ist* die
/// Rechnung.
class LadderProgress {
  const LadderProgress({this.highestDefeated = 0});

  const LadderProgress.empty() : this();

  /// Die hoechste Sprosse, die geschlagen wurde. 0 heisst: noch keine.
  final int highestDefeated;

  /// Der Gegner, der als Naechstes ansteht.
  ///
  /// Bleibt auf der letzten Sprosse stehen, wenn die Reihe durch ist --
  /// so gibt es immer einen Kampf, auch am Ende.
  int get nextRung {
    final naechste = highestDefeated + 1;
    return naechste > Enemies.rungs ? Enemies.rungs : naechste;
  }

  EnemyBlueprint get nextEnemy => Enemies.atRung(nextRung);

  bool get isComplete => highestDefeated >= Enemies.rungs;

  /// Ob ein Sieg gegen [rung] noch etwas einbringt.
  bool isNewGround(int rung) => rung > highestDefeated;

  int get earnedXp => _summeBis(LadderRewards.xpFor);

  int get earnedGold => _summeBis(LadderRewards.goldFor);

  /// Traegt einen Sieg ein.
  ///
  /// **Nur ein Schritt nach oben zaehlt.** Ein erneuter Sieg gegen einen
  /// laengst geschlagenen Gegner laesst den Stand unveraendert -- und
  /// damit auch Erfahrung und Gold. Das ist die Stelle, an der aus
  /// "Belohnung" keine Dauerquelle wird.
  LadderProgress defeat(int rung) {
    if (!isNewGround(rung)) return this;
    if (rung > Enemies.rungs) return this;

    // Sprossen lassen sich nicht ueberspringen: Wer Sprosse 9 meldet,
    // ohne 8 geschlagen zu haben, hat einen Fehler im Aufrufer -- nicht
    // einen Fortschritt.
    if (rung != highestDefeated + 1) return this;

    return LadderProgress(highestDefeated: rung);
  }

  int _summeBis(int Function(int) je) {
    var summe = 0;
    for (var rung = 1; rung <= highestDefeated; rung++) {
      summe += je(rung);
    }
    return summe;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'defeated': highestDefeated};
  }

  /// Liest den Stand. Was nicht lesbar ist, faellt auf 0 zurueck -- ein
  /// beschaedigter Eintrag darf hoechstens die Reihe zuruecksetzen, nie
  /// den ganzen Stand kosten (ADR-0010).
  factory LadderProgress.fromJson(Map<String, Object?> json) {
    final roh = json['defeated'];
    if (roh is! int || roh <= 0) return const LadderProgress.empty();

    return LadderProgress(
      highestDefeated: roh > Enemies.rungs ? Enemies.rungs : roh,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LadderProgress && other.highestDefeated == highestDefeated;
  }

  @override
  int get hashCode => highestDefeated.hashCode;
}

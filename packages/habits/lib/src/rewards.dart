import 'habit.dart';

/// Ein Streak-Meilenstein: ab [days] Tagen am Stück gilt [multiplier].
class StreakMilestone {
  const StreakMilestone({required this.days, required this.multiplier});

  final int days;
  final double multiplier;
}

/// Wie eine Kurve von erledigten Häkchen zu einem Charakterwert wird.
class StatRule {
  const StatRule({
    required this.base,
    required this.checksPerPoint,
    required this.pointStep,
    required this.maxBonus,
  });

  /// Der Wert eines Charakters, der noch nie etwas abgehakt hat.
  final int base;

  /// Wie viele Häkchen einen Punkt bringen.
  final int checksPerPoint;

  /// Wie viel ein Punkt wert ist.
  final int pointStep;

  /// Obergrenze des Zugewinns. Ohne Deckel überholt ein alter Account
  /// jede Gegnerauslegung.
  final int maxBonus;
}

/// Sämtliche Stellschrauben der Gewohnheiten an einem Ort.
///
/// Gleiche Regel wie bei `combat/balance.dart`, `theory/rewards.dart` und
/// `progression/level_curve.dart`: Steht eine dieser Zahlen irgendwo anders
/// im Code, ist das ein Bug.
abstract final class HabitRewards {
  /// Erfahrung für ein Häkchen, vor dem Streak-Multiplikator.
  ///
  /// Zum Vergleich: Eine Theorie-Lektion bringt einmalig 40. Ein Häkchen
  /// ist kleiner, kommt dafür jeden Tag wieder — genau das Verhältnis, das
  /// das Konzept mit „50 % Habits, 30 % Theorie“ meint.
  static const int xpPerCheck = 15;

  /// Gold für ein Häkchen. Bewusst **ohne** Streak-Multiplikator: Der
  /// Streak soll den Charakter stärken, nicht die Geldbörse. Sonst wird
  /// eine lange Streak zur Abkürzung durch den Shop.
  static const int goldPerCheck = 5;

  /// Wie viele Gewohnheiten gleichzeitig laufen dürfen.
  ///
  /// Eine Obergrenze ist kein Gängeln: Ohne sie hakt man alle Vorlagen an
  /// und keine davon ab. Sie hält außerdem die Erfahrung pro Tag
  /// berechenbar, worauf die Levelkurve angewiesen ist.
  static const int maxActiveHabits = 5;

  /// Deckel des Streak-Multiplikators.
  ///
  /// Das Konzept empfiehlt x2 (Abschnitt 3.7): Bei x3 wird der Verlust
  /// einer langen Streak so schmerzhaft, dass Nutzer aufgeben statt neu
  /// anzufangen.
  static const double multiplierCap = 2.0;

  /// Die Meilensteine, aufsteigend. Der letzte trifft [multiplierCap].
  static const List<StreakMilestone> streakMilestones = <StreakMilestone>[
    StreakMilestone(days: 3, multiplier: 1.2),
    StreakMilestone(days: 7, multiplier: 1.4),
    StreakMilestone(days: 14, multiplier: 1.6),
    StreakMilestone(days: 30, multiplier: 1.8),
    StreakMilestone(days: 60, multiplier: multiplierCap),
  ];

  /// Der Multiplikator, der zu einer Streak von [streak] Tagen gehört.
  static double multiplierFor(int streak) {
    var value = 1.0;
    for (final milestone in streakMilestones) {
      if (streak >= milestone.days) value = milestone.multiplier;
    }
    return value > multiplierCap ? multiplierCap : value;
  }

  /// Der nächste Meilenstein nach einer Streak von [streak] Tagen.
  /// Null, wenn der Deckel erreicht ist.
  static StreakMilestone? nextMilestoneAfter(int streak) {
    for (final milestone in streakMilestones) {
      if (streak < milestone.days) return milestone;
    }
    return null;
  }

  /// Erfahrung für ein Häkchen, das eine Streak von [streak] Tagen
  /// abschließt. [streak] zählt dieses Häkchen mit: Der erste Tag ist 1.
  static int xpFor(int streak) {
    if (streak <= 0) return 0;
    return (xpPerCheck * multiplierFor(streak)).round();
  }

  /// Gold für ein Häkchen. Der Streak spielt hier bewusst keine Rolle.
  static int goldFor(int streak) => streak <= 0 ? 0 : goldPerCheck;
}

/// Wie aus abgehakten Gewohnheiten Kampfwerte werden.
///
/// Die Zahlen sind eng gesteckt, und das mit Absicht: Die
/// Balance-Simulation zeigt, dass zwei Angriffspunkte über Sieg oder
/// Niederlage entscheiden (`docs/context/state.md`). Solange diese Frage
/// offen ist, darf die Stat-Kurve keine Sprünge machen. Deshalb wachsen
/// alle vier Werte, nicht nur der Angriff — vier kleine Zugewinne tragen
/// weiter als ein großer.
abstract final class StatCurve {
  /// Angriff: 13 bis 20. Der Gegner steht bei 18.
  static const StatRule _staerke = StatRule(
    base: 13,
    checksPerPoint: 5,
    pointStep: 1,
    maxBonus: 7,
  );

  /// Lebenspunkte: 160 bis 224.
  ///
  /// Der Pool ist gegenüber dem ersten Entwurf (100 bis 140) um zwei
  /// Drittel gewachsen, damit ein Kampf statt fünf Runden gut zehn dauert.
  /// Nicht wegen der Multiplikatoren — die wirken über jede Länge gleich —
  /// sondern damit im Kampf überhaupt Entscheidungen vorkommen: Bei fünf
  /// Runden reicht die Energie für genau einen Wuchtschlag, der vierte
  /// Slot kommt nie zum Einsatz (ADR-0009).
  static const StatRule _ausdauer = StatRule(
    base: 160,
    checksPerPoint: 4,
    pointStep: 8,
    maxBonus: 64,
  );

  /// Verteidigung: 8 bis 14.
  static const StatRule _disziplin = StatRule(
    base: 8,
    checksPerPoint: 6,
    pointStep: 1,
    maxBonus: 6,
  );

  /// Energie: 8 bis 12. Unter 8 wäre der Wuchtschlag (Kosten 6)
  /// unbezahlbar, der Kampf verlöre einen seiner vier Slots.
  static const StatRule _klarheit = StatRule(
    base: 8,
    checksPerPoint: 10,
    pointStep: 1,
    maxBonus: 4,
  );

  static StatRule ruleFor(HabitStat stat) {
    return switch (stat) {
      HabitStat.staerke => _staerke,
      HabitStat.ausdauer => _ausdauer,
      HabitStat.disziplin => _disziplin,
      HabitStat.klarheit => _klarheit,
    };
  }

  /// Der Zugewinn, den [checks] Häkchen auf [stat] bringen.
  static int bonusFor(HabitStat stat, int checks) {
    if (checks <= 0) return 0;
    final rule = ruleFor(stat);
    final bonus = checks ~/ rule.checksPerPoint * rule.pointStep;
    return bonus > rule.maxBonus ? rule.maxBonus : bonus;
  }

  /// Wie viele Häkchen noch bis zum nächsten Punkt fehlen.
  /// 0, wenn der Deckel erreicht ist.
  static int checksToNextPoint(HabitStat stat, int checks) {
    final rule = ruleFor(stat);
    if (bonusFor(stat, checks) >= rule.maxBonus) return 0;
    final done = checks < 0 ? 0 : checks;
    return rule.checksPerPoint - done % rule.checksPerPoint;
  }
}

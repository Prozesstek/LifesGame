/// Die Kurve der **Skills** (ADR-0085) — je Gebiet ein Level, das nur
/// wächst.
///
/// **Warum eine zweite Kurve neben [LevelCurve].** Das Charakter-Level
/// endet bei 50, und mit fünf Gewohnheiten ist man dort nach gut einem
/// halben Jahr. Ein Skill misst dagegen, wie lange man in **einem** Gebiet
/// dabei ist, und soll noch nach Jahren steigen. Er hat deshalb einen
/// kleineren Schritt und ein höheres Ende.
///
/// Gemessen mit einer Gewohnheit täglich, samt Kettenbonus und ohne eine
/// Seite: Skill 10 nach 50 Tagen, 25 nach gut fünf Monaten (159), 50
/// nach gut einem Jahr (425), 100 nach dreieinhalb Jahren (1307). Mit
/// Seiten und mehreren Gewohnheiten im Gebiet geht es schneller.
/// `test/skills_test.dart` hält die Spanne fest.
///
/// Gleiche Regel wie bei [LevelCurve]: Steht eine dieser Zahlen irgendwo
/// anders im Code, ist das ein Bug.
abstract final class SkillCurve {
  /// Erfahrung von Skill 1 auf 2 — so viel wie beim Charakter-Level.
  static const int baseXp = 100;

  /// Um wie viel jede weitere Stufe teurer wird als die vorige.
  ///
  /// Ein Drittel des Schritts beim Level (25): Ein Skill sammelt nur, was
  /// in einem Gebiet geschieht, und muss trotzdem jedes Jahr spürbar
  /// weitergehen.
  static const int stepXp = 8;

  static const int minLevel = 1;
  static const int maxLevel = 100;

  /// Gesamte Erfahrung, die nötig ist, um [level] zu erreichen.
  static int totalXpFor(int level) {
    if (level <= minLevel) return 0;
    final steps = (level > maxLevel ? maxLevel : level) - 1;
    return baseXp * steps + stepXp * steps * (steps - 1) ~/ 2;
  }

  /// Der Stand, der zu [totalXp] gehört.
  static SkillLevel levelFor(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;

    var level = minLevel;
    while (level < maxLevel && totalXpFor(level + 1) <= xp) {
      level++;
    }

    final start = totalXpFor(level);
    final step = level >= maxLevel ? 0 : totalXpFor(level + 1) - start;
    return SkillLevel(
      level: level,
      totalXp: xp,
      xpIntoLevel: xp - start,
      xpForLevel: step,
    );
  }

  /// **Das Gesamtlevel**: die Summe aller Skills. Die Zahl, mit der man
  /// sich am einfachsten vergleicht — vier Skills auf 1 sind 4.
  static int totalLevelOf(Iterable<SkillLevel> skills) {
    return skills.fold(0, (sum, skill) => sum + skill.level);
  }
}

/// Wo ein Skill gerade steht.
class SkillLevel {
  const SkillLevel({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForLevel,
  });

  const SkillLevel.start()
      : level = SkillCurve.minLevel,
        totalXp = 0,
        xpIntoLevel = 0,
        xpForLevel = SkillCurve.baseXp;

  final int level;
  final int totalXp;

  /// Erfahrung innerhalb der aktuellen Stufe.
  final int xpIntoLevel;

  /// Erfahrung, die diese Stufe insgesamt kostet. 0 auf der Höchststufe.
  final int xpForLevel;

  bool get isMaxLevel => level >= SkillCurve.maxLevel;

  int get xpToNextLevel => isMaxLevel ? 0 : xpForLevel - xpIntoLevel;

  /// Fortschritt innerhalb der Stufe, 0..1.
  double get ratio {
    if (isMaxLevel || xpForLevel <= 0) return 1;
    return xpIntoLevel / xpForLevel;
  }
}

/// Die Levelkurve an einem Ort.
///
/// Gleiche Regel wie bei `balance.dart` und `rewards.dart`: Steht eine dieser
/// Zahlen irgendwo anders im Code, ist das ein Bug.
abstract final class LevelCurve {
  /// Erfahrung von Level 1 auf 2.
  static const int baseXp = 100;

  /// Um wie viel jede weitere Stufe teurer wird als die vorige.
  ///
  /// Linear steigend, nicht exponentiell: Der Fortschritt kommt laut Konzept
  /// aus echten Gewohnheiten und lässt sich nicht durch Grinden beschleunigen.
  /// Eine exponentielle Kurve würde die späteren Stufen unerreichbar machen.
  static const int stepXp = 25;

  static const int minLevel = 1;
  static const int maxLevel = 50;

  /// Gesamte Erfahrung, die nötig ist, um [level] zu erreichen.
  static int totalXpFor(int level) {
    if (level <= minLevel) return 0;
    final steps = level - 1;
    return baseXp * steps + stepXp * steps * (steps - 1) ~/ 2;
  }

  /// Erfahrung, die allein die Stufe [level] → [level] + 1 kostet.
  static int xpForStep(int level) {
    if (level >= maxLevel) return 0;
    return totalXpFor(level + 1) - totalXpFor(level);
  }

  /// Der Stand, der zu [totalXp] gehört.
  static PlayerLevel levelFor(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;

    var level = minLevel;
    while (level < maxLevel && totalXpFor(level + 1) <= xp) {
      level++;
    }

    return PlayerLevel(
      level: level,
      totalXp: xp,
      xpIntoLevel: xp - totalXpFor(level),
      xpForLevel: xpForStep(level),
    );
  }
}

/// Wo der Charakter gerade steht.
class PlayerLevel {
  const PlayerLevel({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForLevel,
  });

  final int level;
  final int totalXp;

  /// Erfahrung innerhalb der aktuellen Stufe.
  final int xpIntoLevel;

  /// Erfahrung, die diese Stufe insgesamt kostet. 0 auf Maximalstufe.
  final int xpForLevel;

  bool get isMaxLevel => level >= LevelCurve.maxLevel;

  int get xpToNextLevel => isMaxLevel ? 0 : xpForLevel - xpIntoLevel;

  /// Fortschritt innerhalb der Stufe, 0..1.
  double get ratio {
    if (isMaxLevel || xpForLevel <= 0) return 1;
    return xpIntoLevel / xpForLevel;
  }
}

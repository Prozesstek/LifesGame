import 'lesson.dart';

/// Ein Theoriezweig: eine geordnete Folge von Lektionen zu einem Thema.
///
/// Zwei Sperren liegen übereinander. Der Zweig als Ganzes öffnet sich mit dem
/// Charakterlevel ([unlockLevel]), innerhalb des Zweigs ist die Reihenfolge
/// verbindlich — Lektion n+1 erst nach bestandener n
/// (`TheoryProgress.isUnlocked`).
class TheoryBranch {
  const TheoryBranch({
    required this.id,
    required this.name,
    required this.description,
    required this.lessons,
    this.unlockLevel = 1,
  });

  final String id;
  final String name;
  final String description;
  final List<Lesson> lessons;

  /// Ab welchem Charakterlevel der Zweig offen ist.
  ///
  /// 1 heißt: von Anfang an. Siehe ADR-0007.
  final int unlockLevel;

  bool get isFreeFromStart => unlockLevel <= 1;

  bool isUnlockedAt(int playerLevel) => playerLevel >= unlockLevel;

  int get lessonCount => lessons.length;

  /// Position der Lektion im Zweig, oder -1 wenn sie nicht dazugehört.
  int indexOf(String lessonId) {
    for (var i = 0; i < lessons.length; i++) {
      if (lessons[i].id == lessonId) return i;
    }
    return -1;
  }

  Lesson? lessonById(String lessonId) {
    final index = indexOf(lessonId);
    return index < 0 ? null : lessons[index];
  }
}

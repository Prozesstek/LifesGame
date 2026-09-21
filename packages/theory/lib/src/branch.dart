import 'lesson.dart';

/// Ein Theoriezweig: eine geordnete Folge von Lektionen zu einem Thema.
///
/// Innerhalb des Zweigs ist die Reihenfolge verbindlich — Lektion n+1 erst
/// nach bestandener n (`TheoryProgress.isUnlocked`).
///
/// Eine Levelsperre für den Zweig als Ganzes gab es bis ADR-0019. Seitdem
/// öffnet der Graph über Theoriepunkte, und die flachen Zweige tragen nur
/// noch das Handbuch und die Lektionen, auf die der Graph zeigt.
class TheoryBranch {
  const TheoryBranch({
    required this.id,
    required this.name,
    required this.description,
    required this.lessons,
  });

  final String id;
  final String name;
  final String description;
  final List<Lesson> lessons;

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

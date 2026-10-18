/// Ein Abschnitt Lesetext innerhalb einer Lektion.
class LessonSection {
  const LessonSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

/// Eine Multiple-Choice-Frage mit genau einer richtigen Antwort.
///
/// Die Erklärung wird nach der Antwort gezeigt — auch bei einer richtigen
/// Antwort. Sie ist Teil des Inhalts, nicht nur Fehlerkorrektur.
class Question {
  const Question({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  bool isCorrect(int? answer) => answer == correctIndex;
}

/// Eine Lektion: Text lesen, danach Fragen beantworten.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.sections,
    required this.questions,
    this.unlocksHabit,
    this.teaser,
  });

  final String id;
  final String title;

  /// Ein Satz für die Übersicht — was diese Lektion beantwortet.
  final String summary;

  final List<LessonSection> sections;
  final List<Question> questions;

  /// Name der Habit-Vorlage, die mit dieser Lektion freigeschaltet wird.
  ///
  /// Null, wenn die Lektion keine Vorlage mitbringt. Der Tracker-Teil liest
  /// dieses Feld später aus; das Konzept verlangt, dass Theorie und Habits
  /// verknüpft sind und nicht nebeneinanderstehen.
  final String? unlocksHabit;

  /// **Das Rätsel vor der Seite** (18.10.): eine Schätzfrage, die vor dem
  /// Lesen gestellt und **nicht gewertet** wird. Wer geraten hat, liest
  /// nach einer Antwort statt vor sich hin — und behält mehr, auch wenn
  /// er falsch lag. Die Auflösung steht in [Question.explanation], das
  /// Warum im Text darunter.
  ///
  /// Null, solange die Seite keins hat; bisher hat es nur Kraft &
  /// Muskulatur, als Probe. Es zählt nicht zu [questions] und kommt nie
  /// in der Rückfrage des Tages.
  final Question? teaser;

  int get questionCount => questions.length;
}

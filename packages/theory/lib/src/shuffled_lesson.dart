import 'dart:math';

import 'lesson.dart';

/// Eine Frage, wie sie **angezeigt** wird — Antworten gemischt.
///
/// [optionOrder] ist die Rückübersetzung: An Stelle *i* der Anzeige steht
/// die Antwort `optionOrder[i]` der Lektion. Ohne sie wäre eine gemischte
/// Frage nicht mehr auswertbar.
class ShuffledQuestion {
  const ShuffledQuestion({
    required this.question,
    required this.lessonIndex,
    required this.optionOrder,
  });

  /// Die gemischte Fassung. Ihr `correctIndex` zeigt auf dieselbe
  /// Antwort wie vorher, nur an ihrer neuen Stelle.
  final Question question;

  /// Der Platz dieser Frage in `lesson.questions`.
  final int lessonIndex;

  /// Anzeige-Stelle → Stelle in der Lektion.
  final List<int> optionOrder;
}

/// Eine Lektion in zufälliger Reihenfolge (ADR-0027, Issue #21 Punkt 3).
///
/// **Warum das nicht im Bildschirm steht:** Gemischt wird mit einer
/// Rückübersetzung, und die ist Indexrechnung. Sobald in `lib/` gerechnet
/// wird, gehört die Rechnung in ein Package — hier zusätzlich deshalb,
/// weil sie ohne Flutter prüfbar sein muss.
///
/// **Der Inhalt bleibt unangetastet.** Die Reihenfolge im Katalog ist
/// nur noch Speicherform; sie sagt nichts mehr darüber aus, was der
/// Spieler sieht. Deshalb prüft `question_fairness_test.dart` die
/// gespeicherte Verteilung trotzdem weiter — als Absicherung für den
/// Fall, dass irgendwo ungemischt angezeigt wird.
class ShuffledLesson {
  const ShuffledLesson._(this.lesson, this.questions);

  /// Mischt Fragen **und** Antworten.
  factory ShuffledLesson.of(Lesson lesson, Random random) {
    final fragen = <ShuffledQuestion>[];

    for (var i = 0; i < lesson.questions.length; i++) {
      final frage = lesson.questions[i];
      final reihenfolge = List<int>.generate(frage.options.length, (k) => k)
        ..shuffle(random);

      fragen.add(
        ShuffledQuestion(
          question: Question(
            prompt: frage.prompt,
            options: <String>[
              for (final k in reihenfolge) frage.options[k],
            ],
            correctIndex: reihenfolge.indexOf(frage.correctIndex),
            explanation: frage.explanation,
          ),
          lessonIndex: i,
          optionOrder: reihenfolge,
        ),
      );
    }

    fragen.shuffle(random);
    final fest = List<ShuffledQuestion>.unmodifiable(fragen);

    return ShuffledLesson._(lesson, fest);
  }

  final Lesson lesson;

  /// Die Fragen in Anzeigereihenfolge.
  final List<ShuffledQuestion> questions;

  int get questionCount => questions.length;

  /// Übersetzt die Antworten der Anzeige zurück in die Reihenfolge der
  /// Lektion — nur so lässt sich `TheoryProgress.submit` damit füttern.
  ///
  /// Nicht beantwortete Fragen bleiben null.
  List<int?> toLessonAnswers(List<int?> shown) {
    final zurueck = List<int?>.filled(lesson.questions.length, null);

    for (var i = 0; i < questions.length && i < shown.length; i++) {
      final gewaehlt = shown[i];
      if (gewaehlt == null) continue;

      final frage = questions[i];
      zurueck[frage.lessonIndex] = frage.optionOrder[gewaehlt];
    }

    return zurueck;
  }
}

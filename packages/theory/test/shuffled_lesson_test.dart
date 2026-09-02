import 'dart:math';

import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Prüft das Mischen aus ADR-0027.
///
/// Der gefährliche Fehler hier ist still: Wer die Antworten mischt und
/// die Rückübersetzung vergisst, wertet richtige Antworten als falsch —
/// und niemand merkt es, weil beides plausibel aussieht.
void main() {
  const lektion = Lesson(
    id: 'test-lektion',
    title: 'Test',
    summary: 'Nur für den Test.',
    sections: <LessonSection>[
      LessonSection(heading: 'A', body: 'Ein Abschnitt für den Test.'),
    ],
    questions: <Question>[
      Question(
        prompt: 'Frage eins?',
        options: <String>['1a', '1b', '1c'],
        correctIndex: 0,
        explanation: 'weil',
      ),
      Question(
        prompt: 'Frage zwei?',
        options: <String>['2a', '2b', '2c'],
        correctIndex: 1,
        explanation: 'weil',
      ),
      Question(
        prompt: 'Frage drei?',
        options: <String>['3a', '3b', '3c'],
        correctIndex: 2,
        explanation: 'weil',
      ),
    ],
  );

  group('Gemischt wird, aber nichts geht verloren', () {
    test('alle Fragen kommen genau einmal vor', () {
      final gemischt = ShuffledLesson.of(lektion, Random(7));

      final prompts = gemischt.questions.map((q) => q.question.prompt).toSet();

      expect(gemischt.questionCount, 3);
      expect(prompts, {'Frage eins?', 'Frage zwei?', 'Frage drei?'});
    });

    test('alle Antworten einer Frage kommen genau einmal vor', () {
      final gemischt = ShuffledLesson.of(lektion, Random(7));

      for (final frage in gemischt.questions) {
        final original = lektion.questions[frage.lessonIndex];

        expect(frage.question.options.toSet(), original.options.toSet());
      }
    });

    test('correctIndex zeigt weiter auf denselben Antworttext', () {
      final gemischt = ShuffledLesson.of(lektion, Random(3));

      for (final frage in gemischt.questions) {
        final original = lektion.questions[frage.lessonIndex];

        expect(
          frage.question.options[frage.question.correctIndex],
          original.options[original.correctIndex],
        );
      }
    });
  });

  group('Rückübersetzung', () {
    test('wer in der Anzeige richtig tippt, hat in der Lektion recht', () {
      // Über viele Seeds, damit nicht zufällig genau die eine
      // Reihenfolge getroffen wird, in der auch ein Fehler durchgeht.
      for (var seed = 0; seed < 50; seed++) {
        final gemischt = ShuffledLesson.of(lektion, Random(seed));
        final getippt = <int?>[
          for (final frage in gemischt.questions) frage.question.correctIndex,
        ];

        final inLektion = gemischt.toLessonAnswers(getippt);

        for (var i = 0; i < lektion.questions.length; i++) {
          expect(
            lektion.questions[i].isCorrect(inLektion[i]),
            isTrue,
            reason: 'Seed $seed, Frage $i',
          );
        }
      }
    });

    test('wer daneben tippt, liegt auch in der Lektion daneben', () {
      final gemischt = ShuffledLesson.of(lektion, Random(11));
      final getippt = <int?>[
        for (final frage in gemischt.questions)
          (frage.question.correctIndex + 1) % frage.question.options.length,
      ];

      final inLektion = gemischt.toLessonAnswers(getippt);

      for (var i = 0; i < lektion.questions.length; i++) {
        expect(lektion.questions[i].isCorrect(inLektion[i]), isFalse);
      }
    });

    test('unbeantwortete Fragen bleiben unbeantwortet', () {
      final gemischt = ShuffledLesson.of(lektion, Random(5));

      final inLektion = gemischt.toLessonAnswers(<int?>[null, null, null]);

      expect(inLektion, <int?>[null, null, null]);
    });
  });

  test('verschiedene Seeds ergeben verschiedene Reihenfolgen', () {
    // Ein Mischen, das immer dasselbe liefert, wäre kein Mischen — und
    // genau das fiele im Spiel niemandem auf.
    final reihenfolgen = <String>{
      for (var seed = 0; seed < 20; seed++)
        ShuffledLesson.of(lektion, Random(seed))
            .questions
            .map((q) => '${q.lessonIndex}${q.optionOrder.join()}')
            .join('|'),
    };

    expect(reihenfolgen.length, greaterThan(1));
  });
}

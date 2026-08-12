import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Eine kleine Lektion mit drei Fragen, damit die Erwartungen im Test
/// nachrechenbar bleiben.
const Lesson _lesson = Lesson(
  id: 'test-01',
  title: 'Testlektion',
  summary: 'Nur für Tests.',
  sections: <LessonSection>[
    LessonSection(heading: 'A', body: 'Text.'),
  ],
  questions: <Question>[
    Question(
      prompt: 'Frage 1',
      options: <String>['falsch', 'richtig'],
      correctIndex: 1,
      explanation: 'weil',
    ),
    Question(
      prompt: 'Frage 2',
      options: <String>['richtig', 'falsch'],
      correctIndex: 0,
      explanation: 'weil',
    ),
    Question(
      prompt: 'Frage 3',
      options: <String>['falsch', 'richtig'],
      correctIndex: 1,
      explanation: 'weil',
    ),
  ],
);

const TheoryBranch _branch = TheoryBranch(
  id: 'test',
  name: 'Test',
  description: 'Zweig für Tests.',
  lessons: <Lesson>[_lesson, _second],
);

const Lesson _second = Lesson(
  id: 'test-02',
  title: 'Zweite',
  summary: 'Folgt auf die erste.',
  sections: <LessonSection>[LessonSection(heading: 'A', body: 'Text.')],
  questions: <Question>[
    Question(
      prompt: 'Frage',
      options: <String>['a', 'b'],
      correctIndex: 0,
      explanation: 'weil',
    ),
  ],
);

void main() {
  group('Bestehensgrenze', () {
    test('zwei von drei richtig reicht', () {
      expect(TheoryRewards.passes(2, 3), isTrue);
    });

    test('eine von drei richtig reicht nicht', () {
      expect(TheoryRewards.passes(1, 3), isFalse);
    });

    test('null Fragen gelten nie als bestanden', () {
      expect(TheoryRewards.passes(0, 0), isFalse);
    });
  });

  group('Auswertung eines Versuchs', () {
    test('alles richtig gibt XP plus Perfekt-Bonus und Gold', () {
      const progress = TheoryProgress.empty();

      final result = progress.submit(_lesson, <int?>[1, 0, 1]);

      expect(result.correct, 3);
      expect(result.isPerfect, isTrue);
      expect(
        result.xpGained,
        TheoryRewards.xpForPass + TheoryRewards.xpPerfectBonus,
      );
      expect(result.goldGained, TheoryRewards.goldForPass);
    });

    test('knapp bestanden gibt XP ohne Bonus', () {
      const progress = TheoryProgress.empty();

      final result = progress.submit(_lesson, <int?>[1, 1, 1]);

      expect(result.correct, 2);
      expect(result.isPassed, isTrue);
      expect(result.xpGained, TheoryRewards.xpForPass);
    });

    test('durchgefallen gibt nichts', () {
      const progress = TheoryProgress.empty();

      final result = progress.submit(_lesson, <int?>[0, 1, 0]);

      expect(result.correct, 0);
      expect(result.isPassed, isFalse);
      expect(result.xpGained, 0);
      expect(result.goldGained, 0);
      expect(result.progress.isPassed(_lesson.id), isFalse);
    });

    test('unbeantwortete Fragen zählen als falsch', () {
      const progress = TheoryProgress.empty();

      final result = progress.submit(_lesson, <int?>[1, null, null]);

      expect(result.correct, 1);
      expect(result.isPassed, isFalse);
    });

    test('kürzere Antwortliste wirft nicht', () {
      const progress = TheoryProgress.empty();

      final result = progress.submit(_lesson, <int?>[1]);

      expect(result.correct, 1);
      expect(result.total, 3);
    });
  });

  group('Wiederholung', () {
    test('dieselbe Lektion zweimal bestehen zahlt nicht doppelt', () {
      const progress = TheoryProgress.empty();

      final first = progress.submit(_lesson, <int?>[1, 0, 1]);
      final second = first.progress.submit(_lesson, <int?>[1, 0, 1]);

      expect(second.xpGained, 0);
      expect(second.goldGained, 0);
      expect(second.progress.totalXp, first.progress.totalXp);
    });

    test('Verbesserung zahlt nur die Differenz', () {
      const progress = TheoryProgress.empty();

      final first = progress.submit(_lesson, <int?>[1, 1, 1]);
      final second = first.progress.submit(_lesson, <int?>[1, 0, 1]);

      expect(first.xpGained, TheoryRewards.xpForPass);
      expect(second.xpGained, TheoryRewards.xpPerfectBonus);
      expect(
        second.progress.totalXp,
        TheoryRewards.xpForPass + TheoryRewards.xpPerfectBonus,
      );
    });

    test('schlechterer Versuch nimmt nichts weg', () {
      const progress = TheoryProgress.empty();

      final first = progress.submit(_lesson, <int?>[1, 0, 1]);
      final second = first.progress.submit(_lesson, <int?>[0, 1, 0]);

      expect(second.xpGained, 0);
      expect(second.progress.isPassed(_lesson.id), isTrue);
      expect(second.progress.recordFor(_lesson.id)?.bestCorrect, 3);
      expect(second.isNewBest, isFalse);
    });
  });

  group('Freischaltung im Zweig', () {
    test('die erste Lektion ist immer offen', () {
      const progress = TheoryProgress.empty();

      expect(progress.isUnlocked(_branch, _lesson.id), isTrue);
      expect(progress.isUnlocked(_branch, _second.id), isFalse);
    });

    test('die zweite öffnet sich nach bestandener erster', () {
      const progress = TheoryProgress.empty();

      final after = progress.submit(_lesson, <int?>[1, 0, 1]).progress;

      expect(after.isUnlocked(_branch, _second.id), isTrue);
    });

    test('durchgefallen schaltet nicht frei', () {
      const progress = TheoryProgress.empty();

      final after = progress.submit(_lesson, <int?>[0, 1, 0]).progress;

      expect(after.isUnlocked(_branch, _second.id), isFalse);
    });

    test('fremde Lektions-Id ist nicht freigeschaltet', () {
      const progress = TheoryProgress.empty();

      expect(progress.isUnlocked(_branch, 'gibt-es-nicht'), isFalse);
    });

    test('nextLesson zeigt auf die erste offene Lektion', () {
      const progress = TheoryProgress.empty();
      expect(progress.nextLesson(_branch)?.id, _lesson.id);

      final after = progress.submit(_lesson, <int?>[1, 0, 1]).progress;
      expect(after.nextLesson(_branch)?.id, _second.id);

      final done = after.submit(_second, <int?>[0]).progress;
      expect(done.nextLesson(_branch), isNull);
      expect(done.passedCount(_branch), 2);
    });
  });

  group('Fortschritt bleibt unveränderlich', () {
    test('submit verändert den alten Fortschritt nicht', () {
      const progress = TheoryProgress.empty();

      progress.submit(_lesson, <int?>[1, 0, 1]);

      expect(progress.totalXp, 0);
      expect(progress.isPassed(_lesson.id), isFalse);
    });
  });
}

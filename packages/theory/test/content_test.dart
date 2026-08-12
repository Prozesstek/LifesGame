import 'package:test/test.dart';
import 'package:theory/theory.dart';

/// Diese Tests prüfen keinen Code, sondern den Inhalt.
///
/// Beim Schreiben von Lektionen sind Zahlendreher im `correctIndex` und
/// doppelte Ids die wahrscheinlichsten Fehler — und beide fallen beim
/// Durchklicken kaum auf. Der Test läuft über den **ganzen Baum**, damit
/// ein neuer Zweig automatisch mitgeprüft wird.
void main() {
  group('Aufbau des Baums', () {
    test('enthält die fünf geplanten Zweige', () {
      expect(
        theoryTree.branches.map((b) => b.id),
        containsAll(<String>[
          'habits',
          'koerper',
          'geist',
          'wissenschaft',
          'gesellschaft',
        ]),
      );
    });

    test('alle Zweig-Ids und -Namen sind eindeutig', () {
      final ids = theoryTree.branches.map((b) => b.id).toList();
      final names = theoryTree.branches.map((b) => b.name).toList();

      expect(ids.toSet().length, ids.length);
      expect(names.toSet().length, names.length);
    });

    test('genau ein Zweig ist von Anfang an offen', () {
      final free = theoryTree.branches.where((b) => b.isFreeFromStart);

      expect(free.length, 1);
      expect(free.first.id, 'habits');
    });

    test('jeder gesperrte Zweig öffnet sich auf einer eigenen Stufe', () {
      final levels = theoryTree.branches
          .where((b) => !b.isFreeFromStart)
          .map((b) => b.unlockLevel)
          .toList();

      expect(levels.toSet().length, levels.length);
      for (final level in levels) {
        expect(level, greaterThan(1));
      }
    });

    test('alle Lektions-Ids im Baum sind eindeutig', () {
      final ids = <String>[
        for (final branch in theoryTree.branches)
          for (final lesson in branch.lessons) lesson.id,
      ];

      expect(ids.toSet().length, ids.length);
      expect(ids.length, theoryTree.lessonCount);
    });

    test('keine Habit-Vorlage kommt zweimal vor', () {
      final habits = <String>[
        for (final branch in theoryTree.branches)
          for (final lesson in branch.lessons)
            if (lesson.unlocksHabit case final String habit) habit,
      ];

      expect(habits, isNotEmpty);
      expect(habits.toSet().length, habits.length);
    });
  });

  group('Inhalt jeder Lektion', () {
    test('jeder Zweig hat Beschreibung und Lektionen', () {
      for (final branch in theoryTree.branches) {
        expect(branch.name.trim(), isNotEmpty, reason: branch.id);
        expect(
          branch.description.trim().length,
          greaterThan(40),
          reason: branch.id,
        );
        expect(branch.lessons, isNotEmpty, reason: branch.id);
      }
    });

    test('jede Lektion hat Titel, Zusammenfassung, Text und Fragen', () {
      for (final lesson in _allLessons) {
        expect(lesson.title.trim(), isNotEmpty, reason: lesson.id);
        expect(lesson.summary.trim(), isNotEmpty, reason: lesson.id);
        expect(lesson.sections, isNotEmpty, reason: lesson.id);
        expect(lesson.questions, isNotEmpty, reason: lesson.id);
      }
    });

    test('jeder Abschnitt hat Überschrift und Fließtext', () {
      for (final lesson in _allLessons) {
        for (final section in lesson.sections) {
          expect(section.heading.trim(), isNotEmpty, reason: lesson.id);
          expect(
            section.body.trim().length,
            greaterThan(40),
            reason: '${lesson.id}: ${section.heading}',
          );
        }
      }
    });

    test('jede Frage hat mindestens zwei Antworten', () {
      for (final lesson in _allLessons) {
        for (final question in lesson.questions) {
          expect(
            question.options.length,
            greaterThanOrEqualTo(2),
            reason: '${lesson.id}: ${question.prompt}',
          );
        }
      }
    });

    test('jeder correctIndex zeigt auf eine vorhandene Antwort', () {
      for (final lesson in _allLessons) {
        for (final question in lesson.questions) {
          expect(
            question.correctIndex,
            greaterThanOrEqualTo(0),
            reason: '${lesson.id}: ${question.prompt}',
          );
          expect(
            question.correctIndex,
            lessThan(question.options.length),
            reason: '${lesson.id}: ${question.prompt}',
          );
        }
      }
    });

    test('keine Antwortmöglichkeit steht doppelt', () {
      for (final lesson in _allLessons) {
        for (final question in lesson.questions) {
          expect(
            question.options.toSet().length,
            question.options.length,
            reason: '${lesson.id}: ${question.prompt}',
          );
        }
      }
    });

    test('jede Frage hat Aufgabentext und Erklärung', () {
      for (final lesson in _allLessons) {
        for (final question in lesson.questions) {
          expect(question.prompt.trim(), isNotEmpty, reason: lesson.id);
          expect(question.explanation.trim(), isNotEmpty, reason: lesson.id);
        }
      }
    });

    test('die richtige Antwort steht in jedem Zweig nicht immer gleich', () {
      for (final branch in theoryTree.branches) {
        final positions = <int>{};
        for (final lesson in branch.lessons) {
          for (final question in lesson.questions) {
            positions.add(question.correctIndex);
          }
        }
        expect(positions.length, greaterThan(1), reason: branch.id);
      }
    });
  });

  group('Durchlauf', () {
    test('jeder Zweig lässt sich von vorn bis hinten durchspielen', () {
      for (final branch in theoryTree.branches) {
        var progress = const TheoryProgress.empty();

        for (final lesson in branch.lessons) {
          expect(
            progress.isUnlocked(branch, lesson.id),
            isTrue,
            reason: '${branch.id}/${lesson.id}',
          );
          final answers = lesson.questions.map((q) => q.correctIndex).toList();
          progress = progress.submit(lesson, answers).progress;
        }

        expect(progress.isBranchComplete(branch), isTrue, reason: branch.id);
        expect(progress.nextLesson(branch), isNull, reason: branch.id);
      }
    });

    test('der ganze Baum bringt genug Erfahrung für alle Sperren', () {
      var progress = const TheoryProgress.empty();
      for (final lesson in _allLessons) {
        final answers = lesson.questions.map((q) => q.correctIndex).toList();
        progress = progress.submit(lesson, answers).progress;
      }

      expect(progress.passedCountIn(theoryTree), theoryTree.lessonCount);
      expect(
        progress.totalXp,
        theoryTree.lessonCount *
            (TheoryRewards.xpForPass + TheoryRewards.xpPerfectBonus),
      );
    });
  });
}

Iterable<Lesson> get _allLessons sync* {
  for (final branch in theoryTree.branches) {
    yield* branch.lessons;
  }
}

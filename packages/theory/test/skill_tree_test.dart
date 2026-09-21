import 'package:test/test.dart';
import 'package:theory/theory.dart';

void main() {
  group('Nachschlagen', () {
    test('Zweig über die Id finden', () {
      expect(theoryTree.branchById('geist')?.name, 'Geist');
      expect(theoryTree.branchById('gibt-es-nicht'), isNull);
    });

    test('Lektion über die Id finden, quer über alle Zweige', () {
      final lesson = theoryTree.lessonById('koerper-01-schlaf');

      expect(lesson, isNotNull);
      expect(lesson?.unlocksHabit, isNotNull);
      expect(theoryTree.lessonById('gibt-es-nicht'), isNull);
    });

    test('jede Lektion kennt ihren Zweig', () {
      for (final branch in theoryTree.branches) {
        for (final lesson in branch.lessons) {
          expect(
            theoryTree.branchOfLesson(lesson.id)?.id,
            branch.id,
            reason: lesson.id,
          );
        }
      }
      expect(theoryTree.branchOfLesson('gibt-es-nicht'), isNull);
    });

    test('die Lektionszahl stimmt mit der Summe der Zweige überein', () {
      final sum = theoryTree.branches.fold(
        0,
        (total, branch) => total + branch.lessonCount,
      );

      expect(theoryTree.lessonCount, sum);
      expect(theoryTree.lessonCount, greaterThan(10));
    });
  });

  group('Fortschritt über den Baum', () {
    test('ein bestandener Zweig zählt nicht in einen anderen hinein', () {
      var progress = const TheoryProgress.empty();
      for (final lesson in koerperBranch.lessons) {
        final answers = lesson.questions.map((q) => q.correctIndex).toList();
        progress = progress.submit(lesson, answers).progress;
      }

      expect(progress.isBranchComplete(koerperBranch), isTrue);
      expect(progress.isBranchComplete(geistBranch), isFalse);
      expect(progress.passedCount(habitsBranch), 0);
      expect(progress.passedCountIn(theoryTree), koerperBranch.lessonCount);
    });
  });
}

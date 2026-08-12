import 'package:test/test.dart';
import 'package:theory/theory.dart';

void main() {
  group('Levelsperre', () {
    test('auf Level 1 ist nur der Wurzelzweig offen', () {
      final open = theoryTree.unlockedAt(1);

      expect(open.length, 1);
      expect(open.first.id, habitsBranch.id);
      expect(theoryTree.lockedAt(1).length, theoryTree.branchCount - 1);
    });

    test('jeder Zweig öffnet sich genau auf seiner Stufe', () {
      for (final branch in theoryTree.branches) {
        expect(
          branch.isUnlockedAt(branch.unlockLevel),
          isTrue,
          reason: branch.id,
        );
        if (!branch.isFreeFromStart) {
          expect(
            branch.isUnlockedAt(branch.unlockLevel - 1),
            isFalse,
            reason: branch.id,
          );
        }
      }
    });

    test('höheres Level öffnet nie weniger als ein niedrigeres', () {
      for (var level = 1; level < 10; level++) {
        expect(
          theoryTree.unlockedAt(level + 1).length,
          greaterThanOrEqualTo(theoryTree.unlockedAt(level).length),
          reason: 'Level $level',
        );
      }
    });

    test('ab der höchsten Sperre ist alles offen', () {
      final highest = theoryTree.branches
          .map((b) => b.unlockLevel)
          .reduce((a, b) => a > b ? a : b);

      expect(theoryTree.unlockedAt(highest).length, theoryTree.branchCount);
      expect(theoryTree.lockedAt(highest), isEmpty);
    });

    test('nextUnlock zeigt auf den nächstniedrigeren gesperrten Zweig', () {
      expect(theoryTree.nextUnlock(1)?.id, koerperBranch.id);
      expect(theoryTree.nextUnlock(2)?.id, geistBranch.id);
      expect(theoryTree.nextUnlock(3)?.id, wissenschaftBranch.id);
      expect(theoryTree.nextUnlock(4)?.id, gesellschaftBranch.id);
      expect(theoryTree.nextUnlock(99), isNull);
    });
  });

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

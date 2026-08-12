import 'branch.dart';
import 'content/geist_branch.dart';
import 'content/gesellschaft_branch.dart';
import 'content/habits_branch.dart';
import 'content/koerper_branch.dart';
import 'content/wissenschaft_branch.dart';
import 'lesson.dart';

/// Alle Theoriezweige zusammen — der Skillbaum.
///
/// Die Sperre liegt beim Charakterlevel, nicht beim Fortschritt im Baum:
/// Zweige öffnen sich durch das, was der Spieler im Leben tut, nicht durch
/// das, was er im Baum bereits gelesen hat (ADR-0007).
class SkillTree {
  const SkillTree(this.branches);

  final List<TheoryBranch> branches;

  int get branchCount => branches.length;

  int get lessonCount {
    return branches.fold(0, (sum, branch) => sum + branch.lessonCount);
  }

  TheoryBranch? branchById(String id) {
    for (final branch in branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  Lesson? lessonById(String lessonId) {
    for (final branch in branches) {
      final lesson = branch.lessonById(lessonId);
      if (lesson != null) return lesson;
    }
    return null;
  }

  /// Der Zweig, zu dem die Lektion gehört.
  TheoryBranch? branchOfLesson(String lessonId) {
    for (final branch in branches) {
      if (branch.indexOf(lessonId) >= 0) return branch;
    }
    return null;
  }

  List<TheoryBranch> unlockedAt(int playerLevel) {
    return List<TheoryBranch>.unmodifiable(
      branches.where((b) => b.isUnlockedAt(playerLevel)),
    );
  }

  List<TheoryBranch> lockedAt(int playerLevel) {
    return List<TheoryBranch>.unmodifiable(
      branches.where((b) => !b.isUnlockedAt(playerLevel)),
    );
  }

  /// Der nächste Zweig, der sich öffnen wird — für die Anzeige „ab Level X“.
  /// Null, wenn alles offen ist.
  TheoryBranch? nextUnlock(int playerLevel) {
    TheoryBranch? next;
    for (final branch in branches) {
      if (branch.isUnlockedAt(playerLevel)) continue;
      if (next == null || branch.unlockLevel < next.unlockLevel) {
        next = branch;
      }
    }
    return next;
  }
}

/// Der Baum, wie er im Spiel steht.
///
/// „Gewohnheiten" steht ohne Sperre vorn: Der Zweig erklärt, wie die App
/// selbst funktioniert (ADR-0005). Ihn hinter ein Level zu legen hieße, das
/// Handbuch wegzusperren.
const SkillTree theoryTree = SkillTree(<TheoryBranch>[
  habitsBranch,
  koerperBranch,
  geistBranch,
  wissenschaftBranch,
  gesellschaftBranch,
]);

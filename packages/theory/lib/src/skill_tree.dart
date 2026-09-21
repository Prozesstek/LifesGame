import 'branch.dart';
import 'content/geist_branch.dart';
import 'content/gesellschaft_branch.dart';
import 'content/habits_branch.dart';
import 'content/koerper_branch.dart';
import 'content/wissenschaft_branch.dart';
import 'lesson.dart';

/// Alle flachen Theoriezweige zusammen.
///
/// Seit ADR-0019 ist das nicht mehr der Skillbaum — der ist `theoryGraph`.
/// Hier stehen noch das Handbuch und die Lektionen, auf die Knoten im
/// Graphen zeigen. Eine Levelsperre gibt es nicht mehr.
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
}

/// Der Baum, wie er im Spiel steht.
///
/// „Gewohnheiten" steht vorn: Der Zweig erklärt, wie die App selbst
/// funktioniert (ADR-0005), und ist das Handbuch, an dem seit ADR-0018 der
/// Kampf hängt.
const SkillTree theoryTree = SkillTree(<TheoryBranch>[
  habitsBranch,
  koerperBranch,
  geistBranch,
  wissenschaftBranch,
  gesellschaftBranch,
]);

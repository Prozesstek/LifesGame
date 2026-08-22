import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../save/save_providers.dart';

/// Bindeglied zwischen den Theorie-Inhalten und der Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Was eine Lektion einbringt und wann
/// sie als bestanden gilt, steht in `package:theory`. Dieser Controller
/// hält nur fest, wo der Spieler steht.
///
/// Der Anfangsstand kommt aus dem Speicher (ADR-0010). Gespeichert wird
/// nicht hier, sondern an einer Stelle für alle drei Bereiche —
/// `lib/save/save_watcher.dart`.
class TheoryController extends Notifier<TheoryProgress> {
  @override
  TheoryProgress build() => ref.watch(savedGameProvider).theory;

  /// Wertet einen Lektionsversuch aus und übernimmt den neuen Fortschritt.
  LessonResult submit(Lesson lesson, List<int?> answers) {
    final result = state.submit(lesson, answers);
    state = result.progress;
    return result;
  }
}

final theoryProgressProvider =
    NotifierProvider<TheoryController, TheoryProgress>(TheoryController.new);

/// Der freie Zweig — das Handbuch der App.
///
/// Er kostet keinen Theoriepunkt (ADR-0012), weil er erklärt, wie das
/// Spiel funktioniert. Seit ADR-0018 ist er zusätzlich der Einstieg: Der
/// Kampf öffnet sich erst, wenn er durch ist.
final handbookProvider = Provider<TheoryBranch>((ref) {
  return theoryTree.branches.firstWhere(
    (branch) => branch.id == handbookBranchId,
    orElse: () => theoryTree.branches.first,
  );
});

/// Die Id des Handbuch-Zweigs. Steht hier und nicht verstreut im Code —
/// an ihr hängt seit ADR-0018 der Zugang zum Kampf.
const String handbookBranchId = 'habits';

/// Ob das Handbuch durchgearbeitet ist.
///
/// **Abschliessen, nicht anfangen.** Ein halb gelesener Zweig ist genau
/// das Verhalten, vor dem `konzept.md` warnt — und vier der fünf
/// Lektionen reichen rechnerisch nicht für Level 3 (ADR-0018).
final handbookDoneProvider = Provider<bool>((ref) {
  return ref
      .watch(theoryProgressProvider)
      .isBranchComplete(ref.watch(handbookProvider));
});

/// Wie viele Lektionen des Handbuchs noch fehlen. 0, wenn es durch ist.
final handbookRemainingProvider = Provider<int>((ref) {
  final branch = ref.watch(handbookProvider);
  final progress = ref.watch(theoryProgressProvider);

  return branch.lessons.length - progress.passedCount(branch);
});

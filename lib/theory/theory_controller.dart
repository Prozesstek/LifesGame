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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

/// Bindeglied zwischen den Theorie-Inhalten und der Oberfläche.
///
/// Enthält bewusst **keine** Regeln: Was eine Lektion einbringt und wann
/// sie als bestanden gilt, steht in `package:theory`. Dieser Controller
/// hält nur fest, wo der Spieler steht.
///
/// Noch ohne Persistenz — der Fortschritt lebt nur, solange die App läuft.
/// Drift kommt, sobald das Datenmodell für Habits steht.
class TheoryController extends Notifier<TheoryProgress> {
  @override
  TheoryProgress build() => const TheoryProgress.empty();

  /// Wertet einen Lektionsversuch aus und übernimmt den neuen Fortschritt.
  LessonResult submit(Lesson lesson, List<int?> answers) {
    final result = state.submit(lesson, answers);
    state = result.progress;
    return result;
  }
}

final theoryProgressProvider =
    NotifierProvider<TheoryController, TheoryProgress>(TheoryController.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import 'package:progression/progression.dart';

import '../progression/level_provider.dart';
import '../dev/dev_controller.dart';
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

  /// Öffnet einen Knoten im Theoriegraphen und zahlt den Punkt.
  ///
  /// **[availablePoints] kommt von außen, und das ist kein Schönheits-
  /// fehler.** Der Punktestand hängt über das Level am Theoriefortschritt
  /// — also am eigenen Zustand. Würde dieser Notifier ihn selbst lesen,
  /// entstünde genau der `CircularDependencyError` aus `gotchas.md`.
  ///
  /// Gibt zurück, ob geöffnet wurde. Die Bedingung selbst steht in
  /// `package:theory`, nicht hier.
  bool openNode(String nodeId, {required int availablePoints}) {
    final graph = ref.read(theoryGraphProvider);
    if (!state.canOpenNode(nodeId, graph, availablePoints: availablePoints)) {
      return false;
    }

    state = state.openNode(nodeId);
    return true;
  }

  /// Öffnet jeden Knoten und besteht jede Seite — Handbuch wie Graph.
  ///
  /// **Nur für den Entwicklermodus** (ADR-0021), und bewusst über
  /// [TheoryProgress.submit] statt über einen Abkürzungspfad: So gelten
  /// dieselben Regeln wie beim echten Beantworten, und Erfahrung und Gold
  /// entstehen auf demselben Weg. Ein eigener „alles bestanden"-Schalter
  /// im Package wäre eine zweite Wahrheit über den Fortschritt.
  ///
  /// Die Punkte für die Knoten werden **nicht** hier verrechnet — der
  /// Dev-Modus schenkt sie getrennt dazu.
  void unlockEverything() {
    var next = state;

    List<int?> allCorrect(Lesson lesson) => <int?>[
      for (final question in lesson.questions) question.correctIndex,
    ];

    for (final branch in theoryTree.branches) {
      for (final lesson in branch.lessons) {
        next = next.submit(lesson, allCorrect(lesson)).progress;
      }
    }

    for (final node in ref.read(theoryGraphProvider).nodes) {
      next = next.submit(node.lesson, allCorrect(node.lesson)).progress;
      next = next.openNode(node.id);
    }

    state = next;
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

/// Der Theoriegraph aus ADR-0019 — vier Wurzeln, zwanzig Unterknoten.
///
/// Als Provider und nicht als Konstante, damit Tests einen kleineren
/// Graphen unterschieben können.
final theoryGraphProvider = Provider<TheoryGraph>((ref) => theoryGraph);

/// Wie viele Theoriepunkte schon in Knoten stecken.
///
/// Abgeleitet aus dem Graphen, nicht gespeichert — wie das Gold.
final spentTheoryPointsProvider = Provider<int>((ref) {
  return ref
      .watch(theoryProgressProvider)
      .spentPointsIn(ref.watch(theoryGraphProvider));
});

/// Wie viele Theoriepunkte noch frei sind.
///
/// **Die einzige Stelle, an der Level und Baum zusammenkommen.** Zwei
/// Punkte je Aufstieg stehen in `package:progression`, die Kosten am
/// Knoten in `package:theory` — hier treffen sie sich.
final availableTheoryPointsProvider = Provider<int>((ref) {
  final verdient = TheoryPoints.availableAt(
    level: ref.watch(playerLevelProvider).level,
    spent: ref.watch(spentTheoryPointsProvider),
  );

  // Ohne Entwicklermodus ist der Zuschlag 0 (ADR-0021).
  final int geschenkt = ref.watch(grantedTheoryPointsProvider);
  return verdient + geschenkt;
});

/// Bestandene Seiten insgesamt — Handbuch **und** Graph.
///
/// **Warum es diesen Provider gibt.** Bis ADR-0019 lagen alle Lektionen
/// in `theoryTree`, und `passedCountIn(theoryTree)` war die ganze
/// Wahrheit. Seither liegen zwölf der neunundzwanzig Seiten nur im
/// Graphen — wer weiter die Zweige zählt, unterschlägt sie. Genau das
/// war nach dem Umbau kurzzeitig der Fall, beim Titelfortschritt und auf
/// dem Startbildschirm.
final passedPagesProvider = Provider<int>((ref) {
  final progress = ref.watch(theoryProgressProvider);

  return progress.passedCount(ref.watch(handbookProvider)) +
      progress.passedNodeCount(ref.watch(theoryGraphProvider));
});

/// Wie viele Seiten es insgesamt gibt.
///
/// Handbuch und Graph überschneiden sich nicht — das prüft
/// `graph_content_test.dart`, damit hier nichts doppelt gezählt wird.
final totalPagesProvider = Provider<int>((ref) {
  return ref.watch(handbookProvider).lessonCount +
      ref.watch(theoryGraphProvider).nodeCount;
});

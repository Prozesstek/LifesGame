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

  /// Öffnet jeden Knoten und besteht jede Seite.
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

/// Ob die fünf Seiten des früheren Handbuchs bestanden sind.
///
/// **Sperrt nichts mehr** (ADR-0070): Bis dahin hing daran der Baum
/// (ADR-0025), davor der Kampf (ADR-0018). Übrig ist eine Bedingung der
/// Startseite — wer sie vor dem Umbau gelesen hatte, behält den Kreis der
/// Fähigkeiten.
final grundlagenGelesenProvider = Provider<bool>((ref) {
  return ref.watch(theoryProgressProvider).isBranchComplete(habitsBranch);
});

/// Der Theoriegraph aus ADR-0019 — vier Wurzeln, einundzwanzig Knoten darunter.
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

/// Bestandene Seiten insgesamt.
///
/// **Der Graph ist die ganze Wahrheit** (ADR-0070). Bis dahin stand das
/// Handbuch daneben und wurde dazugezählt; seit seine fünf Seiten Knoten
/// sind, zählte das sie doppelt. Wer bestandene Seiten braucht, nimmt
/// diesen Provider und weder `theoryTree` noch einen einzelnen Zweig.
final passedPagesProvider = Provider<int>((ref) {
  return ref
      .watch(theoryProgressProvider)
      .passedNodeCount(ref.watch(theoryGraphProvider));
});

/// Wie viele Seiten es insgesamt gibt.
final totalPagesProvider = Provider<int>((ref) {
  return ref.watch(theoryGraphProvider).nodeCount;
});

/// Was der Baum als Nächstes vorschlägt, wenn man im Gebiet [under]
/// steht — **rechnet nichts**: Die Regel steht in
/// `TheoryProgress.suggestedStep`, der Weg in `theoryBasicsPath`.
final suggestedStepProvider = Provider.family<TheoryStep?, String>((
  ref,
  under,
) {
  return ref
      .watch(theoryProgressProvider)
      .suggestedStep(
        ref.watch(theoryGraphProvider),
        path: theoryBasicsPath,
        availablePoints: ref.watch(availableTheoryPointsProvider),
        under: under,
      );
});

/// Die Seite nach der Lektion [lessonId] (ADR-0070) — für den Knopf auf
/// dem Ergebnis. Null, wenn die Lektion an keinem Knoten hängt oder
/// nichts zu lesen und nichts zu bezahlen ist.
final stepAfterLessonProvider = Provider.family<TheoryStep?, String>((
  ref,
  lessonId,
) {
  final graph = ref.watch(theoryGraphProvider);
  for (final node in graph.nodes) {
    if (node.lesson.id != lessonId) continue;
    return ref
        .watch(theoryProgressProvider)
        .nextAfter(
          node.id,
          graph,
          availablePoints: ref.watch(availableTheoryPointsProvider),
        );
  }
  return null;
});

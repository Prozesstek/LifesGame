import 'package:theory/theory.dart';

/// In welchem Zustand ein Knoten für den Spieler ist.
///
/// Fünf Zustände, und der Unterschied zwischen den letzten beiden ist
/// der wichtige: *zu teuer* geht später von selbst weg, *unerreichbar*
/// verlangt, vorher etwas anderes zu öffnen. Sähen beide gleich aus,
/// wüsste niemand, ob Warten hilft.
enum NodeState { passed, open, affordable, tooExpensive, unreachable }

/// In welchem Zustand [node] gerade ist.
///
/// **Eine Frage, eine Stelle.** Die Blase im Baum, der Handlungsknopf
/// darüber und die Elternleiste beantworten sie alle drei — würden sie
/// je selbst rechnen, driften sie auseinander, sobald jemand eine Quelle
/// ergänzt. Genau dieser Fall steht in `gotchas.md`.
///
/// **Erreichbarkeit und Preis sind zwei verschiedene Absagen.** Die eine
/// geht mit dem nächsten Levelaufstieg weg, die andere nicht.
NodeState nodeStateFor(
  TheoryNode node,
  TheoryGraph graph,
  TheoryProgress progress,
  int availablePoints,
) {
  if (progress.isPassed(node.lesson.id)) return NodeState.passed;
  if (progress.isNodeOpened(node.id, graph)) return NodeState.open;
  if (!graph.canOpen(node.id, progress.openIdsIn(graph))) {
    return NodeState.unreachable;
  }
  return node.cost <= availablePoints
      ? NodeState.affordable
      : NodeState.tooExpensive;
}

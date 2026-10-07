import '../branch.dart';
import 'habits_lessons.dart';

/// Das frühere Handbuch — die fünf Seiten, die erklären, wie die App
/// funktioniert.
///
/// Warum ausgerechnet Gewohnheiten: siehe ADR-0005. Kurz — diese Seiten
/// erklären genau das, was der Tracker verlangt. Theorie und Anwendung
/// fallen zusammen, statt nebeneinanderzustehen.
///
/// **Seit ADR-0070 nur noch ein Behälter**, wie die anderen flachen
/// Zweige: Die Seiten stehen als Knoten im Baum unter *Gewohnheiten*
/// (`theory_graph_content.dart`), kosten einen Punkt und haben keine
/// verbindliche Reihenfolge mehr. Wer Seiten zählt, zählt den Graphen —
/// diesen Zweig dazuzunehmen zählte sie doppelt.
const TheoryBranch habitsBranch = TheoryBranch(
  id: 'habits',
  name: 'Gewohnheiten',
  description:
      'Wie Verhalten entsteht, warum es abreißt und was man dagegen tut. '
      'Fünf Lektionen, jede in wenigen Minuten zu lesen.',
  lessons: habitsLessons,
);

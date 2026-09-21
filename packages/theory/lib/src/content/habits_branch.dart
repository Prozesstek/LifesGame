import '../branch.dart';
import 'habits_lessons.dart';

/// Das Handbuch — der Zweig, der erklärt, wie die App funktioniert.
///
/// Warum ausgerechnet Gewohnheiten: siehe ADR-0005. Kurz — dieser Zweig
/// erklärt genau das, was der Tracker verlangt. Theorie und Anwendung
/// fallen zusammen, statt nebeneinanderzustehen. Genau deshalb ist er
/// von Anfang an offen und kostet keinen Theoriepunkt.
const TheoryBranch habitsBranch = TheoryBranch(
  id: 'habits',
  name: 'Gewohnheiten',
  description:
      'Wie Verhalten entsteht, warum es abreißt und was man dagegen tut. '
      'Fünf Lektionen, jede in wenigen Minuten zu lesen.',
  lessons: habitsLessons,
);

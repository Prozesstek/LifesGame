import '../branch.dart';
import 'habits_lessons.dart';

/// Der Wurzelzweig des Skillbaums — ohne Levelsperre.
///
/// Warum ausgerechnet Gewohnheiten: siehe ADR-0005. Kurz — dieser Zweig
/// erklärt genau das, was der Tracker verlangt. Theorie und Anwendung
/// fallen zusammen, statt nebeneinanderzustehen. Genau deshalb bleibt er
/// von Anfang an offen, während die vier Themenzweige ein Level brauchen
/// (ADR-0007).
const TheoryBranch habitsBranch = TheoryBranch(
  id: 'habits',
  name: 'Gewohnheiten',
  description:
      'Wie Verhalten entsteht, warum es abreißt und was man dagegen tut. '
      'Fünf Lektionen, jede in wenigen Minuten zu lesen.',
  lessons: habitsLessons,
);

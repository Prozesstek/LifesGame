import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';

import '../habits/habits_controller.dart';
import '../theory/review_controller.dart';
import '../theory/theory_controller.dart';
import 'skills.dart';

/// Die Skills je Gebiet (ADR-0085) — **die achtzehnte Stelle, an der
/// etwas zusammenläuft**: Gewohnheiten, Seiten und Rückfragen.
///
/// Rechnet nichts selbst; die Summe steht in [Skills.aus], die Regeln in
/// den Packages. Die Errungenschaften nehmen dieselbe Rechnung
/// (`buildAchievementStats`), sonst zeigte der Charakter ein anderes
/// Level, als ein Titel unterstellt.
final skillsProvider = Provider<Skills>((ref) {
  return Skills.aus(
    habits: ref.watch(habitTrackerProvider),
    theory: ref.watch(theoryProgressProvider),
    graph: ref.watch(theoryGraphProvider),
    reviews: ref.watch(reviewLogProvider),
  );
});

/// **Das Gebiet des letzten Häkchens** — der Balken unter dem Level zeigt
/// es, solange seine grünen Funken fliegen (`GebietsBalken`, ADR-0085).
///
/// Nur Darstellung: Gespeichert wird nichts, und nach einem Neustart ist
/// es wieder leer.
final zuletztGebietProvider = NotifierProvider<ZuletztGebiet, SkillArea?>(
  ZuletztGebiet.new,
);

class ZuletztGebiet extends Notifier<SkillArea?> {
  @override
  SkillArea? build() => null;

  void setze(SkillArea area) => state = area;
}

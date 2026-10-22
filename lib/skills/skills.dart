import 'package:habits/habits.dart';
import 'package:progression/progression.dart';
import 'package:theory/theory.dart';

/// **Die Skills je Gebiet** (ADR-0085): was Gewohnheiten, Seiten und
/// Rückfragen eines Gebiets zusammen eingebracht haben.
///
/// Ein Skill ist das, was bleibt, wenn eine Kette fällt. Er misst, wie
/// lange und wie viel jemand in einem Gebiet getan hat — 100 Ketten zu 25
/// Tagen zählen hier mehr als eine zu 30.
///
/// **Gerechnet, nie gespeichert.** Jede Quelle ist eine Historie, also
/// bekommt ein alter Stand seine Skills beim ersten Start, und keiner
/// beginnt bei null.
///
/// Drei Quellen, je Gebiet zusammengezählt — die Regeln dazu stehen in
/// den Packages, hier wird nur addiert:
///
/// | Quelle | Antwortet |
/// |---|---|
/// | Häkchen, mit Kette und Schwierigkeit | `HabitTracker.xpIn` |
/// | bestandene Seiten unter der Wurzel | `TheoryProgress.xpInArea` |
/// | richtige Rückfragen zu diesen Seiten | `ReviewLog.xpFor` |
class Skills {
  Skills._(Map<SkillArea, SkillLevel> levels)
    : _levels = Map<SkillArea, SkillLevel>.unmodifiable(levels);

  /// Alle vier auf Stufe 1 — ein leerer Stand.
  Skills.start() : this._(const <SkillArea, SkillLevel>{});

  factory Skills.aus({
    required HabitTracker habits,
    required TheoryProgress theory,
    required TheoryGraph graph,
    required ReviewLog reviews,
  }) {
    return Skills._(<SkillArea, SkillLevel>{
      for (final area in SkillArea.values)
        area: SkillCurve.levelFor(
          habits.xpIn(area) +
              theory.xpInArea(graph, area.name) +
              reviews.xpFor(_seitenIn(graph, area)),
        ),
    });
  }

  final Map<SkillArea, SkillLevel> _levels;

  SkillLevel of(SkillArea area) => _levels[area] ?? const SkillLevel.start();

  /// **Das Gesamtlevel**: die Summe der vier. Die Zahl zum Vergleichen.
  int get gesamt => SkillCurve.totalLevelOf(SkillArea.values.map(of));

  /// Die Seiten eines Gebiets — die Wurzel samt allem, was daran hängt.
  static Set<String> _seitenIn(TheoryGraph graph, SkillArea area) {
    return <String>{
      for (final node in graph.descendantsOf(area.name, includeSelf: true))
        node.lesson.id,
    };
  }
}

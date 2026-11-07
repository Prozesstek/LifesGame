import 'package:flutter/material.dart';
import 'package:progression/progression.dart';

import '../ui/level_abzeichen.dart';

/// Etwas, das ein Aufstieg bringt — mehr als Punkt und Macht.
@immutable
class RoadmapGewinn {
  const RoadmapGewinn(this.icon, this.name, this.feier);

  final IconData icon;

  /// Wie es auf der Roadmap heißt: „Haustier“.
  final String name;

  /// Wie die Feier eines Aufstiegs es sagt: „Haustier ist offen“.
  final String feier;
}

/// **Die Level-Roadmap** (ADR-0098): was welches Level bringt — reine
/// Rechnung aus den Kurven, die es schon gibt, **keine neue Zahl**.
///
/// Jedes Level bringt einen Talentpunkt und macht im Kampf stärker; das
/// steht einmal oben im Blatt. Einzeln aufgeführt werden nur die
/// **Meilensteine**: Plätze, Ultimate, Extras, ein neuer Rahmen, das
/// Höchstlevel. Eine Stelle für das Blatt und die Feier eines Aufstiegs.
abstract final class LevelRoadmap {
  /// Wie ein Extra heißt und aussieht — **eine Tabelle**.
  static (IconData, String) extra(LevelExtra e) => switch (e) {
    LevelExtra.lagerfeuer => (Icons.local_fire_department, 'Lagerfeuer'),
    LevelExtra.tagesdungeon => (Icons.event, 'Tagesdungeon'),
    LevelExtra.haustier => (Icons.pets, 'Haustier'),
    LevelExtra.statistik => (Icons.insights, 'Statistik'),
    LevelExtra.sammlung => (Icons.collections_bookmark_outlined, 'Sammlung'),
  };

  /// Was der Schritt auf [level] bringt, ohne Punkt und Macht.
  static List<RoadmapGewinn> gewinneAuf(int level) =>
      gewinne(LevelUp.between(level - 1, level));

  /// Was [auf] bringt, ohne Punkt und Macht — auch über mehrere Level.
  static List<RoadmapGewinn> gewinne(LevelUp auf) {
    if (!auf.isLevelUp) return const <RoadmapGewinn>[];
    final rahmen = LevelRahmen.fuer(auf.to);
    final neuerRahmen = rahmen != LevelRahmen.fuer(auf.from);
    return <RoadmapGewinn>[
      for (final slot in auf.newSlots)
        RoadmapGewinn(
          Icons.add_box_outlined,
          'Fähigkeitsplatz $slot',
          '+1 Fähigkeitsplatz',
        ),
      if (auf.opensUltimate)
        const RoadmapGewinn(
          Icons.auto_awesome,
          'Ultimate',
          'Der Platz der Ultimate ist offen',
        ),
      for (final e in auf.extras)
        RoadmapGewinn(extra(e).$1, extra(e).$2, '${extra(e).$2} ist offen'),
      if (neuerRahmen)
        RoadmapGewinn(
          Icons.workspace_premium_outlined,
          'Rahmen: ${rahmen.label}',
          'Neuer Rahmen: ${rahmen.label}',
        ),
      if (auf.isMax)
        const RoadmapGewinn(
          Icons.emoji_events_outlined,
          'Höchstlevel',
          'Das Höchstlevel. Respekt.',
        ),
    ];
  }

  /// Alle Level, die mehr bringen als Punkt und Macht, aufsteigend.
  static final List<int> meilensteine = List<int>.unmodifiable(<int>[
    for (var l = LevelCurve.minLevel + 1; l <= LevelCurve.maxLevel; l++)
      if (gewinneAuf(l).isNotEmpty) l,
  ]);

  /// Der nächste Meilenstein über [level], oder null ganz oben.
  static int? naechsterMeilenstein(int level) {
    for (final l in meilensteine) {
      if (l > level) return l;
    }
    return null;
  }
}

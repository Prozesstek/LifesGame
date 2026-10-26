import 'package:flutter/material.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../ui/palette.dart';

/// Welche Farbe ein Gebiet trägt — **eine Tabelle** (26.10.2026).
///
/// Frederik: „Hinter jedem Theorie-Gebiet eine Farbe … wirklich alles,
/// was irgendwie mit den Gebieten zu tun hat, wird mit der gleichen
/// Farbe eingefärbt.“ Die Werte stehen in der [Palette], je einer für
/// Pergament und einer für Leder; hier steht nur, welches Gebiet welchen
/// trägt.
///
/// Wie `gebietZeichen` gibt es dies **nur einmal**. Stünde die Farbe an
/// einer zweiten Stelle, sähe Körper im Charakter irgendwann anders aus
/// als im Baum.
abstract final class GebietFarbe {
  /// Für Schrift und Flächen auf Pergament und auf dem Buchpapier.
  static Color pergament(SkillArea area) => switch (area) {
    SkillArea.koerper => Palette.gebietKoerper,
    SkillArea.geist => Palette.gebietGeist,
    SkillArea.wissenschaft => Palette.gebietWissenschaft,
    SkillArea.gesellschaft => Palette.gebietGesellschaft,
  };

  /// Für Schrift und Flächen auf Leder: der Baum, die Leiste oben.
  static Color leder(SkillArea area) => switch (area) {
    SkillArea.koerper => Palette.gebietKoerperOnDark,
    SkillArea.geist => Palette.gebietGeistOnDark,
    SkillArea.wissenschaft => Palette.gebietWissenschaftOnDark,
    SkillArea.gesellschaft => Palette.gebietGesellschaftOnDark,
  };

  /// Der Ton für den Grund, auf dem er steht.
  static Color auf(SkillArea area, {required bool dunkel}) =>
      dunkel ? leder(area) : pergament(area);

  /// Die Farbe der Wurzel [rootId] im Baum. Eine Wurzel, die kein Gebiet
  /// ist — die gibt es nur in Tests —, trägt den Akzent.
  static Color vonWurzel(String rootId, {required bool dunkel}) =>
      switch (SkillArea.tryParse(rootId)) {
        final SkillArea area => auf(area, dunkel: dunkel),
        null => dunkel ? Palette.accentOnDark : Palette.accent,
      };
}

/// Zu welchem Gebiet ein Knoten des Baums gehört.
///
/// **[bevorzugt], wenn er dort steht**: Wer *Stress* unter Geist öffnet,
/// liest ihn in der Farbe von Geist, obwohl er zuerst an Körper hängt.
/// Sonst sein Zuhause (`TheoryGraph.rootIdsOf`). Null für eine Id, die
/// es nicht gibt.
SkillArea? gebietVon(TheoryGraph graph, String nodeId, {SkillArea? bevorzugt}) {
  final wurzeln = graph.rootIdsOf(nodeId);
  if (bevorzugt != null && wurzeln.contains(bevorzugt.name)) return bevorzugt;
  for (final id in wurzeln) {
    final area = SkillArea.tryParse(id);
    if (area != null) return area;
  }
  return null;
}

/// Zu welchem Gebiet eine Seite gehört — über den Knoten, der sie trägt.
/// Null für eine Seite, die in keinem Knoten steht.
SkillArea? gebietDerSeite(
  TheoryGraph graph,
  String lessonId, {
  SkillArea? bevorzugt,
}) {
  for (final node in graph.nodes) {
    if (node.lesson.id != lessonId) continue;
    return gebietVon(graph, node.id, bevorzugt: bevorzugt);
  }
  return null;
}

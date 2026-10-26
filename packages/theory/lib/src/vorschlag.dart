import 'node.dart';
import 'node_graph.dart';
import 'progress.dart';

/// Warum eine Seite vorgeschlagen wird — jeder Vorschlag sagt es mit
/// seinem Zeichen.
enum TheoryVorschlagGrund {
  /// Schon geöffnet und noch nicht gelesen: kostet nichts.
  offen,

  /// Der nächste Schritt auf dem Weg der Grundlagen (ADR-0070).
  grundlagen,

  /// Weiter, wo zuletzt Neues gelesen wurde: darunter, daneben, im
  /// selben Gebiet.
  weiter,

  /// Im Gebiet, in dem die Gewohnheiten am meisten Erfahrung bringen
  /// (ADR-0085).
  gewohnheiten,

  /// Ein Gebiet, in dem noch nichts gelesen ist.
  neuesGebiet,
}

/// Ein Vorschlag: der Schritt und sein Grund.
class TheoryVorschlag {
  const TheoryVorschlag(this.step, this.grund);

  final TheoryStep step;
  final TheoryVorschlagGrund grund;

  TheoryNode get node => step.node;
}

/// **Vorschläge für das nächste Kapitel** (26.10.2026).
///
/// Frederik: „Wenn ein Skillpunkt offen ist: Vorschläge für nächstes
/// Kapitel. So muss der Spieler nicht selber entscheiden, kann es aber,
/// wenn er will. Sonst wird ihm vorgeschlagen abhängig von dem, was er
/// gemacht hat.“
///
/// Bis dahin gab es genau einen Vorschlag ([TheoryProgress.suggestedStep]):
/// was offen ist, sonst der Weg der Grundlagen. Wer die Grundlagen durch
/// hatte, bekam nichts mehr.
extension TheoryVorschlaege on TheoryProgress {
  /// Höchstens [hoechstens] Seiten, jede nur einmal, in dieser Reihenfolge:
  ///
  /// 1. was offen ist ([TheoryVorschlagGrund.offen]) — unter [under]
  ///    zuerst, dann irgendwo; höchstens eine,
  /// 2. der Weg der Grundlagen, solange er nicht durch ist,
  /// 3. weiter, wo zuletzt gelesen wurde,
  /// 4. das Gebiet der Gewohnheiten: [gewicht] ist je Wurzel die
  ///    Erfahrung, die Häkchen dort gebracht haben,
  /// 5. ein Gebiet ohne bestandene Seite.
  ///
  /// **Der erste ist derselbe wie [TheoryProgress.suggestedStep]** —
  /// wer nicht wählen will, nimmt ihn, und der Mentor zeigt auf ihn.
  ///
  /// Vorgeschlagen wird nur, was offen ist oder sich mit
  /// [availablePoints] öffnen lässt. Ohne freien Punkt bleibt also
  /// höchstens, was schon offen ist.
  List<TheoryVorschlag> vorschlaege(
    TheoryGraph graph, {
    required List<String> path,
    required int availablePoints,
    Map<String, int> gewicht = const <String, int>{},
    String? under,
    int hoechstens = 3,
  }) {
    final offen = openIdsIn(graph);
    final ergebnis = <TheoryVorschlag>[];
    final schon = <String>{};

    bool nimm(TheoryStep? step, TheoryVorschlagGrund grund) {
      if (step == null || ergebnis.length >= hoechstens) return false;
      if (!schon.add(step.node.id)) return false;
      ergebnis.add(TheoryVorschlag(step, grund));
      return true;
    }

    /// Der erste lesbare Knoten aus [kandidaten], der noch nicht dran ist.
    TheoryStep? ersterAus(Iterable<TheoryNode> kandidaten) {
      for (final node in kandidaten) {
        if (schon.contains(node.id)) continue;
        final step = _schritt(node, graph, offen, availablePoints);
        if (step != null) return step;
      }
      return null;
    }

    final liegt = (under == null ? null : nextToRead(graph, under: under)) ??
        nextToRead(graph);
    if (liegt != null) {
      nimm(TheoryStep(liegt, needsOpening: false), TheoryVorschlagGrund.offen);
    }

    nimm(
      nextOnPath(path, graph, availablePoints: availablePoints),
      TheoryVorschlagGrund.grundlagen,
    );

    nimm(ersterAus(_weiterNach(graph)), TheoryVorschlagGrund.weiter);

    final nachGewicht = graph.roots
        .where((r) => (gewicht[r.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (gewicht[b.id] ?? 0).compareTo(gewicht[a.id] ?? 0));
    for (final wurzel in nachGewicht) {
      final step = ersterAus(graph.descendantsOf(wurzel.id, includeSelf: true));
      if (nimm(step, TheoryVorschlagGrund.gewohnheiten)) break;
    }

    // Unberührte Gebiete — die mit Gewohnheiten zuerst, sonst wie im Baum.
    final unberuehrt = graph.roots
        .where((r) => !hasPassedInArea(graph, r.id))
        .toList()
      ..sort((a, b) => (gewicht[b.id] ?? 0).compareTo(gewicht[a.id] ?? 0));
    for (final wurzel in unberuehrt) {
      if (nimm(
        ersterAus(<TheoryNode>[wurzel]),
        TheoryVorschlagGrund.neuesGebiet,
      )) {
        break;
      }
    }

    return List<TheoryVorschlag>.unmodifiable(ergebnis);
  }

  /// Wohin es von der zuletzt bestandenen Seite weitergeht: erst ihre
  /// Kinder, dann ihre Geschwister, dann ihr Gebiet.
  Iterable<TheoryNode> _weiterNach(TheoryGraph graph) sync* {
    final zuletzt = passedInOrder;
    if (zuletzt.isEmpty) return;
    TheoryNode? knoten;
    for (final node in graph.nodes) {
      if (node.lesson.id == zuletzt.last) knoten = node;
    }
    if (knoten == null) return;

    yield* graph.childrenOf(knoten.id);
    for (final eltern in knoten.parentIds) {
      yield* graph.childrenOf(eltern);
    }
    final zuhause = graph.rootIdsOf(knoten.id);
    if (zuhause.isNotEmpty) {
      yield* graph.descendantsOf(zuhause.first, includeSelf: true);
    }
  }

  /// Wie `nextAfter` einen Knoten liest: offen, oder zu öffnen und
  /// bezahlbar. Bestandenes nicht.
  TheoryStep? _schritt(
    TheoryNode node,
    TheoryGraph graph,
    Set<String> offen,
    int availablePoints,
  ) {
    if (isPassed(node.lesson.id)) return null;
    if (offen.contains(node.id)) return TheoryStep(node, needsOpening: false);
    if (node.cost <= availablePoints && graph.canOpen(node.id, offen)) {
      return TheoryStep(node, needsOpening: true);
    }
    return null;
  }
}

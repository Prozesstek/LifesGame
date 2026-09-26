import 'node.dart';
import 'placeholder.dart';

/// Alle Theorieknoten und ihre Verbindungen.
///
/// **Ein Graph, kein Baum.** Ein Knoten darf zwei Eltern haben, damit
/// „Ernährung" unter Körper *und* Wissenschaft hängen kann (ADR-0019).
/// Das kostet zwei Prüfungen, die ein Baum nicht gebraucht hätte:
/// [isAcyclic] und [danglingParentIds].
///
/// Zum Öffnen genügt **ein** offener Elternknoten. Beide zu verlangen
/// baute eine Reihenfolge quer durch zwei Wurzeln, die im Baum niemand
/// sieht — wer von der einen Seite kommt, käme nicht weiter und wüsste
/// nicht, warum.
class TheoryGraph {
  const TheoryGraph(
    this.nodes, {
    this.placeholders = const <TheoryPlaceholder>[],
  });

  final List<TheoryNode> nodes;

  /// Angekündigte Überschriften ohne Seite (ADR-0050).
  ///
  /// Stehen **nicht** in [nodes]: Alles, was Seiten zählt, belohnt oder
  /// abfragt, sieht sie nicht. Nur das Bild zeigt sie.
  final List<TheoryPlaceholder> placeholders;

  int get nodeCount => nodes.length;

  TheoryNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Die Einstiegsknoten — die ohne Eltern.
  List<TheoryNode> get roots {
    return List<TheoryNode>.unmodifiable(nodes.where((n) => n.isRoot));
  }

  List<TheoryNode> childrenOf(String id) {
    return List<TheoryNode>.unmodifiable(
      nodes.where((n) => n.parentIds.contains(id)),
    );
  }

  /// Die angekündigten Überschriften unter [id].
  List<TheoryPlaceholder> placeholdersOf(String id) {
    return List<TheoryPlaceholder>.unmodifiable(
      placeholders.where((p) => p.parentIds.contains(id)),
    );
  }

  TheoryPlaceholder? placeholderById(String id) {
    for (final placeholder in placeholders) {
      if (placeholder.id == id) return placeholder;
    }
    return null;
  }

  List<TheoryNode> parentsOf(String id) {
    final node = nodeById(id);
    if (node == null) return const <TheoryNode>[];

    final parents = <TheoryNode>[];
    for (final parentId in node.parentIds) {
      final parent = nodeById(parentId);
      if (parent != null) parents.add(parent);
    }
    return List<TheoryNode>.unmodifiable(parents);
  }

  /// Alle Knoten, die von [id] aus nach unten erreichbar sind.
  ///
  /// **Wofür.** Ein Gebiet ist eine Wurzel mit allem, was daran hängt —
  /// und der Fortschritt eines Gebiets ist genau die Frage, wie viele
  /// davon bestanden sind (ADR-0026).
  ///
  /// Ein Knoten mit zwei Eltern kommt in **beiden** Gebieten vor. Das ist
  /// kein Fehler, sondern die Aussage: *Stress* gehört zu Körper und zu
  /// Geist, und beide Seiten dürfen ihn zählen.
  List<TheoryNode> descendantsOf(String id, {bool includeSelf = false}) {
    final gefunden = <String>{};
    final ergebnis = <TheoryNode>[];

    void absteigen(String von) {
      for (final kind in childrenOf(von)) {
        if (!gefunden.add(kind.id)) continue;
        ergebnis.add(kind);
        absteigen(kind.id);
      }
    }

    if (includeSelf) {
      final selbst = nodeById(id);
      if (selbst != null) {
        gefunden.add(id);
        ergebnis.add(selbst);
      }
    }
    absteigen(id);

    return List<TheoryNode>.unmodifiable(ergebnis);
  }

  /// Ob [id] mit den bereits geöffneten Knoten geöffnet werden darf.
  ///
  /// Prüft **nicht**, ob genug Theoriepunkte da sind — das ist die Frage
  /// der Ökonomie und gehört zu `packages/progression`. Hier steht nur
  /// die Struktur.
  bool canOpen(String id, Set<String> openedIds) {
    final node = nodeById(id);
    if (node == null) return false;
    if (node.isRoot) return true;

    return node.parentIds.any(openedIds.contains);
  }

  /// [ids], ergänzt um jeden Knoten, der als **einziger Eltern** eines
  /// Knotens darin steht — bis nichts mehr dazukommt.
  ///
  /// **Warum das stimmt.** Ein Knoten mit genau einem Eltern ließ sich
  /// nur öffnen, solange dieser Eltern offen war. Steht er offen da, war
  /// es der Eltern also auch. Für einen neuen Spieler ändert die Regel
  /// darum nichts.
  ///
  /// **Wofür sie da ist: alte Spielstände** (ADR-0050, ADR-0051). Wer
  /// Schlaf geöffnet hat, als er noch direkt an einer kostenlosen Wurzel
  /// hing, hat weder Schlaf & Regeneration noch Körper im Spielstand.
  /// Beide gelten über diese Regel als offen — ohne Punkt, weil sie
  /// nicht im Spielstand stehen.
  ///
  /// Ein Kind mit **zwei** Eltern (Stress, Vergleich) sagt nichts
  /// darüber, welcher offen war, und schenkt deshalb keinen.
  Set<String> withSoleParents(Set<String> ids) {
    final offen = <String>{...ids};
    var gewachsen = true;
    while (gewachsen) {
      gewachsen = false;
      for (final node in nodes) {
        if (!offen.contains(node.id) || node.parentIds.length != 1) continue;
        if (offen.add(node.parentIds.single)) gewachsen = true;
      }
    }
    return offen;
  }

  /// Ids, die mehr als einmal vorkommen. Leer ist gut.
  List<String> get duplicateIds {
    final seen = <String>{};
    final doubled = <String>{};
    for (final id in <String>[
      for (final node in nodes) node.id,
      for (final placeholder in placeholders) placeholder.id,
    ]) {
      if (!seen.add(id)) doubled.add(id);
    }
    return List<String>.unmodifiable(doubled);
  }

  /// Eltern-Ids, zu denen es keinen Knoten gibt. Leer ist gut.
  ///
  /// Ein Tippfehler in einer Eltern-Id macht sonst einen Knoten
  /// unerreichbar, ohne dass irgendetwas abstürzt.
  List<String> get danglingParentIds {
    final known = nodes.map((n) => n.id).toSet();
    final missing = <String>{};
    final parentLists = <List<String>>[
      for (final node in nodes) node.parentIds,
      for (final placeholder in placeholders) placeholder.parentIds,
    ];
    for (final parentIds in parentLists) {
      for (final parentId in parentIds) {
        if (!known.contains(parentId)) missing.add(parentId);
      }
    }
    return List<String>.unmodifiable(missing);
  }

  /// Ob der Graph kreisfrei ist.
  ///
  /// Ein Kreis ist kein theoretisches Problem: Jeder Knoten darin wäre
  /// dauerhaft gesperrt, weil keiner ohne den anderen zu öffnen ist. Der
  /// bezahlte Punkt wäre verloren.
  bool get isAcyclic {
    final visited = <String>{};
    final onPath = <String>{};

    bool hasCycleFrom(String id) {
      if (onPath.contains(id)) return true;
      if (visited.contains(id)) return false;

      onPath.add(id);
      final node = nodeById(id);
      if (node != null) {
        for (final parentId in node.parentIds) {
          if (hasCycleFrom(parentId)) return true;
        }
      }
      onPath.remove(id);
      visited.add(id);
      return false;
    }

    for (final node in nodes) {
      if (hasCycleFrom(node.id)) return false;
    }
    return true;
  }

  /// Ankündigungen ohne Eltern. Leer ist gut.
  ///
  /// Eine Ankündigung ohne Platz stünde nirgends im Bild.
  List<String> get orphanPlaceholderIds {
    return List<String>.unmodifiable(
      placeholders.where((p) => p.parentIds.isEmpty).map((p) => p.id),
    );
  }

  /// Ob der Graph benutzbar ist.
  ///
  /// Vier Bedingungen, alle mit demselben Zweck: Es darf keinen Knoten
  /// geben, für den ein Punkt bezahlt werden kann, ohne dass er je
  /// erreichbar wird.
  bool get isHealthy {
    return duplicateIds.isEmpty &&
        danglingParentIds.isEmpty &&
        isAcyclic &&
        roots.isNotEmpty &&
        orphanPlaceholderIds.isEmpty;
  }
}

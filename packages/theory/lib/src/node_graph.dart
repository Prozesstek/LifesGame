import 'node.dart';

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
  const TheoryGraph(this.nodes);

  final List<TheoryNode> nodes;

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

  /// Ids, die mehr als einmal vorkommen. Leer ist gut.
  List<String> get duplicateIds {
    final seen = <String>{};
    final doubled = <String>{};
    for (final node in nodes) {
      if (!seen.add(node.id)) doubled.add(node.id);
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
    for (final node in nodes) {
      for (final parentId in node.parentIds) {
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

  /// Ob der Graph benutzbar ist.
  ///
  /// Vier Bedingungen, alle mit demselben Zweck: Es darf keinen Knoten
  /// geben, für den ein Punkt bezahlt werden kann, ohne dass er je
  /// erreichbar wird.
  bool get isHealthy {
    return duplicateIds.isEmpty &&
        danglingParentIds.isEmpty &&
        isAcyclic &&
        roots.isNotEmpty;
  }
}

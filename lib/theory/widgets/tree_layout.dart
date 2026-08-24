import 'dart:ui';

import 'package:theory/theory.dart';

/// Wo jeder Knoten auf der Zeichenfläche sitzt.
///
/// **Reine Rechnung, kein Widget.** Die Anordnung ist der Teil, der
/// schiefgehen kann — überlappende Knoten, Kinder außerhalb der Fläche,
/// eine Wurzel ohne Platz. Als Funktion lässt sich das prüfen, ohne
/// etwas zu rendern.
///
/// **Warum von oben nach unten und nicht radial wie das Vorbild.**
/// Das Zielgerät ist ein Handy im Hochformat (`konzept.md` 5). Ein
/// radialer Baum braucht Breite in alle Richtungen; ein Band je Gebiet
/// braucht sie nur nach unten — und nach unten hat ein Handy beliebig
/// viel.
class TreeLayout {
  const TreeLayout({
    required this.positions,
    required this.size,
    required this.bandTops,
  });

  /// Baut die Anordnung für [graph].
  ///
  /// Ein Band je Wurzel: die Wurzel oben in der Mitte, ihre Kinder
  /// darunter in einem flachen Bogen. Der Bogen ist reine Kosmetik, aber
  /// er unterscheidet den Baum von einer Tabelle.
  factory TreeLayout.of(TheoryGraph graph, List<String> rootIds) {
    final positions = <String, Offset>{};
    final bandTops = <String, double>{};

    var y = topPadding;
    for (final rootId in rootIds) {
      final root = graph.nodeById(rootId);
      if (root == null) continue;

      bandTops[rootId] = y;
      positions[rootId] = Offset(canvasWidth / 2, y + rootOffsetY);

      final children = graph.childrenOf(rootId);
      // Kinder, die schon in einem früheren Band liegen, bekommen keine
      // zweite Stelle — sie werden nur zusätzlich verbunden. Sonst hätte
      // ein verbindender Knoten zwei Positionen und die Linie ginge ins
      // Leere.
      final eigene = children
          .where((c) => !positions.containsKey(c.id))
          .toList();

      for (var i = 0; i < eigene.length; i++) {
        positions[eigene[i].id] = _childOffset(i, eigene.length, y);
      }

      y += bandHeight;
    }

    return TreeLayout(
      positions: positions,
      size: Size(canvasWidth, y - bandHeight + bandHeight),
      bandTops: bandTops,
    );
  }

  /// Breite der Zeichenfläche. Breiter als ein Handy — dafür gibt es
  /// Verschieben und Zoomen.
  static const double canvasWidth = 620;

  /// Höhe eines Gebietsbandes.
  static const double bandHeight = 300;

  static const double topPadding = 24;

  /// Wie weit unter dem Bandanfang die Wurzel sitzt.
  static const double rootOffsetY = 40;

  /// Wie weit unter dem Bandanfang die Kinder sitzen.
  static const double childOffsetY = 190;

  /// Wie stark sich der Bogen der Kinder hebt.
  static const double arcLift = 34;

  /// Radius eines Knotens.
  static const double nodeRadius = 26;

  final Map<String, Offset> positions;
  final Size size;

  /// Der obere Rand jedes Gebietsbandes — für die Beschriftung.
  final Map<String, double> bandTops;

  Offset? operator [](String nodeId) => positions[nodeId];

  static Offset _childOffset(int index, int count, double bandTop) {
    final slot = canvasWidth / count;
    final x = slot * index + slot / 2;

    // Die äußeren Kinder rutschen nach unten, die mittleren stehen
    // höher — das ergibt den Bogen.
    final mitte = (count - 1) / 2;
    final abstand = mitte == 0 ? 0.0 : (index - mitte).abs() / mitte;
    final y = bandTop + childOffsetY + arcLift * abstand;

    return Offset(x, y);
  }
}

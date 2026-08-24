import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'tree_layout.dart';

/// Zeichnet die Verbindungen zwischen den Knoten.
///
/// **Die Linien sind der Unterschied zwischen einem Baum und einer
/// Liste.** Ohne sie stünden 24 Kacheln nebeneinander und niemand sähe,
/// dass *Stress* an Körper **und** Geist hängt.
///
/// Zwei Sorten Linie, und der Unterschied trägt eine Aussage:
///
/// * **Durchgezogen** — die Verbindung zur eigenen Wurzel.
/// * **Gestrichelt** — eine Verbindung in ein anderes Gebiet. Sie läuft
///   quer über die Bänder und wäre sonst nicht als etwas anderes zu
///   erkennen.
class TreePainter extends CustomPainter {
  const TreePainter({
    required this.graph,
    required this.layout,
    required this.openIds,
  });

  final TheoryGraph graph;
  final TreeLayout layout;

  /// Offene Knoten werden hell verbunden, gesperrte stumpf. Damit sieht
  /// man den zurückgelegten Weg, ohne einen Knoten anzutippen.
  final Set<String> openIds;

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in graph.nodes) {
      final to = layout[node.id];
      if (to == null) continue;

      for (final parentId in node.parentIds) {
        final from = layout[parentId];
        if (from == null) continue;

        final erreicht = openIds.contains(node.id);
        final quer = _isCrossBand(from, to);

        final paint = Paint()
          ..color = erreicht
              ? Palette.accent.withValues(alpha: quer ? 0.45 : 0.7)
              : Palette.muted.withValues(alpha: quer ? 0.25 : 0.4)
          ..strokeWidth = erreicht ? 2.0 : 1.4
          ..style = PaintingStyle.stroke;

        final path = _curve(from, to);
        if (quer) {
          _drawDashed(canvas, path, paint);
        } else {
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  /// Eine Verbindung läuft quer, wenn sie mehr als ein Band überspringt.
  bool _isCrossBand(Offset from, Offset to) {
    return (to.dy - from.dy).abs() > TreeLayout.bandHeight * 0.8;
  }

  /// Eine weiche Kurve statt einer Geraden — gerade Linien zwischen
  /// Kreisen sehen aus wie ein Schaltplan, nicht wie ein Baum.
  Path _curve(Offset from, Offset to) {
    final path = Path()..moveTo(from.dx, from.dy);
    final mitteY = (from.dy + to.dy) / 2;

    path.cubicTo(from.dx, mitteY, to.dx, mitteY, to.dx, to.dy);
    return path;
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const strich = 7.0;
    const luecke = 6.0;

    for (final metric in path.computeMetrics()) {
      var abstand = 0.0;
      while (abstand < metric.length) {
        final ende = (abstand + strich).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(abstand, ende), paint);
        abstand = ende + luecke;
      }
    }
  }

  @override
  bool shouldRepaint(TreePainter old) {
    return old.openIds.length != openIds.length ||
        old.layout != layout ||
        old.graph != graph;
  }
}

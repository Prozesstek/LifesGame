import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'tree_layout.dart';

/// Zeichnet die Verbindungen vom Startknoten zu seinen Kindern.
///
/// **Die Linien sind der Unterschied zwischen einem Baum und einer
/// Liste.** Ohne sie stünden fünf Kacheln nebeneinander und niemand
/// sähe, dass sie an dem Knoten hängen, der darunter sitzt.
///
/// Seit ADR-0026 ist nur **eine** Ebene im Bild, also gibt es auch nur
/// eine Sorte Verbindung: von unten nach oben. Die alte Unterscheidung
/// zwischen Linien innerhalb eines Bandes und quer über die Bänder ist
/// damit gegenstandslos — es gibt keine Bänder mehr.
///
/// Geblieben ist eine Unterscheidung, und sie trägt weiter eine Aussage:
///
/// * **Durchgezogen** — ein Kind, das nur hier hängt.
/// * **Gestrichelt** — ein Kind mit zwei Eltern. Es steht in beiden
///   Gebieten, und ohne die gestrichelte Linie sähe man ihm das nicht an.
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
    final start = layout[layout.focusId];
    if (start == null) return;

    for (final kind in graph.childrenOf(layout.focusId)) {
      final ziel = layout[kind.id];
      if (ziel == null) continue;

      final erreicht = openIds.contains(kind.id);
      final geteilt = kind.parentIds.length > 1;

      final paint = Paint()
        ..color = erreicht
            ? Palette.accent.withValues(alpha: geteilt ? 0.5 : 0.75)
            : Palette.muted.withValues(alpha: geteilt ? 0.3 : 0.45)
        ..strokeWidth = erreicht ? 2.2 : 1.5
        ..style = PaintingStyle.stroke;

      final pfad = _curve(start, ziel);
      if (geteilt) {
        _drawDashed(canvas, pfad, paint);
      } else {
        canvas.drawPath(pfad, paint);
      }
    }
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
    return old.layout.focusId != layout.focusId ||
        old.openIds.length != openIds.length ||
        old.layout != layout ||
        old.graph != graph;
  }
}

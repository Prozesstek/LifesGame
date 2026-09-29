import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'node_icon.dart';
import 'node_state.dart';
import 'tree_layout.dart';
import '../../ui/druck.dart';

/// Ein Knoten im gezeichneten Baum: ein Kreis mit Symbol.
///
/// Der Name steht **unter** dem Kreis und nicht darin. Titel wie
/// „Stress ist ein Werkzeug mit Verfallsdatum" passen in keinen Kreis,
/// und ein Baum aus abgeschnittenen Wörtern ist unlesbar.
///
/// Es gibt die Blase in zwei Größen. Der Startknoten unten ist größer —
/// er ist der Ort, an dem man gerade steht, und ein zweiter Druck darauf
/// öffnet ihn (ADR-0026). Wäre er so groß wie seine Kinder, sähe die
/// Ebene aus wie sechs gleichwertige Knöpfe.
class NodeBubble extends StatelessWidget {
  const NodeBubble({
    required this.node,
    required this.state,
    required this.onTap,
    this.radius = TreeLayout.nodeRadius,
    this.width = labelWidth,
    this.below,
    super.key,
  });

  /// Die größere Blase für den Startknoten.
  const NodeBubble.focus({
    required this.node,
    required this.state,
    required this.onTap,
    this.below,
    super.key,
  }) : radius = TreeLayout.focusRadius,
       width = focusLabelWidth;

  final TheoryNode node;
  final NodeState state;
  final VoidCallback onTap;

  /// Wie viel unter diesem Knoten geschafft ist (ADR-0056) — oder null
  /// bzw. `total == 0` bei einem Thema ohne Unterpunkte.
  ///
  /// **Grün heißt „diese Seite gelesen“, der Ring sagt, was darunter
  /// liegt.** Vorher leuchtete eine Zwischenebene grün, sobald ihre
  /// Einführung bestanden war — und sah fertig aus, obwohl vier von fünf
  /// Themen fehlten.
  final ({int passed, int total})? below;

  /// Radius des Kreises.
  final double radius;

  /// Wie breit die Blase samt Namenszeile ist. Sie bestimmt, wo die
  /// Blase sitzt — die Anordnung gibt nur den Mittelpunkt.
  final double width;

  static const double labelWidth = 108;
  static const double focusLabelWidth = 150;

  bool get _isFocus => radius >= TreeLayout.focusRadius;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final gefuellt = state == NodeState.passed;

    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: '${node.name}, ${_stateLabel()}',
        child: Druck(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gefuellt
                              ? color.withValues(alpha: 0.9)
                              : Palette.surface,
                          border: Border.all(
                            color: color.withValues(alpha: gefuellt ? 1 : 0.65),
                            width: _isFocus || node.isRoot ? 2.5 : 1.8,
                          ),
                        ),
                        child: Icon(
                          iconForNode(node.iconId),
                          size: _isFocus ? 32 : (node.isRoot ? 26 : 22),
                          color: gefuellt ? Palette.background : color,
                        ),
                      ),
                      if (_hatUnterpunkte)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _RingPainter(
                                anteil: _anteil,
                                fertig: _allesDarunter,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: NodeStateBadge(
                          state: state,
                          fertig: _allesDarunter,
                          cost: node.cost,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    node.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _isFocus ? 12 : 10,
                      height: 1.2,
                      color: _isDim()
                          ? Palette.textOnDarkDim
                          : Palette.textOnDark,
                      fontWeight: _isFocus || node.isRoot
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (below case (:final passed, :final total) when total > 0)
                    Text(
                      '$passed / $total',
                      style: TextStyle(
                        fontSize: _isFocus ? 11 : 9.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: _allesDarunter
                            ? Palette.goldOnDark
                            : Palette.textOnDarkDim,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hatUnterpunkte => (below?.total ?? 0) > 0;

  double get _anteil {
    final b = below;
    if (b == null || b.total == 0) return 0;
    return b.passed / b.total;
  }

  /// Seite gelesen **und** alles darunter — erst dann gold.
  bool get _allesDarunter {
    final b = below;
    if (b == null || b.total == 0) return false;
    return state == NodeState.passed && b.passed >= b.total;
  }

  bool _isDim() =>
      state == NodeState.unreachable || state == NodeState.tooExpensive;

  String _stateLabel() {
    return switch (state) {
      NodeState.passed when _allesDarunter => 'bestanden, alles darunter',
      NodeState.passed when _hatUnterpunkte =>
        'bestanden, ${below!.passed} von ${below!.total} darunter',
      NodeState.passed => 'bestanden',
      NodeState.open => 'offen',
      NodeState.affordable => 'kann geöffnet werden',
      NodeState.tooExpensive => 'zu teuer',
      NodeState.unreachable => 'nicht erreichbar',
    };
  }

  Color _color() {
    return switch (state) {
      NodeState.passed => Palette.successOnDark,
      NodeState.open => Palette.accentOnDark,
      NodeState.affordable => Palette.goldOnDark,
      NodeState.tooExpensive || NodeState.unreachable => Palette.textOnDarkDim,
    };
  }
}

/// Eine angekündigte Überschrift: grau, ohne Druck, „Inhalt folgt"
/// (ADR-0050).
///
/// **Nicht antippbar, und deshalb kein [Druck].** Ein Knopf, der einsinkt
/// und dann nichts tut, wäre schlimmer als einer, der gar nicht erst so
/// aussieht. Gestrichelter Rand statt durchgezogener: Der Kreis ist
/// vorgezeichnet, gefüllt wird er später.
class PlaceholderBubble extends StatelessWidget {
  const PlaceholderBubble({required this.placeholder, super.key});

  final TheoryPlaceholder placeholder;

  @override
  Widget build(BuildContext context) {
    const radius = TreeLayout.nodeRadius;

    return SizedBox(
      width: NodeBubble.labelWidth,
      child: Semantics(
        label: '${placeholder.title}, Inhalt folgt',
        child: Opacity(
          opacity: 0.55,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.background,
                    border: Border.all(
                      color: Palette.textOnDarkDim.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    iconForNode(placeholder.iconId),
                    size: 22,
                    color: Palette.textOnDarkDim,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  placeholder.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: Palette.textOnDarkDim,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Statt „Inhalt folgt“ eine Sanduhr: grau und still genug.
                const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 11,
                  color: Palette.textOnDarkDim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Der Ring um einen Knoten mit Unterpunkten: wie viel darunter
/// geschafft ist. Gold, sobald alles geschafft ist.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.anteil, required this.fertig});

  final double anteil;
  final bool fertig;

  static const double _dicke = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).inflate(_dicke / 2 + 1);
    final spur = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dicke
      ..color = Palette.textOnDarkDim.withValues(alpha: 0.25);
    canvas.drawArc(rect, 0, 2 * math.pi, false, spur);
    if (anteil <= 0) return;

    final bogen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dicke
      ..strokeCap = StrokeCap.round
      ..color = fertig ? Palette.goldOnDark : Palette.successOnDark;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * anteil, false, bogen);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.anteil != anteil || old.fertig != fertig;
}

/// Das kleine Zeichen unten rechts am Kreis: was man mit dem Knoten tun
/// kann (ADR-0056). **Zeichen statt nur Farbe** — drei Beigetöne für
/// kaufbar, zu teuer und unerreichbar errät niemand.
class NodeStateBadge extends StatelessWidget {
  const NodeStateBadge({
    required this.state,
    required this.fertig,
    required this.cost,
    super.key,
  });

  final NodeState state;
  final bool fertig;
  final int cost;

  static const double groesse = 18;

  @override
  Widget build(BuildContext context) {
    final (Color grund, Widget inhalt) = switch (state) {
      NodeState.passed => (
        fertig ? Palette.goldOnDark : Palette.successOnDark,
        const Icon(Icons.check_rounded, size: 13, color: Palette.background),
      ),
      NodeState.open => (
        Palette.accentOnDark,
        const Icon(
          Icons.menu_book_rounded,
          size: 11,
          color: Palette.background,
        ),
      ),
      NodeState.affordable => (
        Palette.goldOnDark,
        Text(
          '$cost',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Palette.background,
            height: 1,
          ),
        ),
      ),
      NodeState.tooExpensive => (
        Palette.background,
        const Icon(
          Icons.lock_clock_rounded,
          size: 11,
          color: Palette.textOnDarkDim,
        ),
      ),
      NodeState.unreachable => (
        Palette.background,
        const Icon(Icons.lock_rounded, size: 11, color: Palette.textOnDarkDim),
      ),
    };

    return Container(
      width: groesse,
      height: groesse,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: grund,
        shape: BoxShape.circle,
        border: Border.all(color: Palette.background, width: 1.5),
      ),
      child: inhalt,
    );
  }
}

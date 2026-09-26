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
    super.key,
  });

  /// Die größere Blase für den Startknoten.
  const NodeBubble.focus({
    required this.node,
    required this.state,
    required this.onTap,
    super.key,
  }) : radius = TreeLayout.focusRadius,
       width = focusLabelWidth;

  final TheoryNode node;
  final NodeState state;
  final VoidCallback onTap;

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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isDim() =>
      state == NodeState.unreachable || state == NodeState.tooExpensive;

  String _stateLabel() {
    return switch (state) {
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
                const Text(
                  'Inhalt folgt',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    color: Palette.textOnDarkDim,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'node_card.dart';
import 'node_icon.dart';
import 'tree_layout.dart';

/// Ein Knoten im gezeichneten Baum: ein Kreis mit Symbol.
///
/// Der Name steht **unter** dem Kreis und nicht darin. Titel wie
/// „Stress ist ein Werkzeug mit Verfallsdatum" passen in keinen Kreis,
/// und ein Baum aus abgeschnittenen Wörtern ist unlesbar.
class NodeBubble extends StatelessWidget {
  const NodeBubble({
    required this.node,
    required this.state,
    required this.onTap,
    super.key,
  });

  final TheoryNode node;
  final NodeState state;
  final VoidCallback onTap;

  static const double radius = TreeLayout.nodeRadius;
  static const double labelWidth = 108;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final gefuellt = state == NodeState.passed;

    return SizedBox(
      width: labelWidth,
      child: Semantics(
        button: true,
        label: '${node.name}, ${_stateLabel()}',
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
                      width: node.isRoot ? 2.5 : 1.8,
                    ),
                  ),
                  child: Icon(
                    iconForNode(node.iconId),
                    size: node.isRoot ? 26 : 22,
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
                    fontSize: 10,
                    height: 1.2,
                    color: _isDim() ? Palette.muted : Colors.white,
                    fontWeight: node.isRoot ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
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
      NodeState.passed => Palette.success,
      NodeState.open => Palette.accent,
      NodeState.affordable => Palette.gold,
      NodeState.tooExpensive || NodeState.unreachable => Palette.muted,
    };
  }
}

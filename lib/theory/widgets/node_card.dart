import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'node_icon.dart';

/// In welchem Zustand ein Knoten für den Spieler ist.
///
/// Vier Zustände, und der Unterschied zwischen den letzten beiden ist
/// der wichtige: *zu teuer* geht später von selbst weg, *unerreichbar*
/// verlangt, vorher etwas anderes zu öffnen. Sähen beide gleich aus,
/// wüsste niemand, ob Warten hilft.
enum NodeState { passed, open, affordable, tooExpensive, unreachable }

/// Eine Karte für einen Theorieknoten.
class NodeCard extends StatelessWidget {
  const NodeCard({
    required this.node,
    required this.state,
    required this.onTap,
    super.key,
  });

  final TheoryNode node;
  final NodeState state;

  /// Null macht die Karte stumpf — bei [NodeState.unreachable] und
  /// [NodeState.tooExpensive] gibt es nichts zu tun.
  final VoidCallback? onTap;

  bool get _isReachable =>
      state != NodeState.unreachable && state != NodeState.tooExpensive;

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Material(
      color: state == NodeState.passed
          ? Palette.surfaceRaised
          : Palette.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconForNode(node.iconId), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      node.name,
                      style: TextStyle(
                        color: _isReachable ? Colors.white : Palette.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.summary,
                      style: const TextStyle(
                        color: Palette.textDim,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Badge(state: state, node: node),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _Badge extends StatelessWidget {
  const _Badge({required this.state, required this.node});

  final NodeState state;
  final TheoryNode node;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      NodeState.passed => ('Bestanden', Palette.success),
      NodeState.open => ('Offen — Seite lesen', Palette.accent),
      NodeState.affordable => (
        'Öffnen für ${_points(node.cost)}',
        Palette.gold,
      ),
      NodeState.tooExpensive => (
        'Braucht ${_points(node.cost)}',
        Palette.muted,
      ),
      NodeState.unreachable => ('Erst den Knoten davor', Palette.muted),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (state == NodeState.affordable)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.lock_open_rounded, size: 14, color: Palette.gold),
          ),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static String _points(int cost) {
    return cost == 1 ? '1 Punkt' : '$cost Punkte';
  }
}

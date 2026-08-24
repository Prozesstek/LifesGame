import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'node_card.dart';
import 'node_icon.dart';

/// Was passieren soll, wenn im Detailblatt getippt wird.
enum NodeAction { read, open }

/// Das Detailblatt zu einem Knoten.
///
/// Es steht an der Stelle des Panels aus dem Vorbild: Name, was der
/// Knoten bringt, was er kostet, und **eine** Handlung. Mehr als eine
/// wäre auf einem Handy eine Rateaufgabe.
class NodeSheet extends StatelessWidget {
  const NodeSheet({
    required this.node,
    required this.state,
    required this.availablePoints,
    super.key,
  });

  final TheoryNode node;
  final NodeState state;
  final int availablePoints;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(iconForNode(node.iconId), color: _color(), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              node.summary,
              style: const TextStyle(
                color: Palette.textDim,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (node.unlocksAbility != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.auto_awesome, size: 15, color: Palette.gold),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Dieser Knoten bringt eine Fähigkeit mit',
                      style: TextStyle(color: Palette.gold, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            _action(context),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context) {
    switch (state) {
      case NodeState.passed:
        return _button(
          context,
          label: 'Seite noch einmal lesen',
          icon: Icons.menu_book_outlined,
          result: NodeAction.read,
        );
      case NodeState.open:
        return _button(
          context,
          label: 'Seite lesen',
          icon: Icons.menu_book_outlined,
          result: NodeAction.read,
        );
      case NodeState.affordable:
        return _button(
          context,
          label: node.cost == 1
              ? 'Für einen Punkt öffnen'
              : 'Für ${node.cost} Punkte öffnen',
          icon: Icons.lock_open_rounded,
          result: NodeAction.open,
        );
      case NodeState.tooExpensive:
        return _hint(
          'Du brauchst ${node.cost == 1 ? "einen Punkt" : "${node.cost} Punkte"}'
          ' — du hast $availablePoints. Jeder Levelaufstieg gibt zwei.',
        );
      case NodeState.unreachable:
        return _hint(
          'Erst einen Knoten davor öffnen. Einer der beiden genügt, wenn '
          'dieser zwei Gebiete verbindet.',
        );
    }
  }

  Widget _button(
    BuildContext context, {
    required String label,
    required IconData icon,
    required NodeAction result,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(result),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _hint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Palette.muted,
          fontSize: 13,
          height: 1.35,
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

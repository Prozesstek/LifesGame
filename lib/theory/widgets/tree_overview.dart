import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/druck.dart';
import '../../ui/holz.dart';
import '../../ui/palette.dart';
import 'node_bubble.dart';
import 'node_icon.dart';
import 'node_state.dart';

/// Der Überblick über dem Baum (ADR-0056): vier Gebiete mit ihrem Stand,
/// antippen springt hin.
///
/// **Ersetzt die vier Punkte.** Die sagten, auf welcher Seite man ist,
/// aber nicht, wie weit man dort ist — dafür musste man jedes Gebiet
/// einzeln ansehen.
class AreaProgressRow extends StatelessWidget {
  const AreaProgressRow({
    required this.areas,
    required this.current,
    required this.onSelect,
    super.key,
  });

  /// Je Gebiet der Knoten und sein Stand, mit sich selbst gezählt.
  final List<(TheoryNode, ({int passed, int total}))> areas;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < areas.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _AreaTile(
              node: areas[i].$1,
              stand: areas[i].$2,
              selected: i == current,
              onTap: () => onSelect(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.node,
    required this.stand,
    required this.selected,
    required this.onTap,
  });

  final TheoryNode node;
  final ({int passed, int total}) stand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final anteil = stand.total == 0 ? 0.0 : stand.passed / stand.total;
    final fertig = stand.total > 0 && stand.passed >= stand.total;
    final farbe = selected ? Palette.accentOnDark : Palette.textOnDarkDim;

    return Semantics(
      button: true,
      selected: selected,
      label: '${node.name}, ${stand.passed} von ${stand.total}',
      child: Druck(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? Palette.accentOnDark
                    : Palette.textOnDarkDim.withValues(alpha: 0.3),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(iconForNode(node.iconId), size: 14, color: farbe),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${stand.passed}/${stand.total}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: fertig ? Palette.goldOnDark : farbe,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: anteil,
                    minHeight: 4,
                    backgroundColor: Palette.textOnDarkDim.withValues(
                      alpha: 0.25,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fertig ? Palette.goldOnDark : Palette.successOnDark,
                    ),
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

/// „Weiterlesen: …“ — die Seite, die offen und noch nicht gelesen ist,
/// einen Tipp entfernt (ADR-0056).
///
/// Der Baum bleibt eine Wahl; wer nicht wählen will, muss es nicht.
class ContinueReadingTile extends StatelessWidget {
  const ContinueReadingTile({
    required this.node,
    required this.onTap,
    super.key,
  });

  final TheoryNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Weiterlesen: ${node.name}',
      child: Druck(
        child: Material(
          color: Palette.accentOnDark.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: Palette.accentOnDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          const TextSpan(
                            text: 'Weiterlesen: ',
                            style: TextStyle(color: Palette.textOnDarkDim),
                          ),
                          TextSpan(
                            text: node.name,
                            style: const TextStyle(
                              color: Palette.textOnDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  // Nicht der Pfeil des Gebietswechsels: Dieser führt in
                  // eine Seite, jener zum nächsten Gebiet.
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Palette.accentOnDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Legende: was die Zeichen an den Knoten bedeuten (ADR-0056).
///
/// Zeigt **dieselben** Zeichen wie der Baum ([NodeStateBadge]) — eine
/// zweite Zeichnung davon liefe irgendwann auseinander.
Future<void> showTreeLegend(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (_) => const HolzBlatt(child: _Legende()),
  );
}

class _Legende extends StatelessWidget {
  const _Legende();

  static const List<(NodeState, bool, String)>
  _eintraege = <(NodeState, bool, String)>[
    (NodeState.passed, false, 'Gelesen und bestanden'),
    (NodeState.passed, true, 'Gelesen — und alles darunter auch'),
    (NodeState.open, false, 'Geöffnet, noch zu lesen'),
    (NodeState.affordable, false, 'Für einen Punkt zu öffnen'),
    (
      NodeState.tooExpensive,
      false,
      'Erreichbar, aber noch kein Punkt frei — kommt mit dem nächsten Level',
    ),
    (NodeState.unreachable, false, 'Erst etwas darunter öffnen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Was die Zeichen bedeuten',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 12),
          for (final (state, fertig, text) in _eintraege)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Palette.background,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: NodeStateBadge(
                        state: state,
                        fertig: fertig,
                        cost: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 13, color: Palette.text),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Der Ring um einen Knoten zeigt, wie viel darunter geschafft ist '
            '— „2 / 5“ steht unter dem Namen.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Palette.textDim),
          ),
        ],
      ),
    );
  }
}

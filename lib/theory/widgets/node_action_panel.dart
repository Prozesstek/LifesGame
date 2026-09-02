import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'node_state.dart';

/// Was mit dem Startknoten geschehen soll.
enum NodeAction { read, open }

/// Der Handlungsknopf **über** dem Startknoten (ADR-0026, Punkt 4).
///
/// **Antippen und Öffnen sind zwei Dinge, weil ein Knoten zwei Dinge
/// ist:** ein Ort im Baum und eine Seite zum Lesen. Lägen beide auf
/// derselben Geste, gäbe man beim Erkunden versehentlich Punkte aus.
/// Deshalb zieht ein Druck auf ein Kind es nur herein — geöffnet wird
/// hier, oder mit einem zweiten Druck auf den Knoten selbst.
///
/// **Er ersetzt das alte Detailblatt** (`node_sheet.dart`). Ein Blatt von
/// unten war die richtige Antwort, solange alle vierundzwanzig Knoten auf
/// einer Fläche lagen und ein angetippter Knoten sonst nirgends Platz
/// hatte, sich zu erklären. Jetzt hat er den Platz, und ein Blatt wäre
/// eine Ebene zu viel.
///
/// Bei *zu teuer* und *unerreichbar* steht hier ein Satz statt eines
/// Knopfes. Ein grauer Knopf, der nichts tut, ist die schlechtere Antwort
/// auf „warum geht das nicht".
class NodeActionPanel extends StatelessWidget {
  const NodeActionPanel({
    required this.node,
    required this.state,
    required this.availablePoints,
    required this.onAction,
    super.key,
  });

  final TheoryNode node;
  final NodeState state;
  final int availablePoints;
  final ValueChanged<NodeAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.surfaceRaised),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: Text(
              node.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Palette.textDim,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _action(),
        ],
      ),
    );
  }

  Widget _action() {
    switch (state) {
      case NodeState.passed:
        // **Kein Knopf mehr.** Eine bestandene Seite hat nichts offen;
        // ein Knopf dort verspricht eine Handlung, wo es keine gibt --
        // und beim Oeffnen eines Gebiets steht er jedes Mal unter dem
        // Startknoten, den man laengst gelesen hat.
        //
        // Nachlesen geht weiter: ein Druck auf den Knoten selbst. Der
        // Satz sagt es, damit der Weg nicht verschwindet.
        return _passed();
      case NodeState.open:
        return _button(
          label: 'Seite lesen',
          icon: Icons.menu_book_outlined,
          result: NodeAction.read,
        );
      case NodeState.affordable:
        return _button(
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

  /// **Die Zeile ist selbst der Knopf.**
  ///
  /// Sie muss es sein: Seit der Druck auf den Knoten das Blatt nur noch
  /// auf- und zuklappt, gaebe es sonst gar keinen Weg mehr zurueck in
  /// eine bestandene Seite. Ein Satz, der zum Antippen auffordert und
  /// nicht antippbar ist, waere die schlechteste Fassung davon.
  Widget _passed() {
    return InkWell(
      onTap: () => onAction(NodeAction.read),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.check_circle, size: 15, color: Palette.success),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Bestanden — zum Nachlesen antippen',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Palette.muted, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required NodeAction result,
  }) {
    return FilledButton.icon(
      onPressed: () => onAction(result),
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _hint(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Palette.muted, fontSize: 12, height: 1.35),
    );
  }
}

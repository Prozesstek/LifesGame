import 'package:flutter/material.dart';
import 'package:theory/theory.dart';

import '../../ui/palette.dart';
import 'node_action_panel.dart';
import 'node_bubble.dart';
import 'node_icon.dart';
import 'node_state.dart';
import 'tree_layout.dart';
import 'tree_painter.dart';

/// Ein Gebiet des Skillbaums als Zeichenfläche (ADR-0026).
///
/// Unten der Knoten, an dem man gerade steht, darüber genau **eine**
/// Ebene seiner Kinder, darunter der Elternknoten als Rückweg.
///
/// **Kein `InteractiveViewer` mehr.** Solange das Bild frei verschiebbar
/// war, war ein Wisch nach links zweideutig: Bild bewegen oder Gebiet
/// wechseln? Die Geste gehört jetzt dem Gebietswechsel — senkrecht wird
/// gescrollt, waagerecht wird gewechselt.
///
/// Der Bildschirm hält den Weg nicht selbst: [path] kommt von außen,
/// damit die Zurück-Geste des Geräts ihn kennt und ein Gebietswechsel
/// ihn nicht vergisst.
class TreeView extends StatelessWidget {
  const TreeView({
    required this.graph,
    required this.progress,
    required this.availablePoints,
    required this.path,
    required this.panelOpen,
    required this.onTogglePanel,
    required this.onEnter,
    required this.onLeave,
    required this.onAction,
    this.onPrevArea,
    this.onNextArea,
    super.key,
  });

  final TheoryGraph graph;
  final TheoryProgress progress;
  final int availablePoints;

  /// Der Weg von der Wurzel bis zum Startknoten. Nie leer.
  final List<String> path;

  /// Ob das Blatt über dem Startknoten aufgeklappt ist.
  ///
  /// **Geschlossen ist der Standard.** Wer ein Gebiet betritt, hat noch
  /// nichts gewählt — ein Knopf über der Wurzel stünde dort jedes Mal,
  /// ohne dass ihn jemand gerufen hätte. Wer dagegen ein Kind
  /// hereinzieht, hat es damit gewählt; dann steht er da.
  final bool panelOpen;

  /// Auf- und zuklappen — ein Druck auf den Startknoten.
  final VoidCallback onTogglePanel;

  /// Ein Kind hereinziehen — es wird der neue Startknoten.
  final ValueChanged<TheoryNode> onEnter;

  /// Eine Ebene zurück.
  final VoidCallback onLeave;

  final void Function(TheoryNode node, NodeAction action) onAction;

  /// Ins Gebiet links bzw. rechts wechseln. Null heisst: dort ist keins.
  ///
  /// **Neben dem Wischen, nicht statt dessen.** Eine Geste, die niemand
  /// vermutet, existiert nicht -- die Punkte in der Kopfzeile sagen, dass
  /// es vier Gebiete gibt, die Pfeile sagen, wie man hinkommt.
  final VoidCallback? onPrevArea;
  final VoidCallback? onNextArea;

  String get _focusId => path.last;
  String? get _parentId => path.length > 1 ? path[path.length - 2] : null;

  @override
  Widget build(BuildContext context) {
    final focus = graph.nodeById(_focusId);
    if (focus == null) return const SizedBox.shrink();

    final parent = _parentId == null ? null : graph.nodeById(_parentId!);

    return Column(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layout = TreeLayout.of(
                graph,
                _focusId,
                width: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              );

              // `reverse` setzt den Anfang ans untere Ende. Der
              // Startknoten sitzt dort — ohne das begänne ein tiefer
              // Baum über ihm, also an der Stelle, an der noch nichts
              // passiert ist.
              return SingleChildScrollView(
                reverse: true,
                child: SizedBox(
                  width: layout.size.width,
                  height: layout.size.height,
                  child: _canvas(focus, layout),
                ),
              );
            },
          ),
        ),
        if (parent != null) _ParentStrip(node: parent, onTap: onLeave),
      ],
    );
  }

  Widget _canvas(TheoryNode focus, TreeLayout layout) {
    final offen = progress.openIdsIn(graph);
    final focusState = nodeStateFor(focus, graph, progress, availablePoints);
    final focusY = layout[_focusId]!.dy;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: TreePainter(graph: graph, layout: layout, openIds: offen),
          ),
        ),
        for (final id in layout.rows.expand((r) => r))
          if (graph.nodeById(id) case final TheoryNode kind)
            Positioned(
              left: layout[id]!.dx - NodeBubble.labelWidth / 2,
              top: layout[id]!.dy - TreeLayout.nodeRadius,
              child: NodeBubble(
                node: kind,
                state: nodeStateFor(kind, graph, progress, availablePoints),
                onTap: () => _tapChild(kind),
              ),
            ),
        // Der Knopf sitzt über dem Startknoten, nicht in einer festen
        // Leiste am Bildschirmrand: Er gehört zu genau diesem Knoten.
        //
        // Die Höhe ist gedeckelt, und das ist keine Kosmetik: Ohne den
        // Deckel wuchs er in die Kinderreihe hinein und schluckte deren
        // Drücke — sichtbar war nur, dass Antippen nichts tut.
        if (panelOpen)
          Positioned(
            left: 20,
            right: 20,
            bottom:
                layout.size.height -
                focusY +
                TreeLayout.focusRadius +
                TreeLayout.panelGap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: TreeLayout.panelMaxHeight,
              ),
              child: NodeActionPanel(
                node: focus,
                state: focusState,
                availablePoints: availablePoints,
                onAction: (action) => onAction(focus, action),
              ),
            ),
          ),
        Positioned(
          left: layout[_focusId]!.dx - NodeBubble.focusLabelWidth / 2,
          top: focusY - TreeLayout.focusRadius,
          child: NodeBubble.focus(
            node: focus,
            state: focusState,
            onTap: onTogglePanel,
          ),
        ),
        // **Auf Hoehe des Startknotens, und das ist gerechnet.** Er ist
        // nur `focusLabelWidth` breit und sitzt mittig; links und rechts
        // von ihm ist die Flaeche frei. Auf Hoehe der Kinderreihen waere
        // sie es nicht -- dort steht das aeusserste Kind bis an den Rand.
        _AreaArrow(
          icon: Icons.chevron_left_rounded,
          onTap: onPrevArea,
          left: 2,
          top: focusY - _AreaArrow.size / 2,
        ),
        _AreaArrow(
          icon: Icons.chevron_right_rounded,
          onTap: onNextArea,
          right: 2,
          top: focusY - _AreaArrow.size / 2,
        ),
      ],
    );
  }

  /// Ein Kind antippen zieht es herein — **auch ein Blatt**.
  ///
  /// Und es klappt das Blatt darüber auf: Wer ein Kind antippt, hat es
  /// damit gewählt. Nur der Einstieg in ein Gebiet ist ruhig.
  ///
  /// ADR-0026 wollte ein Blatt ursprünglich sofort öffnen lassen, weil es
  /// nichts hereinzuziehen hat. Gegen den echten Baum trägt das nicht:
  /// **zwanzig der vierundzwanzig Knoten sind Blätter**, es gibt keine
  /// dritte Ebene. Ein Druck hätte damit fast überall sofort einen
  /// Theoriepunkt gekostet — genau das Versehen, gegen das Punkt 4
  /// geschrieben wurde. Die Überschrift schlägt den Sonderfall
  /// (Nachtrag vom 01.09.2026 in ADR-0026).
  ///
  /// Ein Blatt zeigt danach eine leere Ebene über sich. Das ist keine
  /// Lücke, sondern die Auskunft: hier geht es nicht weiter.
  void _tapChild(TheoryNode node) => onEnter(node);
}

/// Ein Pfeil zum Gebietswechsel, neben dem Startknoten.
///
/// Am Rand der Reihe gibt es kein Gebiet mehr; dann steht der Pfeil
/// blass da, statt zu verschwinden. Ein Knopf, der kommt und geht,
/// laesst die Leiste zappeln -- und man sieht nicht mehr, wo man ist.
class _AreaArrow extends StatelessWidget {
  const _AreaArrow({
    required this.icon,
    required this.onTap,
    required this.top,
    this.left,
    this.right,
  });

  static const double size = 44;

  final IconData icon;
  final VoidCallback? onTap;
  final double top;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Opacity(
        opacity: onTap == null ? 0.25 : 1,
        child: Material(
          color: Palette.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 26, color: Palette.textDim),
            ),
          ),
        ),
      ),
    );
  }
}

/// Der Elternknoten als flache Fläche unter dem Startknoten.
///
/// **Zurück ist immer sichtbar** (ADR-0026, Punkt 5). Flach und nicht als
/// Blase, weil er kein Ziel ist, sondern ein Weg — sähe er aus wie ein
/// Knoten, wäre unklar, warum ein Druck darauf etwas anderes tut.
class _ParentStrip extends StatelessWidget {
  const _ParentStrip({required this.node, required this.onTap});

  final TheoryNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Palette.muted,
              ),
              const SizedBox(width: 8),
              Icon(iconForNode(node.iconId), size: 18, color: Palette.textDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zurück zu ${node.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Palette.textDim,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

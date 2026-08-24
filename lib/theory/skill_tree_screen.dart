import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../ui/palette.dart';
import 'branch_screen.dart';
import 'lesson_screen.dart';
import 'theory_controller.dart';
import 'widgets/node_bubble.dart';
import 'widgets/node_card.dart';
import 'widgets/node_sheet.dart';
import 'widgets/points_chip.dart';
import 'widgets/tree_layout.dart';
import 'widgets/tree_painter.dart';

/// Der Skillbaum als gezeichneter Graph (Issue #16, ADR-0019).
///
/// **Warum gezeichnet und nicht als Liste.** Der Issue verlangt einen
/// „richtigen Skill-Tree" und zeigt als Vorbild einen Graphen mit
/// Verbindungslinien. Eine Liste kann die entscheidende Aussage nicht
/// treffen: dass *Stress* an Körper **und** Geist hängt. Die Linien sind
/// der Inhalt, nicht die Verzierung.
///
/// Die Fläche ist breiter als ein Handy — deshalb `InteractiveViewer`
/// mit Verschieben und Zoomen. Das Handbuch steht darüber und bleibt
/// eine Liste: Es ist kein Graph, sondern eine Reihenfolge (ADR-0018).
class SkillTreeScreen extends ConsumerStatefulWidget {
  const SkillTreeScreen({super.key});

  @override
  ConsumerState<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends ConsumerState<SkillTreeScreen> {
  final TransformationController _view = TransformationController();

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final graph = ref.watch(theoryGraphProvider);
    final progress = ref.watch(theoryProgressProvider);
    final available = ref.watch(availableTheoryPointsProvider);
    final handbook = ref.watch(handbookProvider);
    final passed = ref.watch(passedPagesProvider);
    final total = ref.watch(totalPagesProvider);

    final layout = TreeLayout.of(graph, theoryRootIds);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Theorie'),
        backgroundColor: Palette.background,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: PointsChip(points: available)),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _Header(
            passed: passed,
            total: total,
            available: available,
            handbookDone: progress.isBranchComplete(handbook),
            onHandbook: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BranchScreen(branch: handbook),
              ),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              transformationController: _view,
              constrained: false,
              minScale: 0.4,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: layout.size.width,
                height: layout.size.height,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TreePainter(
                          graph: graph,
                          layout: layout,
                          openIds: progress.openIdsIn(graph),
                        ),
                      ),
                    ),
                    for (final entry in layout.bandTops.entries)
                      Positioned(
                        left: 12,
                        top: entry.value,
                        child: _BandLabel(
                          text: graph.nodeById(entry.key)?.name ?? entry.key,
                        ),
                      ),
                    for (final node in graph.nodes)
                      if (layout[node.id] case final Offset at)
                        Positioned(
                          left: at.dx - NodeBubble.labelWidth / 2,
                          top: at.dy - TreeLayout.nodeRadius,
                          child: NodeBubble(
                            node: node,
                            state: stateOf(node, graph, progress, available),
                            onTap: () => _tap(node, graph, progress, available),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// In welchem Zustand ein Knoten ist.
  ///
  /// **Erreichbarkeit und Preis sind zwei verschiedene Absagen.** Die
  /// eine geht mit dem nächsten Levelaufstieg weg, die andere nicht —
  /// sähen sie gleich aus, wüsste niemand, ob Warten hilft.
  static NodeState stateOf(
    TheoryNode node,
    TheoryGraph graph,
    TheoryProgress progress,
    int available,
  ) {
    if (progress.isPassed(node.lesson.id)) return NodeState.passed;
    if (progress.isNodeOpened(node.id, graph)) return NodeState.open;
    if (!graph.canOpen(node.id, progress.openIdsIn(graph))) {
      return NodeState.unreachable;
    }
    return node.cost <= available
        ? NodeState.affordable
        : NodeState.tooExpensive;
  }

  Future<void> _tap(
    TheoryNode node,
    TheoryGraph graph,
    TheoryProgress progress,
    int available,
  ) async {
    final state = stateOf(node, graph, progress, available);

    final action = await showModalBottomSheet<NodeAction>(
      context: context,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          NodeSheet(node: node, state: state, availablePoints: available),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case NodeAction.read:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonScreen(lesson: node.lesson),
          ),
        );
      case NodeAction.open:
        ref
            .read(theoryProgressProvider.notifier)
            .openNode(node.id, availablePoints: available);
    }
  }
}

class _BandLabel extends StatelessWidget {
  const _BandLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Palette.muted,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.passed,
    required this.total,
    required this.available,
    required this.handbookDone,
    required this.onHandbook,
  });

  final int passed;
  final int total;
  final int available;
  final bool handbookDone;
  final VoidCallback onHandbook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: <Widget>[
          Material(
            color: Palette.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onHandbook,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Icon(
                      handbookDone
                          ? Icons.check_circle
                          : Icons.menu_book_outlined,
                      size: 20,
                      color: handbookDone ? Palette.success : Palette.accent,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Das Handbuch',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      handbookDone ? 'durch' : 'offen',
                      style: TextStyle(
                        color: handbookDone ? Palette.success : Palette.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Palette.muted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Beide Hälften müssen schrumpfen dürfen. Bei großer Schrift
          // — und im Widget-Test, wo jede Glyphe quadratisch ist —
          // passen die vollen Sätze sonst nicht nebeneinander.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  '$passed von $total Seiten bestanden',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Palette.textDim, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  available > 0
                      ? '$available Punkte frei'
                      : 'Aufstieg gibt 2 Punkte',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: available > 0 ? Palette.gold : Palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

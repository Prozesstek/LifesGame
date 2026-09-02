import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theory/theory.dart';

import '../ui/palette.dart';
import 'branch_screen.dart';
import 'lesson_screen.dart';
import 'theory_controller.dart';
import 'widgets/node_action_panel.dart';
import 'widgets/points_chip.dart';
import 'widgets/tree_view.dart';

/// Der Skillbaum: ein Bildschirm je Gebiet, waagerecht zu wischen
/// (ADR-0026).
///
/// **Warum nicht mehr alles auf einer Fläche.** Bis dahin lagen die vier
/// Gebiete als Bänder untereinander, verschiebbar und zoombar. Das war
/// bei vierundzwanzig Knoten bereits eng, und jede weitere Ebene hätte es
/// schlechter gemacht, nicht besser. Ein Handy hat Höhe, keine Breite —
/// ein Gebiet je Bildschirm ist dieselbe Einsicht wie in ADR-0019, nur zu
/// Ende geführt.
///
/// **Vorher steht das Handbuch** (ADR-0025). Solange es offen ist, ist es
/// dieser Bildschirm: Erst verstehen, wie das Spiel gemeint ist, dann den
/// Stoff lernen. Aus der schmalen Textzeile über einem unbenutzbaren Baum
/// wird damit der Bildschirm selbst.
class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(handbookDoneProvider)) {
      return BranchScreen(branch: ref.watch(handbookProvider));
    }
    return const _AreaPager();
  }
}

/// Die vier Gebiete nebeneinander.
///
/// **Der Weg je Gebiet liegt hier und nicht in [TreeView].** Zwei Gründe:
/// Die Zurück-Geste des Geräts muss ihn kennen, und ein Gebietswechsel
/// soll ihn nicht vergessen — wer in *Körper* drei Ebenen tief steht,
/// nach *Geist* wischt und zurückkommt, steht wieder dort.
class _AreaPager extends ConsumerStatefulWidget {
  const _AreaPager();

  @override
  ConsumerState<_AreaPager> createState() => _AreaPagerState();
}

class _AreaPagerState extends ConsumerState<_AreaPager> {
  final PageController _pages = PageController();
  final Map<String, List<String>> _paths = <String, List<String>>{
    for (final id in theoryRootIds) id: <String>[id],
  };

  /// Ob das Blatt über dem Startknoten offen ist, je Gebiet.
  ///
  /// **Startet geschlossen.** Ein Gebiet zu betreten ist keine Wahl —
  /// erst ein Druck auf einen Knoten ist eine.
  final Map<String, bool> _panelOpen = <String, bool>{
    for (final id in theoryRootIds) id: false,
  };

  int _current = 0;

  String get _areaId => theoryRootIds[_current];
  List<String> get _path => _paths[_areaId]!;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final graph = ref.watch(theoryGraphProvider);
    final progress = ref.watch(theoryProgressProvider);
    final available = ref.watch(availableTheoryPointsProvider);
    final passed = ref.watch(passedPagesProvider);
    final total = ref.watch(totalPagesProvider);

    return PopScope(
      // Steht der Spieler tief im Baum, geht die Zurück-Geste eine Ebene
      // zurück statt aus der Theorie heraus. Sonst verlöre ein Druck den
      // ganzen Weg — und der Weg ist hier die Navigation.
      canPop: _path.length == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
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
              area: graph.nodeById(_areaId),
              areaPassed: _passedIn(graph, progress, _areaId),
              areaTotal: graph.descendantsOf(_areaId, includeSelf: true).length,
              passed: passed,
              total: total,
              areaIndex: _current,
              areaCount: theoryRootIds.length,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: theoryRootIds.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, i) {
                  final id = theoryRootIds[i];

                  return TreeView(
                    graph: graph,
                    progress: progress,
                    availablePoints: available,
                    path: _paths[id]!,
                    panelOpen: _panelOpen[id]!,
                    onTogglePanel: () =>
                        setState(() => _panelOpen[id] = !_panelOpen[id]!),
                    onEnter: (node) => setState(() {
                      _paths[id]!.add(node.id);
                      _panelOpen[id] = true;
                    }),
                    onLeave: _leave,
                    onAction: _act,
                    onPrevArea: i > 0 ? () => _goToArea(i - 1) : null,
                    onNextArea: i < theoryRootIds.length - 1
                        ? () => _goToArea(i + 1)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wie viele Seiten eines Gebiets bestanden sind.
  ///
  /// Ein Knoten mit zwei Eltern zählt in **beiden** Gebieten mit — das
  /// ist keine Doppelzählung, sondern die Aussage des Graphen: *Stress*
  /// gehört zu Körper und zu Geist.
  int _passedIn(TheoryGraph graph, TheoryProgress progress, String areaId) {
    return graph
        .descendantsOf(areaId, includeSelf: true)
        .where((n) => progress.isPassed(n.lesson.id))
        .length;
  }

  /// Zum Gebiet [index] wechseln.
  ///
  /// Animiert und nicht gesprungen: Der Wisch bewegt die Seiten, und ein
  /// Pfeil, der sie stattdessen austauschte, saehe aus wie ein anderer
  /// Bildschirm statt wie dasselbe Regal einen Schritt weiter.
  void _goToArea(int index) {
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _leave() {
    if (_path.length == 1) return;
    setState(() {
      _paths[_areaId]!.removeLast();
      // Zurückgehen ist kein Wählen. Der Knoten, auf dem man landet,
      // war eben noch der Weg dorthin -- er soll nicht so aussehen, als
      // stünde jetzt eine Entscheidung an.
      _panelOpen[_areaId] = false;
    });
  }

  Future<void> _act(TheoryNode node, NodeAction action) async {
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
            .openNode(
              node.id,
              availablePoints: ref.read(availableTheoryPointsProvider),
            );
    }
  }
}

/// Fortschritt des Gebiets groß, Gesamtfortschritt klein daneben
/// (ADR-0026, Punkt 6).
///
/// Die freien Punkte stehen nicht hier, sondern als [PointsChip] in der
/// Leiste darüber — sie gelten für alle vier Gebiete und wären hier eine
/// Zahl, die beim Wischen mitwandert, ohne sich zu ändern.
class _Header extends StatelessWidget {
  const _Header({
    required this.area,
    required this.areaPassed,
    required this.areaTotal,
    required this.passed,
    required this.total,
    required this.areaIndex,
    required this.areaCount,
  });

  final TheoryNode? area;
  final int areaPassed;
  final int areaTotal;
  final int passed;
  final int total;
  final int areaIndex;
  final int areaCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Beide Hälften müssen schrumpfen dürfen. Bei großer Schrift —
          // und im Widget-Test, wo jede Glyphe quadratisch ist — passen
          // die vollen Sätze sonst nicht nebeneinander.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: Text(
                  '$areaPassed von $areaTotal',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'gesamt $passed von $total',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Palette.muted, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  (area?.name ?? '').toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Palette.accent,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Dots(index: areaIndex, count: areaCount),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vier Punkte für vier Gebiete.
///
/// Ohne sie wäre nicht zu sehen, dass es überhaupt etwas zum Wischen
/// gibt — eine Geste, die niemand vermutet, existiert nicht.
class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              width: i == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? Palette.accent : Palette.muted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

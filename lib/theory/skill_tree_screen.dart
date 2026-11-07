import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/habits.dart';
import 'package:theory/theory.dart';

import '../home/erster_start.dart';
import '../home/erster_start_provider.dart';
import '../mentor/mentor.dart';
import '../mentor/mentor_kasten.dart';
import '../mentor/scheinwerfer.dart';
import '../mentor/zeigefinger.dart';
import '../skills/gebiet_farbe.dart';
import '../skills/skills.dart';
import '../skills/skills_provider.dart';
import '../skills/widgets/skill_abzeichen.dart';
import '../ui/der_reihe_nach.dart';
import '../ui/druck.dart';
import '../ui/on_dark.dart';
import '../ui/palette.dart';
import 'lesson_screen.dart';
import 'theory_controller.dart';
import 'vorschlag_flow.dart';
import 'widgets/bibliothek.dart';
import 'widgets/node_action_panel.dart';
import 'widgets/points_chip.dart';
import 'widgets/talentpunkt_einfuehrung.dart';
import 'widgets/tree_overview.dart';
import 'widgets/tree_view.dart';
import '../ui/aufstieg.dart';
import 'widgets/review_section.dart';
import '../ui/gehrung.dart';

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
/// **Der Baum ist immer offen** (ADR-0070). Bis dahin stand das Handbuch
/// davor (ADR-0025); seine fünf Seiten sind jetzt Knoten unter
/// *Gewohnheiten*. Wer noch nichts gelesen hat, bekommt den Weg dorthin
/// vorgeschlagen (`TheoryProgress.suggestedStep`), muss ihn aber nicht
/// gehen.
class SkillTreeScreen extends ConsumerWidget {
  const SkillTreeScreen({super.key});

  /// „Baum selbst erkunden“ im Einstieg.
  static const Key erkundenKey = ValueKey<String>('theorie-selbst-erkunden');

  @override
  Widget build(BuildContext context, WidgetRef ref) => const _AreaPager();
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

  /// Der Platz der freien Punkte oben rechts — Ziel des Talentpunkts.
  final GlobalKey _punktePlatz = GlobalKey();

  /// Ob der Spieler den Einstieg weggelegt hat, um selbst zu suchen.
  bool _erkunden = false;

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
    // **Erst der Talentpunkt, dann die Bücher** (06.11.2026).
    final talentpunkt =
        ref.watch(ersterStartProvider).schritt == Schritt.talentpunkt;

    return RahmenOrt(
      art: RahmenArt.ranken,
      child: PopScope(
        // Steht der Spieler tief im Baum, geht die Zurück-Geste eine Ebene
        // zurück statt aus der Theorie heraus. Sonst verlöre ein Druck den
        // ganzen Weg — und der Weg ist hier die Navigation.
        canPop: _path.length == 1,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        // **Die Bibliothek dahinter** (03.11.2026): Der Baum steht in
        // dunklem, warmem Holz statt auf glattem Leder.
        child: Bibliothek(
          schleier: 0.55,
          child: TalentpunktEinfuehrung(
            aktiv: talentpunkt,
            punkte: available,
            zielKey: _punktePlatz,
            onAngekommen: () =>
                ref.read(hinweiseProvider.notifier).weiter(Hinweis.talentpunkt),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('Theorie'),
                // Wie im Kampf: Die Kopfzeile geht in die Fläche über, statt
                // als Pergamentleiste darüber zu liegen.
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Palette.textOnDark,
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    // Während der große in der Mitte steht, ist sein Platz
                    // leer — dorthin wandert er.
                    child: Center(
                      child: Opacity(
                        key: _punktePlatz,
                        opacity: talentpunkt ? 0 : 1,
                        child: PointsChip(points: available),
                      ),
                    ),
                  ),
                ],
              ),
              // Über der Rückfrage steigen Erfahrung und Gold auf, wie früher
              // auf dem Gewohnheiten-Bildschirm.
              body: AufstiegHost(
                child: MentorFlaeche(
                  ort: MentorOrt.baum,
                  // Im Einstieg steht er direkt über der Wahl, nicht oben
                  // unter der Leiste — wie auf der Startseite (ADR-0096).
                  mitKasten: talentpunkt || !_zeigtEinstieg,
                  child: Column(
                    children: <Widget>[
                      // **Die Rückfrage des Tages** (Issue #88), ausserhalb von
                      // `OnDark`: Ihre Karte ist Pergament.
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: ReviewSection(),
                      ),
                      Expanded(
                        child: OnDark(
                          child: talentpunkt
                              ? const SizedBox.expand()
                              : _zeigtEinstieg
                              ? _Einstieg(
                                  graph: graph,
                                  vorschlaege: ref.watch(
                                    einstiegVorschlaegeProvider,
                                  ),
                                  onRead: _go,
                                  onErkunden: () =>
                                      setState(() => _erkunden = true),
                                )
                              : Column(
                                  children: <Widget>[
                                    _Header(
                                      graph: graph,
                                      area: graph.nodeById(_areaId),
                                      skills: ref.watch(skillsProvider),
                                      areas:
                                          <
                                            (
                                              TheoryNode,
                                              ({int passed, int total}),
                                            )
                                          >[
                                            for (final id in theoryRootIds)
                                              if (graph.nodeById(id)
                                                  case final TheoryNode wurzel)
                                                (
                                                  wurzel,
                                                  progress.progressBelow(
                                                    id,
                                                    graph,
                                                    includeSelf: true,
                                                  ),
                                                ),
                                          ],
                                      areaIndex: _current,
                                      onSelectArea: _goToArea,
                                      // Bis zu drei, der erste wie bisher: erst im
                                      // Gebiet, das gerade offen ist, dann irgendwo,
                                      // dann der Weg der Grundlagen — danach, was zum
                                      // Gelesenen und zu den Gewohnheiten passt.
                                      vorschlaege: ref.watch(
                                        vorschlaegeProvider(_areaId),
                                      ),
                                      onRead: _go,
                                    ),
                                    Expanded(
                                      child: PageView.builder(
                                        controller: _pages,
                                        itemCount: theoryRootIds.length,
                                        onPageChanged: (i) =>
                                            setState(() => _current = i),
                                        itemBuilder: (context, i) {
                                          final id = theoryRootIds[i];

                                          return TreeView(
                                            graph: graph,
                                            progress: progress,
                                            availablePoints: available,
                                            path: _paths[id]!,
                                            panelOpen: _panelOpen[id]!,
                                            onTogglePanel: () => setState(
                                              () => _panelOpen[id] =
                                                  !_panelOpen[id]!,
                                            ),
                                            onEnter: (node) => setState(() {
                                              _paths[id]!.add(node.id);
                                              _panelOpen[id] = true;
                                            }),
                                            onLeave: _leave,
                                            onAction: _act,
                                            onPrevArea: i > 0
                                                ? () => _goToArea(i - 1)
                                                : null,
                                            onNextArea:
                                                i < theoryRootIds.length - 1
                                                ? () => _goToArea(i + 1)
                                                : null,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// **Der Einstieg** (03.11.2026): Solange die erste Seite fehlt, steht
  /// statt des Baums eine Wahl aus drei Seiten da — wer lieber selbst
  /// sucht, legt sie weg. Danach nie wieder: Der Schritt des Mentors ist
  /// dann vorbei.
  bool get _zeigtEinstieg =>
      !_erkunden &&
      ref.watch(ersterStartProvider).schritt == Schritt.ersteSeite &&
      ref.watch(einstiegVorschlaegeProvider).isNotEmpty;

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

  /// Geht einen vorgeschlagenen Schritt: öffnen, falls nötig, dann lesen.
  Future<void> _go(TheoryStep schritt) => lieseVorschlag(
    context,
    ref,
    schritt,
    bevorzugt: SkillArea.tryParse(_areaId),
  );

  Future<void> _act(TheoryNode node, NodeAction action) async {
    switch (action) {
      case NodeAction.read:
        // In der Farbe des Gebiets, aus dem man kommt — ein Vorschlag aus
        // einem anderen trägt dessen Farbe.
        final gebiet = gebietVon(
          ref.read(theoryGraphProvider),
          node.id,
          bevorzugt: SkillArea.tryParse(_areaId),
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonScreen(lesson: node.lesson, gebiet: gebiet),
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
/// (ADR-0026, Punkt 6) — darunter die vier Gebiete mit ihrem Stand und
/// „Weiterlesen“ (ADR-0056).
///
/// Ein Knoten mit zwei Eltern zählt in **beiden** Gebieten mit — das ist
/// keine Doppelzählung, sondern die Aussage des Graphen: *Stress* gehört
/// zu Körper und zu Geist.
///
/// Die freien Punkte stehen nicht hier, sondern als [PointsChip] in der
/// Leiste darüber — sie gelten für alle vier Gebiete und wären hier eine
/// Zahl, die beim Wischen mitwandert, ohne sich zu ändern.
class _Header extends StatelessWidget {
  const _Header({
    required this.graph,
    required this.area,
    required this.skills,
    required this.areas,
    required this.areaIndex,
    required this.onSelectArea,
    required this.vorschlaege,
    required this.onRead,
  });

  final TheoryGraph graph;
  final TheoryNode? area;

  /// Der Skill des Gebiets steht neben seinem Namen (ADR-0085): Was man
  /// hier liest, lässt ihn wachsen.
  final Skills skills;
  final List<(TheoryNode, ({int passed, int total}))> areas;
  final int areaIndex;
  final ValueChanged<int> onSelectArea;

  /// Was als Nächstes dran sein könnte — der Spieler muss nicht wählen,
  /// darf aber: Der erste ist der Vorschlag, die anderen sind die Wahl.
  final List<TheoryVorschlag> vorschlaege;
  final ValueChanged<TheoryStep> onRead;

  @override
  Widget build(BuildContext context) {
    final stand = areaIndex < areas.length
        ? areas[areaIndex].$2
        : (passed: 0, total: 0);
    final gebiet = SkillArea.tryParse(area?.id);
    final farbe = GebietFarbe.vonWurzel(area?.id ?? '', dunkel: true);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
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
                flex: 3,
                child: Text(
                  area?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Palette.textOnDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (gebiet != null) ...<Widget>[
                const SizedBox(width: 8),
                SkillAbzeichen(
                  area: gebiet,
                  skill: skills.of(gebiet),
                  aufDunkel: true,
                ),
              ],
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  '${stand.passed} / ${stand.total}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: farbe,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // „gesamt 17 von 59“ steht nicht mehr da: Die vier Balken
              // darunter sagen es schon, je Gebiet.
              const Spacer(),
              _LegendKnopf(farbe: farbe),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AreaProgressRow(
              areas: areas,
              current: areaIndex,
              onSelect: onSelectArea,
            ),
          ),
          for (final (i, v) in vorschlaege.indexed) ...<Widget>[
            SizedBox(height: i == 0 ? 8 : 5),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              // Auf den ersten zeigt der Mentor, solange die erste Seite
              // fehlt (ADR-0079): Er ist der kürzeste Weg zu ihr.
              child: _mitFinger(
                erster: i == 0,
                child: ContinueReadingTile(
                  node: v.node,
                  grund: v.grund,
                  farbe: switch (gebietVon(
                    graph,
                    v.node.id,
                    bevorzugt: gebiet,
                  )) {
                    final SkillArea g => GebietFarbe.leder(g),
                    null => farbe,
                  },
                  cost: v.step.needsOpening ? v.node.cost : null,
                  onTap: () => onRead(v.step),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Der erste Vorschlag liegt im Ring des Mentors, die anderen nicht. Der
/// Platz in der Liste wechselt nie, also baut sich nichts neu
/// (`gotchas.md`).
Widget _mitFinger({required bool erster, required Widget child}) {
  if (!erster) return child;
  return Zeigefinger(schritt: Schritt.ersteSeite, child: child);
}

/// Das Fragezeichen, das die Legende öffnet (ADR-0056).
///
/// **Kein `IconButton`**: Das Theme macht jeden daraus eine Holzplanke,
/// und ein Klotz neben einer Zahl liest sich als Hauptknopf.
class _LegendKnopf extends StatelessWidget {
  const _LegendKnopf({required this.farbe});

  /// Die Farbe des Gebiets, aus dem die Legende geöffnet wird.
  final Color farbe;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Was die Zeichen bedeuten',
      child: Druck(
        child: InkWell(
          onTap: () => showTreeLegend(context, farbe: farbe),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: Palette.textOnDarkDim,
            ),
          ),
        ),
      ),
    );
  }
}

/// **Der Einstieg in die Theorie** (03.11.2026): drei Seiten, je eine in
/// einer großen Zeile, mittig — und darunter der Weg in den Baum.
///
/// Frederik: „dass einem 3 Lektionen vorgeschlagen werden + die
/// Möglichkeit den Baum selber zu erkunden“. Der Baum mit vier Gebieten,
/// Balken und Legende ist für die erste Seite zu viel auf einmal.
/// **Wie die Gebiete im Einstieg heißen** (Frederik, 07.11.2026): was
/// man davon hat, nicht der Name der Wurzel. Im Baum, bei den Skills und
/// den Farben bleiben Körper, Geist, Wissenschaft und Gesellschaft — sie
/// heißen dort wie die vier Gebiete (ADR-0085). Eine Tabelle; was hier
/// fehlt, steht mit seinem Namen da.
abstract final class EinstiegNamen {
  static const Map<String, String> namen = <String, String>{
    'koerper': 'Stärker und fitter werden',
    'geist': 'Deinen Kopf verstehen',
    'wissenschaft': 'Die Welt verstehen',
    'gesellschaft': 'Besser mit Menschen',
  };

  static String? von(String knotenId) => namen[knotenId];
}

class _Einstieg extends StatelessWidget {
  const _Einstieg({
    required this.graph,
    required this.vorschlaege,
    required this.onRead,
    required this.onErkunden,
  });

  final TheoryGraph graph;
  final List<TheoryVorschlag> vorschlaege;
  final ValueChanged<TheoryStep> onRead;
  final VoidCallback onErkunden;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          // **Die ganze Wahl liegt im Licht des Mentors** (ADR-0095), nicht
          // nur die erste Zeile: Alle drei und der Baum sind gemeint.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const MentorZeile(ort: MentorOrt.baum, rand: 0),
              const SizedBox(height: 8),
              ScheinwerferLicht(
                child: Zeigefinger(
                  schritt: Schritt.ersteSeite,
                  // Kein gelber Punkt: Gemeint ist die ganze Wahl, das Licht
                  // zeigt sie (Frederik, 07.11.2026).
                  punkt: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Was interessiert dich am meisten?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Palette.textOnDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final (i, v) in vorschlaege.indexed) ...<Widget>[
                          // Der Reihe nach, nach dem Mentor (06.11.2026).
                          DerReiheNach(
                            nr: i,
                            child: ContinueReadingTile(
                              gross: true,
                              mittig: true,
                              titel: EinstiegNamen.von(v.node.id),
                              node: v.node,
                              grund: v.grund,
                              farbe: switch (gebietVon(graph, v.node.id)) {
                                final SkillArea g => GebietFarbe.leder(g),
                                null => Palette.accentOnDark,
                              },
                              cost: v.step.needsOpening ? v.node.cost : null,
                              onTap: () => onRead(v.step),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton.icon(
                            key: SkillTreeScreen.erkundenKey,
                            onPressed: onErkunden,
                            // Hell: Der Knopf steht auf Leder, nicht Pergament.
                            style: TextButton.styleFrom(
                              foregroundColor: Palette.textOnDark,
                            ),
                            icon: const Icon(
                              Icons.account_tree_outlined,
                              size: 22,
                            ),
                            label: const Text(
                              'Baum selbst erkunden',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
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

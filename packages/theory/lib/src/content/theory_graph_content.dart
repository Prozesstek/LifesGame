/// Der Theoriegraph, wie er im Spiel steht (ADR-0019).
///
/// **Vier Wurzeln, je fünf Unterknoten.** Die Wurzeln sind kostenlos —
/// der Einstieg in ein Gebiet darf nichts kosten. Jeder Unterknoten
/// kostet einen Theoriepunkt, unabhängig von der Tiefe.
///
/// **Das Handbuch steht bewusst nicht hier.** Es bleibt der Zweig
/// `habitsBranch` mit verbindlicher Reihenfolge, weil ADR-0018 den
/// Zugang zum Kampf daran hängt. Ein zweites Modell dafür wäre eine
/// zweite Wahrheit.
///
/// Zwölf der zwanzig Seiten stammen aus den alten flachen Zweigen und
/// werden hier nur neu verdrahtet — der Inhalt steht weiterhin in
/// `*_branch.dart` und wird nicht kopiert.
library;

import '../node.dart';
import '../node_graph.dart';
import 'geist_branch.dart';
import 'gesellschaft_branch.dart';
import 'koerper_branch.dart';
import 'koerper_geist_pages.dart';
import 'root_pages.dart';
import 'wissenschaft_branch.dart';
import 'wissenschaft_gesellschaft_pages.dart';

/// Zwei Knoten hängen an **zwei** Wurzeln — der Beleg dafür, dass die
/// Struktur ein Graph ist und kein Baum:
///
/// * *Stress* gehört zu Körper und zu Geist. Beides ist wahr, und sich
///   für eine Seite zu entscheiden wäre eine Lüge über den Gegenstand.
/// * *Vergleich* gehört zu Gesellschaft und zu Geist.
///
/// Zum Öffnen genügt eine der beiden Wurzeln (ADR-0019).
final TheoryGraph theoryGraph = TheoryGraph(<TheoryNode>[
  // ------------------------------------------------------------------
  // Wurzeln — kostenlos
  // ------------------------------------------------------------------
  const TheoryNode(
    id: 'koerper',
    lesson: koerperRootPage,
    iconId: 'body',
    cost: 0,
  ),
  const TheoryNode(
    id: 'geist',
    lesson: geistRootPage,
    iconId: 'mind',
    cost: 0,
  ),
  const TheoryNode(
    id: 'wissenschaft',
    lesson: wissenschaftRootPage,
    iconId: 'science',
    cost: 0,
  ),
  const TheoryNode(
    id: 'gesellschaft',
    lesson: gesellschaftRootPage,
    iconId: 'society',
    cost: 0,
  ),

  // ------------------------------------------------------------------
  // Körper
  // ------------------------------------------------------------------
  TheoryNode(
    id: 'koerper-schlaf',
    lesson: koerperBranch.lessons[0],
    iconId: 'sleep',
    parentIds: const <String>['koerper'],
    unlocksAbility: 'breath',
  ),
  TheoryNode(
    id: 'koerper-bewegung',
    lesson: koerperBranch.lessons[1],
    iconId: 'run',
    parentIds: const <String>['koerper'],
    unlocksAbility: 'heavy_attack',
  ),
  TheoryNode(
    id: 'koerper-ernaehrung',
    lesson: koerperBranch.lessons[2],
    iconId: 'food',
    parentIds: const <String>['koerper'],
    unlocksAbility: 'mend',
  ),
  const TheoryNode(
    id: 'koerper-erholung',
    lesson: erholungPage,
    iconId: 'pause',
    parentIds: <String>['koerper'],
    unlocksAbility: 'poison_strike',
  ),
  const TheoryNode(
    id: 'koerper-stress',
    lesson: stressPage,
    iconId: 'storm',
    parentIds: <String>['koerper', 'geist'],
  ),

  // ------------------------------------------------------------------
  // Geist
  // ------------------------------------------------------------------
  TheoryNode(
    id: 'geist-aufmerksamkeit',
    lesson: geistBranch.lessons[0],
    iconId: 'focus',
    parentIds: const <String>['geist'],
  ),
  TheoryNode(
    id: 'geist-gedanken',
    lesson: geistBranch.lessons[1],
    iconId: 'thought',
    parentIds: const <String>['geist'],
  ),
  TheoryNode(
    id: 'geist-unbehagen',
    lesson: geistBranch.lessons[2],
    iconId: 'endure',
    parentIds: const <String>['geist'],
  ),
  const TheoryNode(
    id: 'geist-motivation',
    lesson: motivationPage,
    iconId: 'spark',
    parentIds: <String>['geist'],
  ),
  const TheoryNode(
    id: 'geist-wiederholung',
    lesson: wiederholungPage,
    iconId: 'repeat',
    parentIds: <String>['geist'],
  ),

  // ------------------------------------------------------------------
  // Wissenschaft
  // ------------------------------------------------------------------
  TheoryNode(
    id: 'wissenschaft-quelle',
    lesson: wissenschaftBranch.lessons[0],
    iconId: 'question',
    parentIds: const <String>['wissenschaft'],
  ),
  TheoryNode(
    id: 'wissenschaft-ursache',
    lesson: wissenschaftBranch.lessons[1],
    iconId: 'link',
    parentIds: const <String>['wissenschaft'],
  ),
  TheoryNode(
    id: 'wissenschaft-selbsttest',
    lesson: wissenschaftBranch.lessons[2],
    iconId: 'flask',
    parentIds: const <String>['wissenschaft'],
  ),
  const TheoryNode(
    id: 'wissenschaft-stichprobe',
    lesson: stichprobePage,
    iconId: 'dice',
    parentIds: <String>['wissenschaft'],
  ),
  const TheoryNode(
    id: 'wissenschaft-studie',
    lesson: studieLesenPage,
    iconId: 'news',
    parentIds: <String>['wissenschaft'],
  ),

  // ------------------------------------------------------------------
  // Gesellschaft
  // ------------------------------------------------------------------
  TheoryNode(
    id: 'gesellschaft-umfeld',
    lesson: gesellschaftBranch.lessons[0],
    iconId: 'people',
    parentIds: const <String>['gesellschaft'],
  ),
  TheoryNode(
    id: 'gesellschaft-zugehoerigkeit',
    lesson: gesellschaftBranch.lessons[1],
    iconId: 'heart',
    parentIds: const <String>['gesellschaft'],
  ),
  TheoryNode(
    id: 'gesellschaft-grenzen',
    lesson: gesellschaftBranch.lessons[2],
    iconId: 'hand',
    parentIds: const <String>['gesellschaft'],
  ),
  const TheoryNode(
    id: 'gesellschaft-vergleich',
    lesson: vergleichPage,
    iconId: 'scale',
    parentIds: <String>['gesellschaft', 'geist'],
  ),
  const TheoryNode(
    id: 'gesellschaft-hilfe',
    lesson: hilfeBittenPage,
    iconId: 'ask',
    parentIds: <String>['gesellschaft'],
  ),
]);

/// Die Ids der vier Wurzeln, in Anzeigereihenfolge.
const List<String> theoryRootIds = <String>[
  'koerper',
  'geist',
  'wissenschaft',
  'gesellschaft',
];

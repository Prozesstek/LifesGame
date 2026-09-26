/// Der Theoriegraph, wie er im Spiel steht (ADR-0019, ADR-0050).
///
/// **Drei Ebenen.** Oben die vier Wurzeln, seit ADR-0051 je einen Punkt
/// wert — auch welches Gebiet man betritt, ist eine Wahl. Darunter die
/// **Zwischenebenen** aus Issue #54 — „Kraft & Muskulatur", „Beziehungen",
/// „Physik" —, jede einen Punkt und eine Einführungsseite wert. Darunter
/// die Themen. Wer die Zwischenebene nicht öffnet, kommt an ihre Themen
/// nicht heran: Die Wahl eines Gebiets ist selbst eine Entscheidung
/// (ADR-0037, Grundsatz 1).
///
/// **Die meisten Überschriften sind noch leer.** Sie stehen als
/// [TheoryPlaceholder] im Bild, grau und mit „Inhalt folgt", damit man
/// sieht, wie groß der Baum wird. Wird eine befüllt, wandert sie mit
/// derselben Id nach oben in die Knoten.
///
/// **Das Handbuch steht bewusst nicht hier.** Es bleibt der Zweig
/// `habitsBranch` mit verbindlicher Reihenfolge, weil ADR-0018 den
/// Zugang zum Kampf daran hängt. Ein zweites Modell dafür wäre eine
/// zweite Wahrheit.
///
/// Die Themen der ersten Stunde stammen aus den alten flachen Zweigen und
/// werden hier nur verdrahtet — der Inhalt steht weiterhin in
/// `*_branch.dart` und wird nicht kopiert.
library;

import '../node.dart';
import '../node_graph.dart';
import '../placeholder.dart';
import 'area_pages.dart';
import 'ausdauer_pages.dart';
import 'geist_branch.dart';
import 'gesellschaft_branch.dart';
import 'koerper_branch.dart';
import 'koerper_geist_pages.dart';
import 'kraft_pages.dart';
import 'psychologie_pages.dart';
import 'root_pages.dart';
import 'wissenschaft_branch.dart';
import 'wissenschaft_gesellschaft_pages.dart';

/// Zwei Themen hängen an **zwei** Stellen — der Beleg dafür, dass die
/// Struktur ein Graph ist und kein Baum:
///
/// * *Stress* gehört zu Schlaf & Regeneration und zu Geist.
/// * *Vergleich* gehört zu Medien & Information und zu Geist.
///
/// Zum Öffnen genügt eine der beiden Stellen (ADR-0019). Alte Stände
/// übernimmt `TheoryGraph.withSoleParents`; diese beiden schenken dabei
/// nichts, weil unklar ist, über welchen Eltern sie geöffnet wurden.
final TheoryGraph theoryGraph = TheoryGraph(
  <TheoryNode>[
    // ----------------------------------------------------------------
    // Wurzeln — ein Punkt (ADR-0051)
    // ----------------------------------------------------------------
    const TheoryNode(id: 'koerper', lesson: koerperRootPage, iconId: 'body'),
    const TheoryNode(id: 'geist', lesson: geistRootPage, iconId: 'mind'),
    const TheoryNode(
      id: 'wissenschaft',
      lesson: wissenschaftRootPage,
      iconId: 'science',
    ),
    const TheoryNode(
      id: 'gesellschaft',
      lesson: gesellschaftRootPage,
      iconId: 'society',
    ),

    // ----------------------------------------------------------------
    // Körper
    // ----------------------------------------------------------------
    const TheoryNode(
      id: 'kraft-muskulatur',
      lesson: kraftPage,
      iconId: 'strength',
      parentIds: <String>['koerper'],
    ),
    TheoryNode(
      id: 'koerper-bewegung',
      lesson: koerperBranch.lessons[1],
      iconId: 'run',
      parentIds: const <String>['kraft-muskulatur'],
      unlocksAbility: 'funkenstoss',
    ),
    const TheoryNode(
      id: 'kraft-hypertrophie',
      lesson: hypertrophiePage,
      iconId: 'muscle',
      parentIds: <String>['kraft-muskulatur'],
    ),
    const TheoryNode(
      id: 'kraft-intensitaet',
      lesson: intensitaetPage,
      iconId: 'gauge',
      parentIds: <String>['kraft-muskulatur'],
    ),
    const TheoryNode(
      id: 'kraft-trainingsplanung',
      lesson: trainingsplanungPage,
      iconId: 'plan',
      parentIds: <String>['kraft-muskulatur'],
    ),
    const TheoryNode(
      id: 'kraft-technik',
      lesson: technikPage,
      iconId: 'technique',
      parentIds: <String>['kraft-muskulatur'],
    ),
    const TheoryNode(
      id: 'kraft-muskelkater',
      lesson: muskelkaterPage,
      iconId: 'recovery',
      parentIds: <String>['kraft-muskulatur'],
    ),
    const TheoryNode(
      id: 'ausdauer-fitness',
      lesson: ausdauerPage,
      iconId: 'endurance',
      parentIds: <String>['koerper'],
    ),
    const TheoryNode(
      id: 'ausdauer-herz',
      lesson: herzPage,
      iconId: 'heartbeat',
      parentIds: <String>['ausdauer-fitness'],
    ),
    const TheoryNode(
      id: 'ausdauer-vo2max',
      lesson: vo2maxPage,
      iconId: 'lungs',
      parentIds: <String>['ausdauer-fitness'],
    ),
    const TheoryNode(
      id: 'ausdauer-grundlage',
      lesson: grundlagePage,
      iconId: 'jog',
      parentIds: <String>['ausdauer-fitness'],
    ),
    const TheoryNode(
      id: 'ausdauer-intervalle',
      lesson: intervallPage,
      iconId: 'intervals',
      parentIds: <String>['ausdauer-fitness'],
    ),
    const TheoryNode(
      id: 'ausdauer-energie',
      lesson: energiePage,
      iconId: 'battery',
      parentIds: <String>['ausdauer-fitness'],
    ),
    const TheoryNode(
      id: 'ernaehrung',
      lesson: ernaehrungPage,
      iconId: 'nutrition',
      parentIds: <String>['koerper'],
    ),
    TheoryNode(
      id: 'koerper-ernaehrung',
      lesson: koerperBranch.lessons[2],
      iconId: 'food',
      parentIds: const <String>['ernaehrung'],
      unlocksAbility: 'wurzelgriff',
    ),
    const TheoryNode(
      id: 'schlaf-regeneration',
      lesson: schlafRegenerationPage,
      iconId: 'moon',
      parentIds: <String>['koerper'],
    ),
    TheoryNode(
      id: 'koerper-schlaf',
      lesson: koerperBranch.lessons[0],
      iconId: 'sleep',
      parentIds: const <String>['schlaf-regeneration'],
      unlocksAbility: 'aurastrom',
    ),
    const TheoryNode(
      id: 'koerper-erholung',
      lesson: erholungPage,
      iconId: 'pause',
      parentIds: <String>['schlaf-regeneration'],
    ),
    const TheoryNode(
      id: 'koerper-stress',
      lesson: stressPage,
      iconId: 'storm',
      parentIds: <String>['schlaf-regeneration', 'geist'],
    ),

    // ----------------------------------------------------------------
    // Geist
    // ----------------------------------------------------------------
    const TheoryNode(
      id: 'geist-psychologie',
      lesson: psychologiePage,
      iconId: 'psyche',
      parentIds: <String>['geist'],
    ),
    TheoryNode(
      id: 'geist-aufmerksamkeit',
      lesson: geistBranch.lessons[0],
      iconId: 'focus',
      parentIds: const <String>['geist-psychologie'],
      unlocksAbility: 'zeitdehnung',
    ),
    const TheoryNode(
      id: 'geist-wiederholung',
      lesson: wiederholungPage,
      iconId: 'repeat',
      parentIds: <String>['geist-psychologie'],
      unlocksAbility: 'klingenwirbel',
    ),
    const TheoryNode(
      id: 'psychologie-konformitaet',
      lesson: aschPage,
      iconId: 'crowd',
      parentIds: <String>['geist-psychologie'],
    ),
    const TheoryNode(
      id: 'psychologie-gehorsam',
      lesson: milgramPage,
      iconId: 'authority',
      parentIds: <String>['geist-psychologie'],
    ),
    const TheoryNode(
      id: 'psychologie-bystander',
      lesson: bystanderPage,
      iconId: 'bystander',
      parentIds: <String>['geist-psychologie'],
    ),
    const TheoryNode(
      id: 'psychologie-gedaechtnis',
      lesson: gedaechtnisPage,
      iconId: 'memory',
      parentIds: <String>['geist-psychologie'],
    ),
    const TheoryNode(
      id: 'psychologie-emotionen',
      lesson: emotionenPage,
      iconId: 'emotion',
      parentIds: <String>['geist-psychologie'],
    ),
    const TheoryNode(
      id: 'selbstentwicklung',
      lesson: selbstentwicklungPage,
      iconId: 'growth',
      parentIds: <String>['geist'],
    ),
    TheoryNode(
      id: 'geist-gedanken',
      lesson: geistBranch.lessons[1],
      iconId: 'thought',
      parentIds: const <String>['selbstentwicklung'],
      unlocksAbility: 'frostnebel',
    ),
    TheoryNode(
      id: 'geist-unbehagen',
      lesson: geistBranch.lessons[2],
      iconId: 'endure',
      parentIds: const <String>['selbstentwicklung'],
    ),
    const TheoryNode(
      id: 'geist-motivation',
      lesson: motivationPage,
      iconId: 'spark',
      parentIds: <String>['selbstentwicklung'],
    ),

    // ----------------------------------------------------------------
    // Wissenschaft
    // ----------------------------------------------------------------
    const TheoryNode(
      id: 'wissenschaftliches-denken',
      lesson: denkenPage,
      iconId: 'method',
      parentIds: <String>['wissenschaft'],
    ),
    TheoryNode(
      id: 'wissenschaft-quelle',
      lesson: wissenschaftBranch.lessons[0],
      iconId: 'question',
      parentIds: const <String>['wissenschaftliches-denken'],
      unlocksAbility: 'prisma_barriere',
    ),
    TheoryNode(
      id: 'wissenschaft-ursache',
      lesson: wissenschaftBranch.lessons[1],
      iconId: 'link',
      parentIds: const <String>['wissenschaftliches-denken'],
      unlocksAbility: 'vulkanbruch',
    ),
    TheoryNode(
      id: 'wissenschaft-selbsttest',
      lesson: wissenschaftBranch.lessons[2],
      iconId: 'flask',
      parentIds: const <String>['wissenschaftliches-denken'],
    ),
    const TheoryNode(
      id: 'wissenschaft-stichprobe',
      lesson: stichprobePage,
      iconId: 'dice',
      parentIds: <String>['wissenschaftliches-denken'],
    ),
    const TheoryNode(
      id: 'wissenschaft-studie',
      lesson: studieLesenPage,
      iconId: 'news',
      parentIds: <String>['wissenschaftliches-denken'],
    ),

    // ----------------------------------------------------------------
    // Gesellschaft
    // ----------------------------------------------------------------
    const TheoryNode(
      id: 'beziehungen',
      lesson: beziehungenPage,
      iconId: 'bond',
      parentIds: <String>['gesellschaft'],
    ),
    TheoryNode(
      id: 'gesellschaft-umfeld',
      lesson: gesellschaftBranch.lessons[0],
      iconId: 'people',
      parentIds: const <String>['beziehungen'],
      unlocksAbility: 'giftmoor',
    ),
    TheoryNode(
      id: 'gesellschaft-zugehoerigkeit',
      lesson: gesellschaftBranch.lessons[1],
      iconId: 'heart',
      parentIds: const <String>['beziehungen'],
    ),
    TheoryNode(
      id: 'gesellschaft-grenzen',
      lesson: gesellschaftBranch.lessons[2],
      iconId: 'hand',
      parentIds: const <String>['beziehungen'],
      unlocksAbility: 'steinhaut',
    ),
    const TheoryNode(
      id: 'gesellschaft-hilfe',
      lesson: hilfeBittenPage,
      iconId: 'ask',
      parentIds: <String>['beziehungen'],
      unlocksAbility: 'bluetentau',
    ),
    const TheoryNode(
      id: 'medien-information',
      lesson: medienPage,
      iconId: 'media',
      parentIds: <String>['gesellschaft'],
    ),
    const TheoryNode(
      id: 'gesellschaft-vergleich',
      lesson: vergleichPage,
      iconId: 'scale',
      parentIds: <String>['medien-information', 'geist'],
    ),
  ],
  placeholders: theoryPlaceholders,
);

/// Die Überschriften aus Issue #54, zu denen es noch keine Seite gibt.
///
/// Reihenfolge wie im Issue. Wer eine befüllt, nimmt sie hier heraus und
/// trägt sie mit **derselben Id** oben als Knoten ein.
const List<TheoryPlaceholder> theoryPlaceholders = <TheoryPlaceholder>[
  // Körper
  TheoryPlaceholder(
    id: 'koerperkontrolle',
    title: 'Körperkontrolle',
    iconId: 'posture',
    parentIds: <String>['koerper'],
  ),
  TheoryPlaceholder(
    id: 'biologie-des-koerpers',
    title: 'Biologie des Körpers',
    iconId: 'anatomy',
    parentIds: <String>['koerper'],
  ),

  // Geist
  TheoryPlaceholder(
    id: 'philosophie',
    title: 'Philosophie',
    iconId: 'philosophy',
    parentIds: <String>['geist'],
  ),
  TheoryPlaceholder(
    id: 'geschichte',
    title: 'Geschichte',
    iconId: 'history',
    parentIds: <String>['geist'],
  ),
  TheoryPlaceholder(
    id: 'kreativitaet',
    title: 'Kreativität',
    iconId: 'creativity',
    parentIds: <String>['geist'],
  ),

  // Gesellschaft
  TheoryPlaceholder(
    id: 'kommunikation',
    title: 'Kommunikation',
    iconId: 'speech',
    parentIds: <String>['gesellschaft'],
  ),
  TheoryPlaceholder(
    id: 'arbeit-karriere',
    title: 'Arbeit & Karriere',
    iconId: 'work',
    parentIds: <String>['gesellschaft'],
  ),
  TheoryPlaceholder(
    id: 'wirtschaft-finanzen',
    title: 'Wirtschaft & Finanzen',
    iconId: 'money',
    parentIds: <String>['gesellschaft'],
  ),
  TheoryPlaceholder(
    id: 'recht-staat',
    title: 'Recht & Staat',
    iconId: 'law',
    parentIds: <String>['gesellschaft'],
  ),
  TheoryPlaceholder(
    id: 'gesellschaft-kultur',
    title: 'Gesellschaft & Kultur',
    iconId: 'culture',
    parentIds: <String>['gesellschaft'],
  ),

  // Wissenschaft
  TheoryPlaceholder(
    id: 'physik',
    title: 'Physik',
    iconId: 'physics',
    parentIds: <String>['wissenschaft'],
  ),
  TheoryPlaceholder(
    id: 'chemie',
    title: 'Chemie',
    iconId: 'chemistry',
    parentIds: <String>['wissenschaft'],
  ),
  TheoryPlaceholder(
    id: 'biologie',
    title: 'Biologie',
    iconId: 'biology',
    parentIds: <String>['wissenschaft'],
  ),
  TheoryPlaceholder(
    id: 'mathematik',
    title: 'Mathematik',
    iconId: 'math',
    parentIds: <String>['wissenschaft'],
  ),
  TheoryPlaceholder(
    id: 'technologie-informatik',
    title: 'Technologie & Informatik',
    iconId: 'computer',
    parentIds: <String>['wissenschaft'],
  ),
  TheoryPlaceholder(
    id: 'erde-universum',
    title: 'Erde & Universum',
    iconId: 'planet',
    parentIds: <String>['wissenschaft'],
  ),
];

/// Die Ids der vier Wurzeln, in Anzeigereihenfolge.
const List<String> theoryRootIds = <String>[
  'koerper',
  'geist',
  'wissenschaft',
  'gesellschaft',
];

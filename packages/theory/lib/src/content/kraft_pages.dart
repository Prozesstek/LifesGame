/// Die Themen unter **Kraft & Muskulatur** (ADR-0050, erstes befülltes
/// Gebiet).
///
/// Körper zuerst, weil dort die älteste Schieflage liegt: Stärke hat die
/// wenigsten Gewohnheitsvorlagen (Konzeptrunde 18.08.). Die Zahlen folgen
/// dem, was Übersichtsarbeiten recht einhellig zeigen, und sind bewusst
/// als Größenordnung formuliert — „etwa", „meist" —, nicht als Rezept.
///
/// **Entwürfe von Claude, gegengelesen von Frederik** (ADR-0050, Punkt 3).
library;

import '../lesson.dart';

const Lesson hypertrophiePage = Lesson(
  id: 'kraft-01-hypertrophie',
  title: 'Wie ein Muskel wächst',
  summary: 'Spannung, Menge und Baustoff — mehr braucht es nicht.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Spannung ist das Signal',
      body: 'Ein Muskel wächst, wenn er unter hoher Spannung arbeiten muss. '
          'Ob diese Spannung von einem schweren Gewicht mit wenigen '
          'Wiederholungen kommt oder von einem leichteren mit vielen, ist '
          'zweitrangig — solange der Satz fordernd endet. Muskelaufbau '
          'klappt über eine erstaunlich breite Spanne von etwa sechs bis '
          'dreißig Wiederholungen.',
    ),
    LessonSection(
      heading: 'Die Menge zählt über die Woche',
      body: 'Entscheidend ist, wie viele fordernde Sätze ein Muskel pro Woche '
          'bekommt. Grob gilt: etwa zehn und mehr harte Sätze je Muskel und '
          'Woche bringen mehr als wenige. Nach oben flacht der Nutzen ab, '
          'und irgendwann frisst die Erholung den Gewinn auf. Wer anfängt, '
          'wächst schon mit deutlich weniger.',
    ),
    LessonSection(
      heading: 'Ohne Baustoff kein Bau',
      body: 'Neues Muskelgewebe wird aus Eiweiß gebaut. Für Menschen, die mit '
          'Gewichten trainieren, liegt eine sinnvolle Menge bei etwa 1,6 '
          'Gramm Eiweiß je Kilogramm Körpergewicht am Tag, verteilt auf '
          'mehrere Mahlzeiten. Mehr schadet selten, bringt aber auch kaum '
          'zusätzlichen Muskel.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Welche Wiederholungszahl baut Muskeln auf?',
      options: <String>[
        'Nur genau acht bis zwölf Wiederholungen',
        'Nur sehr wenige mit dem schwersten Gewicht',
        'Eine breite Spanne, wenn der Satz fordernd endet',
      ],
      correctIndex: 2,
      explanation:
          'Die Spanne ist breit, grob sechs bis dreißig. Wichtiger als die '
          'Zahl ist, dass der Satz nah an die Grenze geht.',
    ),
    Question(
      prompt: 'Worauf kommt es bei der Trainingsmenge vor allem an?',
      options: <String>[
        'Auf die harten Sätze je Muskel und Woche',
        'Auf die Minuten, die man im Studio verbringt',
        'Auf die Zahl der Übungen in einer Einheit',
      ],
      correctIndex: 0,
      explanation:
          'Gezählt werden fordernde Sätze für einen Muskel über die Woche. '
          'Zeit im Studio und Übungsvielfalt sagen darüber wenig.',
    ),
    Question(
      prompt: 'Wie viel Eiweiß ist für Krafttraining ein guter Richtwert?',
      options: <String>[
        'Etwa 0,3 Gramm je Kilo Körpergewicht',
        'Etwa 1,6 Gramm je Kilo Körpergewicht',
        'Etwa 5 Gramm je Kilo Körpergewicht',
      ],
      correctIndex: 1,
      explanation:
          'Um 1,6 Gramm je Kilo am Tag reicht für die meisten. Deutlich '
          'weniger bremst, deutlich mehr bringt kaum etwas.',
    ),
  ],
);

const Lesson intensitaetPage = Lesson(
  id: 'kraft-02-intensitaet',
  title: 'Wie nah ans Versagen',
  summary: 'Ein harter Satz endet kurz vor der Grenze, nicht an ihr.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Wiederholungen in Reserve',
      body: 'Ein nützliches Maß für einen Satz ist die Frage: Wie viele '
          'saubere Wiederholungen wären noch gegangen? Das nennt man '
          'Wiederholungen in Reserve. Ein harter Satz endet mit etwa null '
          'bis drei in Reserve. Ein Satz, bei dem noch zehn gegangen wären, '
          'war Aufwärmen.',
    ),
    LessonSection(
      heading: 'Versagen ist kein Muss',
      body: 'Bis zum völligen Muskelversagen zu gehen, bringt gegenüber ein '
          'bis zwei Wiederholungen davor meist wenig zusätzlich — ermüdet '
          'aber deutlich mehr, und die Technik leidet in den letzten '
          'Zügen. Bei schweren Grundübungen wie Kniebeuge oder Kreuzheben '
          'ist ein Rest in Reserve auch eine Frage der Sicherheit.',
    ),
    LessonSection(
      heading: 'Sich selbst einschätzen lernen',
      body: 'Am Anfang schätzt man die Reserve fast immer zu hoch ein: Man '
          'hört auf, wenn es unangenehm wird, nicht wenn es nicht mehr '
          'geht. Hin und wieder einen Satz bei einer sicheren Übung bis '
          'zur Grenze zu gehen, eicht das eigene Gefühl.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Womit endet ein harter Satz?',
      options: <String>[
        'Mit etwa null bis drei Wiederholungen in Reserve',
        'Mit mindestens zehn Wiederholungen in Reserve',
        'Immer mit dem völligen Versagen des Muskels',
      ],
      correctIndex: 0,
      explanation:
          'Nah an der Grenze, aber nicht zwingend an ihr. Zehn in Reserve '
          'wäre Aufwärmen.',
    ),
    Question(
      prompt: 'Warum muss nicht jeder Satz bis zum Versagen gehen?',
      options: <String>[
        'Weil Versagen den Muskel dauerhaft schädigt',
        'Weil es kaum mehr bringt, aber viel mehr ermüdet',
        'Weil Muskeln nur mit leichten Sätzen wachsen',
      ],
      correctIndex: 1,
      explanation: 'Die letzten Wiederholungen bis zum Versagen bringen wenig '
          'zusätzlich und kosten viel Erholung — und oft saubere Technik.',
    ),
    Question(
      prompt: 'Wie schätzen Anfänger ihre Reserve meist ein?',
      options: <String>[
        'Genau richtig, das Gefühl täuscht selten',
        'Zu niedrig, sie gehen ständig zu weit',
        'Zu hoch, sie hören zu früh schon auf',
      ],
      correctIndex: 2,
      explanation:
          'Unangenehm heißt noch nicht am Ende. Ein gelegentlicher Satz '
          'bis zur Grenze zeigt, wie viel wirklich noch ging.',
    ),
  ],
);

const Lesson trainingsplanungPage = Lesson(
  id: 'kraft-03-trainingsplanung',
  title: 'Den Plan bauen',
  summary: 'Ganzkörper oder Split — und warum das zweitrangig ist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Ganzkörper oder Split',
      body: 'Beim Ganzkörpertraining kommt in jeder Einheit jeder große '
          'Muskel dran. Beim Split teilt man auf, etwa in Ober- und '
          'Unterkörper an verschiedenen Tagen. Beides funktioniert. Der '
          'Unterschied liegt vor allem darin, wie viele Tage man hat und '
          'wie lang eine Einheit sein darf.',
    ),
    LessonSection(
      heading: 'Zweimal ist meist besser als einmal',
      body: 'Jeden Muskel mindestens zweimal pro Woche zu trainieren, ist bei '
          'gleicher Gesamtmenge meist etwas besser, als alles an einem Tag '
          'zu erledigen. Die Menge lässt sich so besser verteilen, und jede '
          'Einheit bleibt frischer. Wer nur zwei Tage hat, landet damit '
          'fast von selbst beim Ganzkörperplan.',
    ),
    LessonSection(
      heading: 'Der beste Plan ist der, den man durchhält',
      body: 'Die Unterschiede zwischen vernünftigen Plänen sind klein. Der '
          'Unterschied zwischen einem Plan, den man drei Monate '
          'durchzieht, und einem, den man nach drei Wochen abbricht, ist '
          'riesig. Ein Plan passt zum Alltag oder er scheitert an ihm.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was unterscheidet Ganzkörper- und Splittraining?',
      options: <String>[
        'Nur eins von beiden baut wirklich Muskeln auf',
        'Wie die Muskeln auf die Trainingstage verteilt werden',
        'Ob man mit freien Gewichten oder Maschinen trainiert',
      ],
      correctIndex: 1,
      explanation:
          'Beide funktionieren. Der Unterschied ist die Verteilung — und die '
          'passt sich den verfügbaren Tagen an.',
    ),
    Question(
      prompt: 'Wie oft sollte ein Muskel pro Woche meist drankommen?',
      options: <String>[
        'Mindestens zweimal',
        'Genau einmal allein',
        'Nur alle zwei Wochen',
      ],
      correctIndex: 0,
      explanation:
          'Bei gleicher Gesamtmenge ist zweimal meist etwas besser: Die '
          'Sätze verteilen sich, jede Einheit bleibt frischer.',
    ),
    Question(
      prompt: 'Was entscheidet am meisten über den Erfolg eines Plans?',
      options: <String>[
        'Dass er möglichst viele verschiedene Übungen enthält',
        'Dass er von einem bekannten Sportler stammen muss',
        'Dass man ihn über viele Monate tatsächlich durchhält',
      ],
      correctIndex: 2,
      explanation: 'Zwischen vernünftigen Plänen sind die Unterschiede klein. '
          'Zwischen durchgehalten und abgebrochen sind sie riesig.',
    ),
  ],
);

const Lesson technikPage = Lesson(
  id: 'kraft-04-technik',
  title: 'Technik vor Gewicht',
  summary: 'Saubere Wiederholungen trainieren, was sie sollen.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der ganze Weg zählt',
      body: 'Eine Wiederholung über den vollen Bewegungsumfang trainiert den '
          'Muskel meist besser als eine halbe mit mehr Gewicht. Gerade die '
          'Phase, in der der Muskel gedehnt unter Last steht, scheint für '
          'das Wachstum wertvoll zu sein. Wer das Gewicht erhöht und dafür '
          'den Weg verkürzt, tauscht Wirkung gegen eine größere Zahl.',
    ),
    LessonSection(
      heading: 'Kontrolle statt Schwung',
      body: 'Schwung nimmt dem Muskel Arbeit ab und legt sie auf Gelenke und '
          'Sehnen. Ein kontrolliertes Absenken und ein entschlossenes, aber '
          'sauberes Heben sind die Regel. Ruckartige Wiederholungen fühlen '
          'sich nach viel an und bringen oft wenig.',
    ),
    LessonSection(
      heading: 'Erst leicht, dann schwer',
      body: 'Eine neue Übung lernt man mit wenig Gewicht, bis der Ablauf sitzt '
          '— ähnlich wie man ein Musikstück erst langsam spielt. Ein Video '
          'vom eigenen Satz oder ein prüfender Blick von jemand Erfahrenem '
          'zeigt Fehler, die man selbst nicht spürt.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was ist meist wirksamer für den Muskel?',
      options: <String>[
        'Der volle Bewegungsumfang mit etwas weniger Gewicht',
        'Ein halber Bewegungsweg mit deutlich mehr Gewicht',
        'Möglichst schnelle Wiederholungen mit viel Schwung',
      ],
      correctIndex: 0,
      explanation:
          'Der ganze Weg, besonders die gedehnte Phase unter Last, trainiert '
          'meist mehr als ein halber mit größerer Zahl auf der Hantel.',
    ),
    Question(
      prompt: 'Was macht Schwung bei einer Wiederholung?',
      options: <String>[
        'Er lässt den Muskel deutlich stärker arbeiten',
        'Er nimmt dem Muskel Arbeit ab und belastet Gelenke',
        'Er hat auf die Wirkung überhaupt keinen Einfluss',
      ],
      correctIndex: 1,
      explanation:
          'Was der Schwung erledigt, muss der Muskel nicht leisten — die '
          'Last landet stattdessen auf Sehnen und Gelenken.',
    ),
    Question(
      prompt: 'Wie lernt man eine neue Übung am besten?',
      options: <String>[
        'Gleich mit dem Gewicht, das andere dafür nehmen',
        'Nur durch Lesen, bevor man sie jemals ausprobiert',
        'Mit wenig Gewicht, bis der Ablauf wirklich sitzt',
      ],
      correctIndex: 2,
      explanation:
          'Erst der Ablauf, dann die Last. Ein Video oder ein zweiter Blick '
          'zeigt Fehler, die man selbst nicht spürt.',
    ),
  ],
);

const Lesson muskelkaterPage = Lesson(
  id: 'kraft-05-muskelkater',
  title: 'Muskelkater und Pausen',
  summary: 'Was Muskelkater bedeutet — und was nicht.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Muskelkater ist kein Zeugnis',
      body: 'Muskelkater tritt meist ein bis drei Tage nach ungewohnter '
          'Belastung auf, besonders nach neuen Übungen. Er zeigt, dass etwas '
          'neu war — nicht, dass das Training gut war. Wer regelmäßig '
          'trainiert, bekommt ihn seltener, und wächst trotzdem weiter.',
    ),
    LessonSection(
      heading: 'Pausen gehören zum Plan',
      body: 'Ein Muskel braucht nach einer harten Einheit meist ein bis zwei '
          'Tage, bis er wieder voll leistungsfähig ist. Andere Muskeln '
          'kann man in der Zeit trainieren. Wer denselben Muskel täglich '
          'hart belastet, gibt ihm nie die Gelegenheit, über den alten '
          'Stand hinaus aufzubauen.',
    ),
    LessonSection(
      heading: 'Übertraining ist selten, Unterversorgung nicht',
      body: 'Echtes Übertraining, das Wochen oder Monate der Erholung '
          'braucht, ist bei Freizeitsportlern selten. Häufiger ist zu '
          'wenig Schlaf, zu wenig Essen und zu viel Stress neben dem '
          'Training. Stagniert die Leistung über Wochen, lohnt der Blick '
          'dorthin oft mehr als ein neuer Plan.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was zeigt Muskelkater vor allem an?',
      options: <String>[
        'Dass die Belastung neu oder ungewohnt war',
        'Dass das Training besonders wirksam war',
        'Dass man sofort weitertrainieren sollte',
      ],
      correctIndex: 0,
      explanation:
          'Er kommt nach Ungewohntem. Wie gut das Training war, sagt er '
          'nicht — wer regelmäßig trainiert, hat ihn seltener.',
    ),
    Question(
      prompt: 'Wie lange braucht ein Muskel nach einer harten Einheit meist?',
      options: <String>[
        'Nur wenige Stunden',
        'Etwa ein bis zwei Tage',
        'Mindestens zwei Wochen',
      ],
      correctIndex: 1,
      explanation:
          'Ein bis zwei Tage sind üblich. In der Zeit lassen sich andere '
          'Muskeln trainieren.',
    ),
    Question(
      prompt: 'Was steckt häufig hinter wochenlangem Stillstand?',
      options: <String>[
        'Fast immer ein echtes, schweres Übertraining',
        'Ein Plan, der nicht modern genug gewesen ist',
        'Zu wenig Schlaf, Essen oder zu viel Stress',
      ],
      correctIndex: 2,
      explanation:
          'Echtes Übertraining ist selten. Die Erholung drumherum fehlt '
          'dagegen oft — dort anzusetzen hilft meist mehr.',
    ),
  ],
);

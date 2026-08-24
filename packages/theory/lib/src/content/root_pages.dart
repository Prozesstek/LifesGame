/// Die vier Wurzelseiten des Theoriegraphen (ADR-0019).
///
/// **Sie kosten keinen Theoriepunkt.** Eine Wurzel ist der Einstieg in
/// ein Gebiet — sie hinter einen Punkt zu legen hieße, den Spieler für
/// etwas zahlen zu lassen, das er noch nicht beurteilen kann. Bezahlt
/// wird ab dem ersten Unterknoten.
///
/// Jede Wurzel beantwortet dieselbe Frage für ihr Gebiet: *Warum steht
/// das in einem Spiel über Gewohnheiten?*
library;

import '../lesson.dart';

const Lesson koerperRootPage = Lesson(
  id: 'koerper-00-wurzel',
  title: 'Körper',
  summary: 'Warum der Körper die Grundlage für alles andere ist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Körper ist keine Nebensache',
      body:
          'Konzentration, Geduld und Selbstbeherrschung fühlen sich an wie '
          'Eigenschaften des Charakters. Sie hängen aber messbar an Schlaf, '
          'Bewegung und Essen. Wer zu wenig geschlafen hat, ist nicht '
          'plötzlich ein anderer Mensch — er hat weniger von dem, woraus '
          'diese Eigenschaften gemacht sind.',
    ),
    LessonSection(
      heading: 'Kleine Hebel, große Wirkung',
      body:
          'Die drei großen Stellschrauben sind unspektakulär: wann du '
          'schläfst, ob du dich bewegst, was in Reichweite liegt, wenn du '
          'Hunger hast. Keine davon verlangt Disziplin im Moment der '
          'Entscheidung — sie verlangen eine Entscheidung vorher, die dann '
          'für viele Tage gilt.',
    ),
    LessonSection(
      heading: 'Was dieser Zweig gibt',
      body:
          'Im Spiel zahlt dieser Zweig auf Ausdauer und Stärke ein, also auf '
          'Trefferpunkte und Angriff. Das ist kein Zufall: Es sind die '
          'beiden Werte, die einen Kampf am direktesten entscheiden — und '
          'im Leben ist es ähnlich unmittelbar.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Warum stehen Schlaf und Bewegung am Anfang?',
      options: <String>[
        'Weil sie am leichtesten zu messen sind',
        'Weil Konzentration und Selbstbeherrschung von ihnen abhängen',
        'Weil sie nichts kosten',
      ],
      correctIndex: 1,
      explanation:
          'Was wie Charakterstärke aussieht, ist zu großen Teilen '
          'Grundversorgung. Ohne sie fehlt die Substanz für alles andere.',
    ),
    Question(
      prompt: 'Was haben die drei großen Stellschrauben gemeinsam?',
      options: <String>[
        'Sie verlangen eine Entscheidung im Voraus, nicht im Moment',
        'Sie wirken sofort am selben Tag',
        'Sie brauchen Ausrüstung',
      ],
      correctIndex: 0,
      explanation:
          'Wer erst bei Hunger entscheidet, entscheidet schlecht. Die Arbeit '
          'liegt davor — beim Einkauf, beim Wecker, bei den Schuhen an der '
          'Tür.',
    ),
    Question(
      prompt: 'Auf welche Charakterwerte zahlt dieser Zweig ein?',
      options: <String>[
        'Klarheit und Disziplin',
        'Nur Stärke',
        'Ausdauer und Stärke',
      ],
      correctIndex: 2,
      explanation:
          'Ausdauer wird zu Trefferpunkten, Stärke zu Angriff — die beiden '
          'Werte, an denen ein Kampf am schnellsten kippt.',
    ),
  ],
);

const Lesson geistRootPage = Lesson(
  id: 'geist-00-wurzel',
  title: 'Geist',
  summary: 'Warum Aufmerksamkeit knapper ist als Zeit.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Zeit hat jeder gleich viel',
      body:
          'Der Tag hat für alle vierundzwanzig Stunden. Was sich '
          'unterscheidet, ist, wie viel davon überhaupt bei einer Sache '
          'ankommt. Wer acht Stunden an etwas sitzt und dabei alle zehn '
          'Minuten unterbrochen wird, hat nicht acht Stunden gearbeitet.',
    ),
    LessonSection(
      heading: 'Der Kopf ist kein zuverlässiger Zeuge',
      body:
          'Gedanken fühlen sich an wie Beobachtungen der Wirklichkeit. Sie '
          'sind aber Vorschläge — oft nützliche, manchmal völlig falsche. '
          'Den Unterschied zu bemerken ist eine Fähigkeit, die man üben '
          'kann, und sie ist der Kern dieses Zweigs.',
    ),
    LessonSection(
      heading: 'Was dieser Zweig gibt',
      body:
          'Hier geht es um Klarheit und Disziplin — im Spiel um Energie und '
          'Verteidigung. Wer im Kampf Energie hat, kann etwas tun, statt nur '
          'zu reagieren. Die Übersetzung ist absichtlich wörtlich gemeint.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Warum ist Aufmerksamkeit knapper als Zeit?',
      options: <String>[
        'Weil der Tag zu kurz ist',
        'Weil nur ein Teil der Zeit tatsächlich bei einer Sache ankommt',
        'Weil man nachts nicht arbeiten kann',
      ],
      correctIndex: 1,
      explanation:
          'Unterbrochene Stunden sind keine Stunden. Die Zeit vergeht '
          'trotzdem — die Aufmerksamkeit nicht.',
    ),
    Question(
      prompt: 'Was ist ein Gedanke nach diesem Zweig?',
      options: <String>[
        'Ein Vorschlag, der stimmen kann oder auch nicht',
        'Eine Beobachtung der Wirklichkeit',
        'Ein Befehl, dem man folgen muss',
      ],
      correctIndex: 0,
      explanation:
          'Gedanken als Vorschläge zu behandeln schafft genau den Abstand, '
          'aus dem heraus eine Entscheidung möglich wird.',
    ),
    Question(
      prompt: 'Welchen Kampfwert speist Klarheit?',
      options: <String>['Angriff', 'Verteidigung', 'Energie'],
      correctIndex: 2,
      explanation:
          'Energie ist das, was Handlungsfähigkeit im Kampf ausmacht — ohne '
          'sie bleibt nur der Grundangriff.',
    ),
  ],
);

const Lesson wissenschaftRootPage = Lesson(
  id: 'wissenschaft-00-wurzel',
  title: 'Wissenschaft',
  summary: 'Wie man erkennt, ob eine Behauptung etwas taugt.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Ratgebermarkt ist voll',
      body:
          'Zu jedem Thema in diesem Spiel gibt es tausend Ratschläge, und '
          'sie widersprechen sich. Ohne ein Werkzeug, mit dem man sie '
          'auseinanderhält, bleibt nur, dem lautesten zu glauben. Dieser '
          'Zweig ist dieses Werkzeug.',
    ),
    LessonSection(
      heading: 'Zwei Fragen reichen erstaunlich weit',
      body:
          '„Woher weißt du das?" und „Könnte es auch anders herum sein?" '
          'sortieren den größten Teil des Unsinns aus, ohne dass man eine '
          'einzige Studie lesen muss. Beide Fragen sind unbequem, und '
          'deshalb stellt sie kaum jemand.',
    ),
    LessonSection(
      heading: 'Am Ende zählt der eigene Versuch',
      body:
          'Was im Durchschnitt vieler Menschen wirkt, muss bei dir nicht '
          'wirken. Deshalb endet dieser Zweig nicht bei fremden Ergebnissen, '
          'sondern bei einem eigenen Test — dem einzigen, dessen Stichprobe '
          'genau zu dir passt.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wozu dient dieser Zweig?',
      options: <String>[
        'Um Ratschläge auseinanderzuhalten, statt dem lautesten zu glauben',
        'Um Studien auswendig zu lernen',
        'Um Diskussionen zu gewinnen',
      ],
      correctIndex: 0,
      explanation:
          'Widersprüchliche Ratschläge sind der Normalfall. Ein Werkzeug '
          'zum Sortieren ist nützlicher als noch ein Ratschlag.',
    ),
    Question(
      prompt: 'Welche zwei Fragen bringen am meisten?',
      options: <String>[
        'Wer sagt das? und Wie viel kostet es?',
        'Woher weißt du das? und Könnte es andersherum sein?',
        'Ist das neu? und Ist das beliebt?',
      ],
      correctIndex: 1,
      explanation:
          'Die erste fragt nach der Grundlage, die zweite nach der '
          'Gegenrichtung. Zusammen sieben sie den meisten Unsinn aus.',
    ),
    Question(
      prompt: 'Warum reicht ein guter Durchschnittsbefund nicht?',
      options: <String>[
        'Weil Durchschnitte immer falsch sind',
        'Weil Studien alt sind',
        'Weil er über viele Menschen gilt und nicht über dich',
      ],
      correctIndex: 2,
      explanation:
          'Ein Mittelwert beschreibt eine Gruppe. Ob du dazugehörst, zeigt '
          'nur der eigene Versuch.',
    ),
  ],
);

const Lesson gesellschaftRootPage = Lesson(
  id: 'gesellschaft-00-wurzel',
  title: 'Gesellschaft',
  summary: 'Warum Vorsätze an anderen Menschen scheitern oder halten.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Niemand ändert sich allein',
      body:
          'Gewohnheiten entstehen selten im luftleeren Raum. Wer mit wem '
          'isst, wer wann anruft, wen man am Wochenende sieht — das '
          'entscheidet oft mehr über einen Vorsatz als der Vorsatz selbst.',
    ),
    LessonSection(
      heading: 'Umgebung schlägt Willenskraft',
      body:
          'Es ist erheblich leichter, sich eine Umgebung zu suchen, in der '
          'das gewünschte Verhalten normal ist, als es gegen eine Umgebung '
          'durchzusetzen, in der es auffällt. Das ist keine Schwäche, '
          'sondern eine Abkürzung.',
    ),
    LessonSection(
      heading: 'Grenzen gehören dazu',
      body:
          'Wer nie ablehnt, hat keine Zeit für das, was er sich vorgenommen '
          'hat. Nein zu sagen, ohne den anderen zu verlieren, ist eine '
          'erlernbare Fertigkeit — und einer der Knoten in diesem Zweig.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was entscheidet oft mehr als der Vorsatz selbst?',
      options: <String>[
        'Die Umgebung und die Menschen darin',
        'Die Uhrzeit',
        'Die Länge des Vorsatzes',
      ],
      correctIndex: 0,
      explanation:
          'Verhalten ist ansteckend. Wer die Umgebung ändert, muss weniger '
          'gegen sich selbst kämpfen.',
    ),
    Question(
      prompt: 'Warum ist die passende Umgebung eine Abkürzung?',
      options: <String>[
        'Weil sie schneller geht',
        'Weil dort das gewünschte Verhalten normal ist statt auffällig',
        'Weil man dort nicht nachdenken muss',
      ],
      correctIndex: 1,
      explanation:
          'Gegen eine Umgebung anzulaufen kostet dauerhaft Kraft. Mit ihr '
          'zu laufen kostet einmal die Suche.',
    ),
    Question(
      prompt: 'Warum gehört Ablehnen in diesen Zweig?',
      options: <String>[
        'Weil man Konflikte üben sollte',
        'Weil Freundlichkeit überschätzt wird',
        'Weil ohne Grenzen keine Zeit für das Vorgenommene bleibt',
      ],
      correctIndex: 2,
      explanation:
          'Jedes Ja zu etwas anderem ist ein Nein zum eigenen Vorhaben — nur '
          'ein unausgesprochenes.',
    ),
  ],
);

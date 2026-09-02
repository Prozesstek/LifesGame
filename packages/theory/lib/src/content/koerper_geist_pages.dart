/// Neue Knotenseiten für Körper und Geist (ADR-0019).
///
/// Jede Wurzel braucht mindestens fünf Unterknoten. Körper und Geist
/// hatten je drei aus der Zeit der flachen Zweige — hier kommen die
/// fehlenden zwei je Wurzel dazu.
library;

import '../lesson.dart';

const Lesson erholungPage = Lesson(
  id: 'koerper-04-erholung',
  title: 'Erholung ist Teil der Arbeit',
  summary: 'Warum Pausen kein Ausfall sind, sondern die Bedingung.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Belastung allein macht nicht stärker',
      body:
          'Ein Muskel wächst nicht während des Trainings, sondern danach. '
          'Dasselbe gilt für fast alles, was man üben kann: Der Reiz setzt '
          'etwas in Gang, die Anpassung passiert in der Ruhe. Wer nur Reize '
          'setzt und nie erholt, sammelt Belastung ohne Ertrag.',
    ),
    LessonSection(
      heading: 'Erschöpfung sieht aus wie Faulheit',
      body:
          'Wer über Wochen zu wenig erholt, verliert zuerst die Lust, dann '
          'die Konzentration, dann die Leistung. Von außen — und oft auch '
          'von innen — sieht das nach mangelnder Disziplin aus. Die Antwort '
          '„streng dich mehr an" macht es dann zuverlässig schlimmer.',
    ),
    LessonSection(
      heading: 'Pausen muss man planen',
      body:
          'Eine Pause, die erst kommt, wenn nichts mehr geht, ist keine '
          'Erholung, sondern ein Zusammenbruch. Nützlich sind Pausen, die '
          'im Plan stehen, bevor sie nötig sind — ein freier Tag pro Woche, '
          'eine leichtere Woche pro Monat.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wann passiert die Anpassung an eine Belastung?',
      options: <String>[
        'Während der Belastung',
        'In der Erholung danach',
        'Beim nächsten Mal',
      ],
      correctIndex: 1,
      explanation:
          'Der Reiz stößt an, die Ruhe baut auf. Ohne den zweiten Teil '
          'bleibt vom ersten nur die Belastung.',
    ),
    Question(
      prompt: 'Warum ist „streng dich mehr an" bei Erschöpfung falsch?',
      options: <String>[
        'Weil Anstrengung gegen Müdigkeit grundsätzlich nie hilft',
        'Weil man dann überhaupt keine Lust mehr hat',
        'Weil es die Ursache verstärkt statt sie zu beheben',
      ],
      correctIndex: 2,
      explanation:
          'Erschöpfung sieht aus wie Faulheit. Wer sie mit mehr Belastung '
          'beantwortet, vertieft genau das Loch, aus dem er heraus will.',
    ),
    Question(
      prompt: 'Was unterscheidet eine nützliche Pause von einem Einbruch?',
      options: <String>[
        'Dass sie geplant war, bevor sie nötig wurde',
        'Ihre Länge und die Tageszeit, zu der sie liegt',
        'Dass sie sich schon im Moment gut anfühlt',
      ],
      correctIndex: 0,
      explanation:
          'Geplante Pausen halten das System stabil. Ungeplante sind das '
          'Ergebnis davon, dass es das nicht mehr ist.',
    ),
  ],
);

const Lesson stressPage = Lesson(
  id: 'koerper-05-stress',
  title: 'Stress ist ein Werkzeug mit Verfallsdatum',
  summary: 'Warum kurzer Stress nützt und langer schadet.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Wofür die Reaktion gebaut ist',
      body:
          'Die Stressreaktion stellt kurzfristig Energie bereit, schärft '
          'die Aufmerksamkeit und stellt anderes hintan — Verdauung, '
          'Reparatur, langfristiges Denken. Für eine Bedrohung, die in '
          'Minuten vorbei ist, ist das eine ausgezeichnete Antwort.',
    ),
    LessonSection(
      heading: 'Das Problem ist die Dauer',
      body:
          'Moderne Belastungen hören selten nach Minuten auf. Läuft die '
          'Reaktion über Wochen, bleiben genau die Dinge liegen, die sie '
          'hintanstellt. Schlaf wird schlechter, die Geduld kürzer, die '
          'Anfälligkeit größer — und all das erzeugt neuen Stress.',
    ),
    LessonSection(
      heading: 'Was die Schleife unterbricht',
      body:
          'Wirksam ist alles, was dem Körper ein Ende signalisiert: '
          'Bewegung, langsames Ausatmen, Schlaf, ein erledigter Punkt auf '
          'einer Liste. Der gemeinsame Nenner ist nicht Entspannung, '
          'sondern ein Abschluss.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was stellt die Stressreaktion hintan?',
      options: <String>[
        'Aufmerksamkeit, Energie und schnelle Reaktion',
        'Bewegung, Muskelkraft und Körperspannung',
        'Verdauung, Reparatur und langfristiges Denken',
      ],
      correctIndex: 2,
      explanation:
          'Alles, was in einer akuten Gefahr warten kann, wird verschoben. '
          'Über Wochen bleibt es dann liegen.',
    ),
    Question(
      prompt: 'Warum ist Dauerstress etwas anderes als kurzer Stress?',
      options: <String>[
        'Weil er im Augenblick deutlich stärker empfunden wird als sonst',
        'Weil man sich mit der Zeit vollständig daran gewöhnen kann',
        'Weil das Verschobene nie nachgeholt wird und neuen Stress erzeugt',
      ],
      correctIndex: 2,
      explanation:
          'Die Reaktion selbst ist nicht das Problem — ihr Ausbleiben eines '
          'Endes ist es. Daraus wird eine Schleife.',
    ),
    Question(
      prompt: 'Was haben wirksame Gegenmittel gemeinsam?',
      options: <String>[
        'Sie signalisieren dem Körper einen Abschluss',
        'Sie fühlen sich schon im Moment angenehm an',
        'Sie dauern mindestens eine halbe Stunde',
      ],
      correctIndex: 0,
      explanation:
          'Nicht Entspannung ist der Wirkstoff, sondern das Signal, dass '
          'die Sache vorbei ist.',
    ),
  ],
);

const Lesson motivationPage = Lesson(
  id: 'geist-04-motivation',
  title: 'Motivation ist ein Gefühl, kein Plan',
  summary: 'Warum Warten auf Lust die häufigste Falle ist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Die Reihenfolge ist meist andersherum',
      body:
          'Der verbreitete Glaube lautet: erst Motivation, dann Handlung. '
          'In der Praxis kommt die Lust häufiger nach den ersten Minuten '
          'als davor. Wer wartet, bis er Lust hat, wartet auf etwas, das '
          'das Anfangen erst erzeugt.',
    ),
    LessonSection(
      heading: 'Gefühle schwanken, Systeme nicht',
      body:
          'Motivation hängt an Schlaf, Wetter, Nachrichten und Zufall. '
          'Etwas, das an einer so schwankenden Größe hängt, taugt nicht als '
          'Fundament. Ein fester Zeitpunkt, ein vorbereiteter Platz und '
          'eine lächerlich kleine erste Handlung schwanken nicht.',
    ),
    LessonSection(
      heading: 'Was trotzdem hilft',
      body:
          'Motivation ist nicht wertlos — sie ist nur kein Werkzeug für '
          'schlechte Tage. Nutze sie an guten Tagen für das, was das System '
          'stabiler macht: einkaufen, vorbereiten, aufräumen. So arbeitet '
          'die gute Laune für den Tag, an dem keine da ist.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'In welcher Reihenfolge treten Handlung und Lust meist auf?',
      options: <String>[
        'Erst kommt die Lust, dann folgt die Handlung',
        'Die Lust kommt oft erst nach den ersten Minuten',
        'Beide treten in aller Regel gleichzeitig auf',
      ],
      correctIndex: 1,
      explanation:
          'Anfangen erzeugt die Lust häufiger, als die Lust das Anfangen '
          'erzeugt. Wer wartet, wartet auf sein eigenes Ergebnis.',
    ),
    Question(
      prompt: 'Warum taugt Motivation nicht als Fundament?',
      options: <String>[
        'Weil sie sich am Ende als unehrlich erweist',
        'Weil sie insgesamt zu selten auftritt',
        'Weil sie an Schlaf, Wetter und Zufall hängt',
      ],
      correctIndex: 2,
      explanation:
          'Eine schwankende Größe trägt nichts. Ein fester Zeitpunkt tut es.',
    ),
    Question(
      prompt: 'Wofür sollte man gute Tage nutzen?',
      options: <String>[
        'Um das System für schlechte Tage vorzubereiten',
        'Für möglichst viel Leistung an diesem Tag',
        'Für eine Belohnung, die man sich dann gönnt',
      ],
      correctIndex: 0,
      explanation:
          'Einkaufen, vorbereiten, aufräumen: So arbeitet die gute Laune '
          'für den Tag, an dem keine da ist.',
    ),
  ],
);

const Lesson wiederholungPage = Lesson(
  id: 'geist-05-wiederholung',
  title: 'Wiederholen, kurz bevor du vergisst',
  summary: 'Warum Anstrengung beim Erinnern der eigentliche Lernvorgang ist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Lesen fühlt sich nach Lernen an',
      body:
          'Etwas zum dritten Mal zu lesen erzeugt ein starkes Gefühl von '
          'Vertrautheit — und Vertrautheit wird zuverlässig mit Können '
          'verwechselt. Beim Abrufen ohne Vorlage bricht dieses Gefühl '
          'regelmäßig zusammen.',
    ),
    LessonSection(
      heading: 'Abrufen ist der Vorgang',
      body:
          'Sich an etwas zu erinnern, ohne nachzusehen, ist anstrengender '
          'als Lesen und dabei deutlich wirksamer. Die Anstrengung ist kein '
          'Nebeneffekt, sondern der Lernvorgang selbst: Was mühsam '
          'hervorgeholt wird, liegt danach näher an der Oberfläche.',
    ),
    LessonSection(
      heading: 'Der beste Zeitpunkt ist kurz vor dem Vergessen',
      body:
          'Zu früh wiederholt ist verschwendete Mühe, zu spät ist neu '
          'lernen. Am meisten bringt der Moment, in dem es gerade noch '
          'geht — deshalb werden die Abstände mit jeder gelungenen '
          'Wiederholung länger.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Warum täuscht wiederholtes Lesen?',
      options: <String>[
        'Weil es dabei insgesamt zu lange dauert',
        'Weil Vertrautheit mit Können verwechselt wird',
        'Weil man dabei fast immer irgendwann einschläft',
      ],
      correctIndex: 1,
      explanation:
          'Das Gefühl, es zu kennen, entsteht durch die Vorlage. Ohne sie '
          'ist es oft weg.',
    ),
    Question(
      prompt: 'Welche Rolle spielt die Anstrengung beim Abrufen?',
      options: <String>[
        'Sie ist ein unerwünschter Effekt',
        'Sie zeigt zu wenig Vorbereitung',
        'Sie ist der Lernvorgang selbst',
      ],
      correctIndex: 2,
      explanation:
          'Mühsam Hervorgeholtes liegt danach näher an der Oberfläche. '
          'Leichtes Wiedererkennen bewirkt das nicht.',
    ),
    Question(
      prompt: 'Wann bringt eine Wiederholung am meisten?',
      options: <String>[
        'Kurz bevor man es vergessen würde',
        'Sofort im Anschluss an das Lesen',
        'Nach festen sieben Tagen Pause',
      ],
      correctIndex: 0,
      explanation:
          'Zu früh ist verschwendet, zu spät ist neu lernen. Deshalb werden '
          'die Abstände mit jedem Erfolg länger.',
    ),
  ],
);

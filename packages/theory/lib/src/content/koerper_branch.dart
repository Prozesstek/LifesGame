import '../branch.dart';
import '../lesson.dart';

/// Zweig „Körper" — Schlaf, Bewegung, Essen.
///
/// Erster Zweig hinter einer Levelsperre (ADR-0007). Bewusst der
/// niedrigschwelligste der vier: Die Inhalte lassen sich sofort in tägliche
/// Habits übersetzen.
const TheoryBranch koerperBranch = TheoryBranch(
  id: 'koerper',
  name: 'Körper',
  description:
      'Schlaf, Bewegung, Essen. Drei Bereiche, in denen kleine Änderungen '
      'am meisten tragen — und in denen fast jeder das Falsche für '
      'entscheidend hält.',
  unlockLevel: 2,
  lessons: <Lesson>[_schlaf, _bewegung, _umgebung],
);

const Lesson _schlaf = Lesson(
  id: 'koerper-01-schlaf',
  title: 'Schlaf ist keine verlorene Zeit',
  summary: 'Warum die Uhrzeit wichtiger ist als die Stundenzahl.',
  unlocksHabit: 'Feste Aufstehzeit — auch am Wochenende',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Nachts wird aufgeräumt',
      body:
          'Schlaf ist kein Ausschalten, sondern Wartungsarbeit. Erlebtes wird '
          'sortiert und ins Langzeitgedächtnis überführt, Hormone werden '
          'zurückgesetzt, das Gehirn spült Abfallstoffe aus. Wer eine Nacht '
          'kürzt, spart keine Zeit — er verschiebt die Arbeit auf den '
          'nächsten Tag, wo sie als Konzentrationsloch wieder auftaucht.',
    ),
    LessonSection(
      heading: 'Regelmäßigkeit schlägt Dauer',
      body: 'Sieben Stunden zur immer gleichen Zeit sind besser als acht '
          'Stunden zu wechselnden. Der Körper stellt sich auf einen Rhythmus '
          'ein und bereitet Einschlafen und Aufwachen vor. Wer jeden Tag zu '
          'einer anderen Zeit ins Bett geht, zwingt ihn, ständig neu zu '
          'raten. Der verlässlichste Anker dafür ist nicht die Schlafenszeit, '
          'sondern die Aufstehzeit — sie lässt sich willentlich einhalten, '
          'Einschlafen nicht.',
    ),
    LessonSection(
      heading: 'Licht stellt die innere Uhr',
      body: 'Helligkeit am Morgen sagt dem Körper, wann der Tag beginnt, und '
          'legt damit fest, wann abends Müdigkeit einsetzt. Zehn Minuten '
          'Tageslicht kurz nach dem Aufstehen wirken stärker als jedes '
          'Einschlafritual am Abend. Umgekehrt verschiebt helles Licht spät '
          'am Abend den Rhythmus nach hinten.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was passiert, wenn jemand regelmäßig eine Stunde Schlaf '
          'streicht?',
      options: <String>[
        'Er gewinnt jeden Tag eine Stunde nutzbare Zeit',
        'Der Körper gleicht den Ausfall vollständig aus',
        'Es wirkt sich nur auf die Stimmung am Morgen aus',
        'Die Arbeit verschiebt sich in den nächsten Tag',
      ],
      correctIndex: 3,
      explanation: 'Die nächtliche Wartung fällt nicht weg, sie fehlt nur. Am '
          'Folgetag zeigt sie sich als Konzentrations- und Stimmungsloch.',
    ),
    Question(
      prompt: 'Was ist verlässlicher: acht Stunden zu wechselnden Zeiten '
          'oder sieben zur gleichen?',
      options: <String>[
        'Sieben Stunden zur gleichen Zeit',
        'Acht Stunden, die Dauer zählt',
        'Beides ist gleichwertig',
        'Das hängt allein vom Alter ab',
      ],
      correctIndex: 0,
      explanation:
          'Ein fester Rhythmus lässt den Körper Einschlafen und Aufwachen '
          'vorbereiten. Wechselnde Zeiten zwingen ihn, jeden Abend neu zu '
          'raten.',
    ),
    Question(
      prompt: 'Welcher Anker lässt sich willentlich einhalten?',
      options: <String>[
        'Die Einschlafzeit',
        'Die Traumphase',
        'Die Schlafdauer',
        'Die Aufstehzeit',
      ],
      correctIndex: 3,
      explanation:
          'Einschlafen kann man nicht erzwingen, Aufstehen schon. Deshalb '
          'ist die Aufstehzeit der praktikable Hebel — und deshalb ist sie '
          'die Habit-Vorlage dieser Lektion.',
    ),
  ],
);

const Lesson _bewegung = Lesson(
  id: 'koerper-02-bewegung',
  title: 'Die kleinste Dosis, die wirkt',
  summary: 'Warum der größte Gewinn ganz am Anfang liegt.',
  unlocksHabit: 'Zehn Minuten am Stück gehen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der erste Schritt bringt am meisten',
      body: 'Der Unterschied zwischen null und ein bisschen Bewegung ist '
          'größer als der zwischen viel und sehr viel. Wer von gar nichts auf '
          'zwanzig Minuten Gehen am Tag kommt, holt den Löwenanteil des '
          'gesundheitlichen Effekts. Wer von einer Stunde auf zwei erhöht, '
          'gewinnt vergleichsweise wenig dazu.',
    ),
    LessonSection(
      heading: 'Alltagsbewegung zählt mit',
      body: 'Treppen, Wege, Stehen, Tragen — das summiert sich über einen Tag '
          'auf mehr als die meisten Trainingseinheiten. Wer drei Mal die '
          'Woche trainiert und die übrigen sechzehn Stunden sitzt, hat ein '
          'Bewegungsproblem, kein Trainingsproblem. Die Lösung liegt selten '
          'im Fitnessstudio.',
    ),
    LessonSection(
      heading: 'Häufig schlägt hart',
      body: 'Eine anstrengende Einheit pro Woche fühlt sich nach mehr an als '
          'zehn Minuten täglich, bewirkt aber weniger. Häufigkeit hält den '
          'Körper in Bereitschaft, Intensität überfordert ihn punktuell. '
          'Dazu kommt: Was täglich stattfindet, wird zur Gewohnheit. Was '
          'einmal pro Woche stattfindet, bleibt eine Entscheidung.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wo liegt der größte gesundheitliche Gewinn?',
      options: <String>[
        'Beim Sprung von viel auf sehr viel Bewegung',
        'Bei besonders intensiven Einheiten',
        'Beim Sprung von gar keiner auf etwas Bewegung',
        'Bei Krafttraining gegenüber Ausdauer',
      ],
      correctIndex: 2,
      explanation:
          'Der Weg von null auf ein wenig bringt den Löwenanteil. Danach '
          'wird jede zusätzliche Stunde weniger wert.',
    ),
    Question(
      prompt: 'Jemand trainiert dreimal wöchentlich und sitzt sonst den '
          'ganzen Tag. Was fehlt ihm?',
      options: <String>[
        'Eine höhere Trainingsintensität',
        'Ein zusätzlicher Trainingstag',
        'Eine besser passende Sportart',
        'Bewegung über den Tag verteilt',
      ],
      correctIndex: 3,
      explanation:
          'Alltagsbewegung summiert sich über sechzehn wache Stunden auf '
          'mehr als drei Einheiten. Das ist ein Bewegungs-, kein '
          'Trainingsproblem.',
    ),
    Question(
      prompt: 'Warum ist täglich zehn Minuten oft besser als einmal '
          'wöchentlich eine Stunde?',
      options: <String>[
        'Weil Häufigkeit zur Gewohnheit wird, Seltenheit zur Entscheidung',
        'Weil zehn Minuten am Stück anstrengender sind als eine Stunde',
        'Weil dabei über die Woche insgesamt mehr Zeit zusammenkommt',
        'Weil kurze Einheiten mehr Kalorien verbrauchen als lange',
      ],
      correctIndex: 0,
      explanation:
          'Was täglich passiert, muss nicht mehr entschieden werden. Was '
          'einmal die Woche ansteht, steht jedes Mal neu zur Debatte — '
          'dieselbe Logik wie im Zweig Gewohnheiten.',
    ),
  ],
);

const Lesson _umgebung = Lesson(
  id: 'koerper-03-umgebung',
  title: 'Essen ist ein Umgebungsproblem',
  summary: 'Warum der Einkauf mehr entscheidet als die Disziplin.',
  unlocksHabit: 'Ein Glas Wasser vor jeder Mahlzeit',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Sichtweite schlägt Vorsatz',
      body: 'Was in Reichweite steht, wird gegessen. Das ist keine '
          'Charakterschwäche, sondern gut belegtes Verhalten: Die Menge, die '
          'jemand isst, hängt stärker von Packungsgröße, Tellergröße und '
          'Sichtbarkeit ab als von seinem Hungergefühl. Wer sich abends gegen '
          'die offene Chipstüte entscheiden muss, hat den Kampf schon '
          'verloren.',
    ),
    LessonSection(
      heading: 'Die Entscheidung fällt im Supermarkt',
      body: 'Eine Entscheidung beim Einkauf ersetzt sieben abendliche. Was '
          'nicht in der Wohnung ist, muss man nicht ablehnen. Das ist '
          'derselbe Hebel wie beim Auslöser einer Gewohnheit: die Umgebung '
          'einmal ändern statt sich täglich zusammenzureißen.',
    ),
    LessonSection(
      heading: 'Ersetzen, nicht verbieten',
      body: 'Verbote erzeugen Verlangen und halten selten lange. Austausch '
          'funktioniert besser: dieselbe Handlung, anderes Ergebnis. Wasser '
          'vor der Mahlzeit statt danach, Obst in Sichtweite statt Süßem, '
          'der Teller einmal kleiner. Keine dieser Änderungen verlangt '
          'Verzicht im Moment — sie verschieben nur, was am nächsten liegt.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wovon hängt die gegessene Menge stärker ab als vom Hunger?',
      options: <String>[
        'Von der Tageszeit und dem Wochentag',
        'Von der Stimmung an diesem Tag',
        'Von Sichtbarkeit und Portionsgröße',
        'Vom Preis der eingekauften Ware',
      ],
      correctIndex: 2,
      explanation:
          'Packungs- und Tellergröße sowie Sichtbarkeit steuern die Menge '
          'zuverlässiger als das Hungergefühl. Deshalb ist Essen zuerst ein '
          'Umgebungsproblem.',
    ),
    Question(
      prompt: 'Warum ist der Einkauf der wirksamere Zeitpunkt?',
      options: <String>[
        'Weil man dort deutlich mehr Zeit zum Nachdenken hat',
        'Weil die Preise im Laden zum Sparen zwingen',
        'Weil man beim Einkauf weniger hungrig ist',
        'Weil eine Entscheidung dort viele spätere ersetzt',
      ],
      correctIndex: 3,
      explanation: 'Was nicht in der Wohnung ist, muss abends nicht abgelehnt '
          'werden. Eine Entscheidung im Laden ersetzt sieben zu Hause.',
    ),
    Question(
      prompt: 'Was funktioniert langfristig besser als ein Verbot?',
      options: <String>[
        'Ein strengeres Verbot mit klarer Regel',
        'Ein Austausch, der dieselbe Handlung erlaubt',
        'Eine Belohnung für jede Woche mit Verzicht',
        'Eine feste Liste erlaubter Lebensmittel',
      ],
      correctIndex: 1,
      explanation:
          'Verbote erzeugen Verlangen. Ein Austausch behält die Handlung '
          'bei und ändert nur das Ergebnis — er verlangt im Moment keinen '
          'Verzicht.',
    ),
  ],
);

import '../branch.dart';
import '../lesson.dart';

/// Zweig „Geist" — Aufmerksamkeit, Gedanken, Impulse.
const TheoryBranch geistBranch = TheoryBranch(
  id: 'geist',
  name: 'Geist',
  description:
      'Aufmerksamkeit, Gedanken, Impulse. Was im Kopf passiert, bevor eine '
      'Handlung überhaupt zur Debatte steht.',
  unlockLevel: 3,
  lessons: <Lesson>[_aufmerksamkeit, _gedanken, _unbehagen],
);

const Lesson _aufmerksamkeit = Lesson(
  id: 'geist-01-aufmerksamkeit',
  title: 'Aufmerksamkeit ist die eigentliche Währung',
  summary: 'Warum nicht die Arbeit teuer ist, sondern der Wechsel.',
  unlocksHabit: 'Eine Stunde ohne Benachrichtigungen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Wechsel kostet, nicht die Aufgabe',
      body: 'Das Gehirn kann nicht zwei anspruchsvolle Dinge gleichzeitig tun. '
          'Was wie Multitasking aussieht, ist schnelles Hin- und Herspringen '
          '— und jeder Sprung kostet. Ein Teil der Aufmerksamkeit bleibt an '
          'der vorigen Aufgabe hängen. Nach der Unterbrechung dauert es '
          'Minuten, bis die volle Tiefe wieder da ist.',
    ),
    LessonSection(
      heading: 'Die Erwartung reicht zum Stören',
      body: 'Man muss nicht unterbrochen werden, um unkonzentriert zu sein. Es '
          'genügt, mit einer Unterbrechung zu rechnen. Ein Handy, das '
          'sichtbar auf dem Tisch liegt, senkt die Leistung messbar, auch '
          'wenn es die ganze Zeit stumm bleibt. Ein Teil des Kopfs überwacht '
          'es.',
    ),
    LessonSection(
      heading: 'Blöcke statt Dauerbereitschaft',
      body: 'Der Ausweg ist nicht mehr Disziplin, sondern eine andere '
          'Einteilung: feste Zeiträume, in denen niemand durchkommt, und '
          'andere, in denen man erreichbar ist. Das ist wieder eine '
          'Umgebungsentscheidung, keine Willensfrage — dieselbe Logik wie '
          'beim Auslöser einer Gewohnheit.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was kostet beim sogenannten Multitasking am meisten?',
      options: <String>[
        'Die einzelnen Aufgaben selbst',
        'Der Wechsel zwischen den Aufgaben',
        'Die Zahl der offenen Programme',
        'Die Dauer der Arbeitszeit',
      ],
      correctIndex: 1,
      explanation: 'Bei jedem Sprung bleibt ein Teil der Aufmerksamkeit an der '
          'vorigen Aufgabe hängen. Die volle Tiefe braucht danach Minuten.',
    ),
    Question(
      prompt: 'Warum stört ein stummes Handy auf dem Tisch trotzdem?',
      options: <String>[
        'Weil es Strahlung abgibt',
        'Weil man es unbewusst überwacht',
        'Weil es den Blick verstellt',
        'Es stört nicht, solange es stumm ist',
      ],
      correctIndex: 1,
      explanation:
          'Schon die Erwartung einer Unterbrechung bindet Aufmerksamkeit. '
          'Ein Teil des Kopfs hält Wache, auch wenn nichts passiert.',
    ),
    Question(
      prompt: 'Was ist der praktikable Ausweg?',
      options: <String>[
        'Mehr Disziplin beim Ignorieren',
        'Feste Blöcke ohne Erreichbarkeit',
        'Schnelleres Beantworten von Nachrichten',
        'Kürzere Arbeitsphasen',
      ],
      correctIndex: 1,
      explanation:
          'Erreichbarkeit einmal einzuteilen wirkt jeden Tag weiter. Sich '
          'jedes Mal zusammenzureißen wirkt nur einmal.',
    ),
  ],
);

const Lesson _gedanken = Lesson(
  id: 'geist-02-gedanken',
  title: 'Gedanken sind keine Tatsachen',
  summary: 'Wie man Abstand zu dem gewinnt, was der Kopf behauptet.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Im Kopf sitzt ein Erzähler',
      body: 'Das Gehirn erklärt ununterbrochen, was gerade passiert — und es '
          'tut das schnell, nicht genau. „Sie hat nicht geantwortet, also ist '
          'sie sauer" fühlt sich nicht wie eine Vermutung an, sondern wie '
          'eine Beobachtung. Der Unterschied zwischen beidem zu bemerken, '
          'ist die eigentliche Fähigkeit.',
    ),
    LessonSection(
      heading: 'Zwei häufige Muster',
      body: 'Katastrophisieren: aus einem Rückschlag wird sofort das '
          'schlimmste Ende gedacht. Alles-oder-nichts: eine ausgelassene '
          'Einheit macht das ganze Vorhaben zunichte. Beide Muster erkennt '
          'man an ihrer Sprache — „immer", „nie", „komplett", „alles '
          'umsonst". Wer diese Wörter bei sich hört, hat einen Anhaltspunkt.',
    ),
    LessonSection(
      heading: 'Abstand statt Widerspruch',
      body: 'Es hilft wenig, einen Gedanken zu bekämpfen. Es hilft, ihn als '
          'Gedanken zu benennen: nicht „Ich schaffe das nie", sondern „Ich '
          'habe gerade den Gedanken, dass ich das nie schaffe." Der Inhalt '
          'ändert sich dadurch nicht, der Abstand schon — und aus Abstand '
          'lässt sich handeln.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was ist die eigentliche Fähigkeit im Umgang mit Gedanken?',
      options: <String>[
        'Negative Gedanken zu unterdrücken',
        'Vermutung von Beobachtung zu unterscheiden',
        'Immer positiv zu denken',
        'Gedanken schriftlich zu widerlegen',
      ],
      correctIndex: 1,
      explanation: 'Der Erzähler im Kopf liefert Deutungen, die sich wie '
          'Beobachtungen anfühlen. Den Unterschied zu bemerken, ist der '
          'entscheidende Schritt.',
    ),
    Question(
      prompt: 'Woran erkennt man Katastrophisieren und Alles-oder-nichts '
          'im Alltag?',
      options: <String>[
        'An der Lautstärke der Gedanken',
        'An Wörtern wie „immer", „nie", „alles umsonst"',
        'Daran, dass sie abends auftreten',
        'Sie sind nicht erkennbar',
      ],
      correctIndex: 1,
      explanation:
          'Beide Muster haben eine typische Sprache. Diese Wörter bei sich '
          'zu hören ist ein brauchbarer Anhaltspunkt.',
    ),
    Question(
      prompt: 'Was schafft Abstand zu einem belastenden Gedanken?',
      options: <String>[
        'Ihn als Gedanken benennen',
        'Ihn mit Gegenargumenten widerlegen',
        'Ihn bewusst ignorieren',
        'Ihn zu Ende denken',
      ],
      correctIndex: 0,
      explanation:
          '„Ich habe gerade den Gedanken, dass …" ändert den Inhalt nicht, '
          'aber die Position. Aus Abstand lässt sich handeln.',
    ),
  ],
);

const Lesson _unbehagen = Lesson(
  id: 'geist-03-unbehagen',
  title: 'Unbehagen aushalten',
  summary: 'Warum ein Drang von allein kleiner wird, wenn man wartet.',
  unlocksHabit: 'Fünf Minuten still sitzen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Drang ist eine Welle',
      body: 'Ein Verlangen — nach dem Handy, der Zigarette, dem Aufschieben — '
          'fühlt sich an, als würde es wachsen, bis man nachgibt. Tatsächlich '
          'steigt es an, erreicht einen Höhepunkt und fällt wieder ab, meist '
          'innerhalb weniger Minuten. Wer einmal bewusst zugesehen hat, weiß '
          'das danach aus eigener Erfahrung und nicht nur vom Hörensagen.',
    ),
    LessonSection(
      heading: 'Nachgeben ist ein Training',
      body: 'Jedes Nachgeben auf dem Höhepunkt lehrt den Kopf: So stark muss '
          'es werden, dann klappt es. Jedes Abwarten lehrt das Gegenteil. '
          'Deshalb wird es nicht mit der Zeit schwerer, sondern leichter — '
          'aber nur, wenn man das Warten tatsächlich übt.',
    ),
    LessonSection(
      heading: 'Üben, wenn nichts auf dem Spiel steht',
      body: 'Diese Fähigkeit lässt sich unabhängig vom Ernstfall trainieren. '
          'Fünf Minuten still sitzen, ohne die Position zu ändern, ohne zum '
          'Handy zu greifen, ist genau diese Übung im Kleinen: Unbehagen '
          'bemerken, nicht darauf reagieren, weitermachen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wie verläuft ein Verlangen typischerweise?',
      options: <String>[
        'Es wächst stetig, bis man nachgibt',
        'Es steigt an, erreicht einen Höhepunkt und fällt ab',
        'Es bleibt konstant, bis es befriedigt wird',
        'Es verschwindet sofort bei Ablenkung',
      ],
      correctIndex: 1,
      explanation:
          'Der Verlauf ist eine Welle, meist innerhalb weniger Minuten. Es '
          'fühlt sich nur an, als würde es endlos wachsen.',
    ),
    Question(
      prompt: 'Was lernt der Kopf, wenn man auf dem Höhepunkt nachgibt?',
      options: <String>[
        'Dass der Drang harmlos ist',
        'Dass er nur stark genug werden muss',
        'Dass Warten nichts bringt',
        'Er lernt daraus nichts',
      ],
      correctIndex: 1,
      explanation:
          'Nachgeben bestätigt das Muster und macht den nächsten Drang '
          'nicht schwächer. Abwarten lehrt das Gegenteil.',
    ),
    Question(
      prompt: 'Warum übt man still sitzen, wenn gar nichts auf dem Spiel '
          'steht?',
      options: <String>[
        'Um Zeit zu sparen',
        'Weil es im Ernstfall zu spät zum Üben ist',
        'Weil es entspannt',
        'Um die Konzentration zu messen',
      ],
      correctIndex: 1,
      explanation:
          'Die Fähigkeit, Unbehagen zu bemerken und nicht zu reagieren, '
          'lässt sich im Kleinen trainieren — dort, wo ein Fehler nichts '
          'kostet.',
    ),
  ],
);

import '../branch.dart';
import '../lesson.dart';

/// Zweig „Wissenschaft" — wie man Behauptungen prüft und sich selbst testet.
///
/// Der Zweig, der die anderen absichert: Wer ihn durch hat, kann die
/// Ratschläge aus „Körper" und „Geist" selbst überprüfen, statt sie zu
/// glauben.
const TheoryBranch wissenschaftBranch = TheoryBranch(
  id: 'wissenschaft',
  name: 'Wissenschaft',
  description:
      'Wie man erkennt, ob eine Behauptung trägt — und wie man am eigenen '
      'Leben sauber ausprobiert, was wirklich wirkt.',
  unlockLevel: 4,
  lessons: <Lesson>[_evidenz, _korrelation, _selbstversuch],
);

const Lesson _evidenz = Lesson(
  id: 'wissenschaft-01-evidenz',
  title: 'Woher weißt du das?',
  summary: 'Der Unterschied zwischen Erzählung, Beobachtung und Experiment.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Drei Sorten von Belegen',
      body:
          'Eine Anekdote ist ein Einzelfall: „Bei mir hat das geholfen." Eine '
          'Beobachtungsstudie zählt viele Fälle, ohne einzugreifen: „Menschen '
          'mit dieser Gewohnheit sind gesünder." Ein Experiment greift ein '
          'und vergleicht mit einer Kontrollgruppe: „Wir haben die eine '
          'Hälfte das tun lassen, die andere nicht." Nur die dritte Form '
          'kann eine Ursache zeigen.',
    ),
    LessonSection(
      heading: 'Wer wurde eigentlich untersucht',
      body: 'Ein Ergebnis gilt zunächst nur für die Gruppe, an der es gewonnen '
          'wurde. Was an zwanzig jungen Leistungssportlern gemessen wurde, '
          'sagt wenig über einen Fünfzigjährigen mit Bürojob. Auch die Zahl '
          'zählt: Bei zwanzig Personen ist ein auffälliges Ergebnis oft '
          'Zufall, bei zweitausend selten.',
    ),
    LessonSection(
      heading: 'Die Frage, die fast immer hilft',
      body: '„Woher weiß ich das?" — und gleich hinterher: „Was müsste ich '
          'sehen, wenn es nicht stimmt?" Wer auf die zweite Frage keine '
          'Antwort findet, hat keine überprüfbare Aussage vor sich, sondern '
          'eine Überzeugung. Das ist nicht automatisch falsch, aber es ist '
          'etwas anderes.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Welche Form von Beleg kann eine Ursache zeigen?',
      options: <String>[
        'Die Anekdote einer einzelnen Person',
        'Das Experiment mit Kontrollgruppe',
        'Die Beobachtungsstudie ohne Eingriff',
        'Alle drei Formen gleichermaßen',
      ],
      correctIndex: 1,
      explanation:
          'Nur wer eingreift und mit einer Vergleichsgruppe misst, kann '
          'Ursache von Begleiterscheinung trennen.',
    ),
    Question(
      prompt: 'Ein Ergebnis stammt von zwanzig jungen Leistungssportlern. '
          'Was folgt daraus?',
      options: <String>[
        'Es gilt ohne Weiteres für alle Menschen',
        'Es ist für den Alltag vollkommen wertlos',
        'Es gilt besonders für untrainierte Menschen',
        'Es gilt zunächst nur für ähnliche Personen',
      ],
      correctIndex: 3,
      explanation:
          'Ein Ergebnis gilt für die untersuchte Gruppe. Die Übertragung '
          'auf andere ist eine zusätzliche Annahme, die begründet werden '
          'muss.',
    ),
    Question(
      prompt: 'Was zeigt die Frage „Was müsste ich sehen, wenn es nicht '
          'stimmt?"',
      options: <String>[
        'Ob die Aussage überprüfbar ist',
        'Ob die Aussage populär ist',
        'Ob die Quelle seriös ist',
        'Ob genügend Personen untersucht wurden',
      ],
      correctIndex: 0,
      explanation:
          'Wer darauf keine Antwort findet, hat eine Überzeugung vor sich, '
          'keine prüfbare Aussage. Das ist nicht automatisch falsch, aber '
          'etwas anderes.',
    ),
  ],
);

const Lesson _korrelation = Lesson(
  id: 'wissenschaft-02-korrelation',
  title: 'Zusammenhang ist keine Ursache',
  summary: 'Warum zwei Kurven gleich aussehen können, ohne zusammenzuhängen.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Gleicher Verlauf, kein Zusammenhang',
      body: 'Zwei Größen können über Jahre parallel verlaufen, ohne '
          'irgendetwas miteinander zu tun zu haben. Bei genügend vielen '
          'Datenreihen findet sich für fast jede eine zweite, die ähnlich '
          'aussieht. Ein gleicher Verlauf ist deshalb ein Anlass '
          'nachzusehen, kein Ergebnis.',
    ),
    LessonSection(
      heading: 'Die dritte Größe',
      body: 'Menschen, die viel frühstücken, sind im Schnitt schlanker. Daraus '
          'folgt nicht, dass Frühstücken schlank macht. Wer regelmäßig '
          'frühstückt, hat oft auch geregelte Tagesabläufe, schläft besser '
          'und bewegt sich mehr. Die dritte Größe erklärt beides — und wird '
          'in der Schlagzeile nie erwähnt.',
    ),
    LessonSection(
      heading: 'Und die Richtung?',
      body: 'Selbst wenn ein echter Zusammenhang besteht, ist offen, wohin er '
          'zeigt. Macht Sport zufrieden, oder gehen zufriedene Menschen '
          'eher joggen? Beides ist plausibel, und oft gilt beides '
          'gleichzeitig. Erst ein Eingriff — eine Gruppe fängt an, die '
          'andere nicht — trennt das auf.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was bedeutet es, wenn zwei Kurven ähnlich verlaufen?',
      options: <String>[
        'Die eine Größe verursacht sicher die andere',
        'Es ist ein Anlass nachzusehen, kein Ergebnis',
        'Der Zusammenhang ist damit schon bewiesen',
        'Die Daten sind mit hoher Wahrscheinlichkeit falsch',
      ],
      correctIndex: 1,
      explanation:
          'Bei genügend vielen Datenreihen findet sich fast immer eine '
          'ähnlich verlaufende zweite. Der gleiche Verlauf ist ein Hinweis, '
          'kein Beleg.',
    ),
    Question(
      prompt: 'Frühstücker sind im Schnitt schlanker. Was ist die '
          'wahrscheinlichste Erklärung?',
      options: <String>[
        'Eine dritte Größe wie ein geregelter Tagesablauf erklärt beides',
        'Das Frühstück beschleunigt den Stoffwechsel für den ganzen Tag',
        'Schlanke Menschen haben am Morgen einfach mehr Hunger als andere',
        'Der beobachtete Zusammenhang ist am Ende reiner Zufall',
      ],
      correctIndex: 0,
      explanation: 'Wer regelmäßig frühstückt, hat meist auch sonst geregelte '
          'Abläufe. Diese dritte Größe erklärt beide Beobachtungen.',
    ),
    Question(
      prompt: 'Was klärt die Richtung eines Zusammenhangs?',
      options: <String>[
        'Eine deutlich größere Stichprobe',
        'Eine längere Beobachtungszeit',
        'Ein Eingriff mit Vergleichsgruppe',
        'Eine deutlich bessere Statistik',
      ],
      correctIndex: 2,
      explanation:
          'Nur wenn eine Gruppe etwas tut und eine vergleichbare nicht, '
          'lässt sich sagen, was woraus folgt.',
    ),
  ],
);

const Lesson _selbstversuch = Lesson(
  id: 'wissenschaft-03-selbstversuch',
  title: 'Sich selbst testen',
  summary: 'Wie ein Selbstversuch aussieht, dem man glauben kann.',
  unlocksHabit: 'Eine Messgröße täglich notieren',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Eine Änderung auf einmal',
      body: 'Wer gleichzeitig früher aufsteht, Kaffee weglässt und mit Sport '
          'anfängt, weiß hinterher nicht, was gewirkt hat. Es fühlt sich '
          'nach schnellerem Fortschritt an, liefert aber kein Wissen. Eine '
          'Änderung, sauber getestet, ist mehr wert als drei gleichzeitig.',
    ),
    LessonSection(
      heading: 'Vorher messen, sonst ist es Erinnerung',
      body: 'Ohne Ausgangswert bleibt nur der Vergleich mit dem Gedächtnis — '
          'und das passt sich an das an, was man erwartet. Wer zwei Wochen '
          'vorher notiert, wie er schläft, hat danach eine Zahl statt eines '
          'Eindrucks. Eine einzige Messgröße reicht dafür völlig, solange '
          'sie täglich erhoben wird.',
    ),
    LessonSection(
      heading: 'Lang genug laufen lassen',
      body:
          'Die ersten Tage einer Umstellung sind untypisch: Neuigkeitseffekt, '
          'Umgewöhnung, besondere Aufmerksamkeit. Zwei bis vier Wochen sind '
          'ein brauchbarer Zeitraum. Wer nach drei Tagen entscheidet, misst '
          'vor allem seine eigene Begeisterung.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Warum sollte man nur eine Sache auf einmal ändern?',
      options: <String>[
        'Weil mehrere Änderungen zu anstrengend sind',
        'Weil man sonst nicht weiß, was gewirkt hat',
        'Weil der Körper sich nur einmal umstellen kann',
        'Weil es schneller geht',
      ],
      correctIndex: 1,
      explanation: 'Mehrere gleichzeitige Änderungen fühlen sich nach mehr '
          'Fortschritt an, liefern aber kein Wissen darüber, was davon '
          'gewirkt hat.',
    ),
    Question(
      prompt: 'Warum reicht der Vergleich mit der eigenen Erinnerung nicht?',
      options: <String>[
        'Weil man einzelne Details mit der Zeit vergisst',
        'Weil Erinnerungen fast immer zu positiv sind',
        'Weil man den betrachteten Zeitraum verwechselt',
        'Weil die Erinnerung sich an die Erwartung anpasst',
      ],
      correctIndex: 3,
      explanation: 'Das Gedächtnis rückt das Vorher in die Richtung, die zur '
          'Erwartung passt. Ein notierter Ausgangswert tut das nicht.',
    ),
    Question(
      prompt: 'Was misst jemand vor allem, der nach drei Tagen entscheidet?',
      options: <String>[
        'Die Wirkung der Änderung',
        'Seine eigene Begeisterung',
        'Den Placeboeffekt der Umgebung',
        'Die Genauigkeit seiner Messung',
      ],
      correctIndex: 1,
      explanation: 'Die ersten Tage sind durch Neuigkeit und besondere '
          'Aufmerksamkeit verzerrt. Zwei bis vier Wochen sind brauchbar.',
    ),
  ],
);

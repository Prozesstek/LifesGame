/// Neue Knotenseiten für Wissenschaft und Gesellschaft (ADR-0019).
///
/// Die fehlenden zwei Unterknoten je Wurzel, damit beide auf die von
/// Issue #16 geforderten fünf kommen.
library;

import '../lesson.dart';

const Lesson stichprobePage = Lesson(
  id: 'wissenschaft-04-stichprobe',
  title: 'Wie viele Fälle braucht eine Behauptung?',
  summary: 'Warum kleine Zahlen große Geschichten erzeugen.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Zufall sieht aus wie ein Muster',
      body:
          'Wirft man zehnmal eine Münze, kommt eine Serie von vier gleichen '
          'Ergebnissen erstaunlich oft vor. Wer nur diese vier sieht, hält '
          'sie für eine Regel. Je kleiner die Zahl der Fälle, desto '
          'wilder schwanken die Ergebnisse — und desto überzeugender wirkt '
          'ein Muster, das keines ist.',
    ),
    LessonSection(
      heading: 'Die Geschichte des Einzelfalls',
      body:
          '„Bei mir hat das sofort geholfen" ist eine Stichprobe von eins. '
          'Sie ist nicht wertlos, aber sie erlaubt keine Aussage darüber, '
          'ob es bei jemand anderem hilft. Genau diese Verwechslung trägt '
          'den größten Teil der Ratgeberliteratur.',
    ),
    LessonSection(
      heading: 'Was man daraus mitnimmt',
      body:
          'Die nützliche Frage lautet nicht „wirkt es?", sondern „bei wie '
          'vielen wurde das geprüft, und wie unterschiedlich waren die?". '
          'Eine ehrliche Antwort darauf sortiert mehr aus als jede '
          'Detaildiskussion über Methoden.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was passiert mit den Ergebnissen bei wenigen Fällen?',
      options: <String>[
        'Sie schwanken stärker und sehen zufällig nach Mustern aus',
        'Sie werden genauer',
        'Sie werden unbrauchbar',
      ],
      correctIndex: 0,
      explanation:
          'Kleine Zahlen erzeugen Serien, die wie Regeln aussehen. Das ist '
          'kein Fehler der Messung, sondern des Blicks darauf.',
    ),
    Question(
      prompt: 'Wie groß ist die Stichprobe bei „bei mir hat es geholfen"?',
      options: <String>['Groß genug', 'Kommt darauf an', 'Eins'],
      correctIndex: 2,
      explanation:
          'Ein Einzelfall ist ein Hinweis, keine Aussage über andere. Der '
          'Unterschied ist der Kern dieses Knotens.',
    ),
    Question(
      prompt: 'Welche Frage sortiert am meisten aus?',
      options: <String>[
        'Wer behauptet das?',
        'Bei wie vielen wurde es geprüft, und wie verschieden waren die?',
        'Ist das schon lange bekannt?',
      ],
      correctIndex: 1,
      explanation:
          'Zahl und Vielfalt der Fälle entscheiden, ob ein Befund über die '
          'geprüfte Gruppe hinaus etwas bedeutet.',
    ),
  ],
);

const Lesson studieLesenPage = Lesson(
  id: 'wissenschaft-05-studie-lesen',
  title: 'Eine Überschrift ist keine Studie',
  summary: 'Was zwischen Ergebnis und Schlagzeile passiert.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Weg verzerrt',
      body:
          'Zwischen einem Ergebnis und der Überschrift, die du liest, '
          'liegen mehrere Stationen: die Studie selbst, die Mitteilung der '
          'Hochschule, die Meldung einer Agentur, die Überschrift der '
          'Redaktion. Jede Station hat einen Anreiz, die Aussage etwas '
          'größer zu machen.',
    ),
    LessonSection(
      heading: 'Drei Dinge, die fast immer fehlen',
      body:
          'Wie viele Personen es waren. Woran genau gemessen wurde. Und wie '
          'groß der Unterschied war — nicht ob es einen gab. „Deutlich '
          'besser" kann ein Vorsprung von zwei Prozent sein.',
    ),
    LessonSection(
      heading: 'Ein billiger Test',
      body:
          'Suche die Zusammenfassung der Studie selbst und vergleiche sie '
          'mit der Überschrift. Das dauert wenige Minuten und ist die '
          'wirksamste Übung dieses Zweigs — weil der Abstand zwischen '
          'beiden regelmäßig überrascht.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Warum wächst eine Aussage auf dem Weg zur Überschrift?',
      options: <String>[
        'Weil Studien ungenau geschrieben sind',
        'Weil jede Station einen Anreiz hat, sie größer zu machen',
        'Weil Übersetzungen fehlerhaft sind',
      ],
      correctIndex: 1,
      explanation:
          'Hochschule, Agentur und Redaktion wollen alle Aufmerksamkeit. '
          'Der Effekt summiert sich über die Stationen.',
    ),
    Question(
      prompt: 'Welche Angabe fehlt am häufigsten?',
      options: <String>[
        'Wie groß der Unterschied war',
        'Wann die Studie erschien',
        'Wer sie geschrieben hat',
      ],
      correctIndex: 0,
      explanation:
          '„Es gab einen Unterschied" sagt nichts darüber, ob er '
          'irgendjemanden interessieren sollte.',
    ),
    Question(
      prompt: 'Was ist der billigste wirksame Test?',
      options: <String>[
        'Die Kommentare lesen',
        'Eine zweite Quelle suchen',
        'Die Zusammenfassung der Studie mit der Überschrift vergleichen',
      ],
      correctIndex: 2,
      explanation:
          'Der Abstand zwischen beiden ist in wenigen Minuten sichtbar und '
          'überrascht regelmäßig.',
    ),
  ],
);

const Lesson vergleichPage = Lesson(
  id: 'gesellschaft-04-vergleich',
  title: 'Vergleichen mit einem Zerrbild',
  summary: 'Warum der Maßstab von außen fast immer falsch ist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Du siehst Ergebnisse, nicht Wege',
      body:
          'Von anderen sieht man das Ergebnis: den Abschluss, den Körper, '
          'die ruhige Familie. Den Weg dorthin sieht man nicht — die Jahre, '
          'die Umstände, die Hilfe, das Scheitern dazwischen. Verglichen '
          'wird also der eigene Weg mit fremden Ergebnissen.',
    ),
    LessonSection(
      heading: 'Die Auswahl ist verzerrt',
      body:
          'Was sichtbar wird, ist vorsortiert: Erfolge werden gezeigt, '
          'Rückschläge selten. Wer daraus einen Durchschnitt bildet, '
          'bekommt einen Maßstab, den in Wirklichkeit fast niemand '
          'erreicht — auch die nicht, die ihn scheinbar setzen.',
    ),
    LessonSection(
      heading: 'Der brauchbare Maßstab',
      body:
          'Der einzige Vergleich mit verlässlicher Grundlage ist der mit '
          'dir vor einem Monat. Dort kennst du beides: das Ergebnis und den '
          'Weg. Genau deshalb zeigt dieses Spiel eine Kette und einen '
          'Bestwert und keine Rangliste.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was vergleicht man beim Blick auf andere tatsächlich?',
      options: <String>[
        'Den eigenen Weg mit fremden Ergebnissen',
        'Zwei Wege miteinander',
        'Zwei Ergebnisse miteinander',
      ],
      correctIndex: 0,
      explanation:
          'Der fremde Weg ist unsichtbar. Damit fehlt genau die Hälfte, die '
          'den Vergleich fair machen würde.',
    ),
    Question(
      prompt: 'Warum ist der sichtbare Durchschnitt zu hoch?',
      options: <String>[
        'Weil Menschen übertreiben',
        'Weil Erfolge gezeigt und Rückschläge verschwiegen werden',
        'Weil es zu viele Menschen gibt',
      ],
      correctIndex: 1,
      explanation:
          'Die Auswahl ist vorsortiert. Der Maßstab, der daraus entsteht, '
          'wird auch von den scheinbaren Vorbildern nicht erreicht.',
    ),
    Question(
      prompt: 'Welcher Vergleich hat eine verlässliche Grundlage?',
      options: <String>[
        'Mit dem Durchschnitt',
        'Mit den Besten des Fachs',
        'Mit dir selbst vor einem Monat',
      ],
      correctIndex: 2,
      explanation:
          'Nur dort kennst du Ergebnis und Weg. Deshalb zeigt das Spiel '
          'eine Kette und einen Bestwert statt einer Rangliste.',
    ),
  ],
);

const Lesson hilfeBittenPage = Lesson(
  id: 'gesellschaft-05-hilfe-bitten',
  title: 'Um Hilfe bitten ist eine Fertigkeit',
  summary: 'Warum die meisten zu selten fragen — und wie man es besser macht.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Die Ablehnung wird überschätzt',
      body:
          'Menschen sagen deutlich häufiger zu, als Fragende erwarten. Wer '
          'sich vorstellt, abgelehnt zu werden, überschätzt diese '
          'Wahrscheinlichkeit regelmäßig — und fragt deshalb gar nicht '
          'erst. Die Absage, die man fürchtet, tritt seltener ein als die '
          'Hilfe, die man dadurch verpasst.',
    ),
    LessonSection(
      heading: 'Vage Bitten sind schwer zu erfüllen',
      body:
          '„Kannst du mir mal helfen?" zwingt den anderen, den Aufwand zu '
          'schätzen — und im Zweifel schätzt er hoch. „Hast du Dienstag '
          'zwanzig Minuten, um über eine Seite zu schauen?" ist beantwortbar. '
          'Je klarer die Bitte, desto leichter das Ja.',
    ),
    LessonSection(
      heading: 'Fragen schafft Verbindung',
      body:
          'Wer um einen kleinen Gefallen bittet und sich bedankt, wird als '
          'sympathischer erlebt, nicht als lästig. Eine Bitte ist ein '
          'Vertrauensbeweis — und sie macht es dem anderen leichter, '
          'seinerseits zu fragen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was schätzen die meisten Menschen beim Fragen falsch ein?',
      options: <String>[
        'Wie lange es dauert',
        'Wie oft sie abgelehnt werden',
        'Wie wichtig die Sache ist',
      ],
      correctIndex: 1,
      explanation:
          'Zusagen kommen häufiger als erwartet. Die überschätzte Absage '
          'verhindert die Frage.',
    ),
    Question(
      prompt: 'Warum ist eine vage Bitte schwerer zu erfüllen?',
      options: <String>[
        'Weil der andere den Aufwand schätzen muss und hoch schätzt',
        'Weil sie unhöflich wirkt',
        'Weil sie zu lang ist',
      ],
      correctIndex: 0,
      explanation:
          'Unklarheit erzeugt Vorsicht. Ein konkreter Rahmen macht das Ja '
          'billig.',
    ),
    Question(
      prompt: 'Wie wirkt eine kleine Bitte auf die Beziehung?',
      options: <String>[
        'Sie belastet sie',
        'Sie verändert nichts',
        'Sie wirkt als Vertrauensbeweis und erleichtert Gegenseitigkeit',
      ],
      correctIndex: 2,
      explanation:
          'Wer gefragt wird, fühlt sich zugetraut. Das macht es beiden '
          'Seiten leichter, künftig zu fragen.',
    ),
  ],
);

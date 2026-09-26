/// Die Seiten der Zwischenebenen (ADR-0050).
///
/// **Eine Zwischenebene ist ein Gebiet im Gebiet** — „Kraft & Muskulatur"
/// unter Körper, „Beziehungen" unter Gesellschaft. Sie kostet einen Punkt
/// wie jeder Knoten, und der Punkt kauft eine Einführung, nicht nur eine
/// Tür: Jede dieser Seiten beantwortet, **worum es in dem Gebiet geht und
/// was darin zu lernen ist**.
///
/// Die achte Zwischenebene, Psychologie, hat keine eigene Seite hier: Sie
/// ist die alte Seite „Was ist Psychologie", die genau das schon tat.
///
/// **Entwürfe von Claude, gegengelesen von Frederik** (ADR-0050, Punkt 3).
library;

import '../lesson.dart';

const Lesson kraftPage = Lesson(
  id: 'koerper-10-kraft',
  title: 'Kraft & Muskulatur',
  summary: 'Wie ein Muskel stärker wird — und wann.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Ein Muskel passt sich an',
      body: 'Muskeln wachsen nicht, weil man trainiert, sondern weil sie '
          'etwas gefordert hat, das sie noch nicht gewohnt waren. Bleibt die '
          'Last immer gleich, gibt es keinen Grund zur Anpassung. Deshalb '
          'steigert gutes Training die Anforderung langsam — mehr Gewicht, '
          'mehr Wiederholungen oder mehr Sätze. Das heißt progressive '
          'Überlastung.',
    ),
    LessonSection(
      heading: 'Gewachsen wird in der Pause',
      body: 'Das Training selbst ermüdet den Muskel und macht ihn kurzfristig '
          'schwächer. Stärker wird er danach, wenn er sich erholt und dabei '
          'etwas über den alten Stand hinaus aufbaut. Wer die Pause '
          'weglässt, trainiert nur die Ermüdung. Schlaf und Eiweiß gehören '
          'deshalb genauso zum Training wie die Hantel.',
    ),
    LessonSection(
      heading: 'Kraft hat mehrere Gesichter',
      body: 'Maximalkraft ist, wie viel man einmal bewegen kann. Schnellkraft '
          'ist, wie schnell man Kraft aufbauen kann, etwa beim Sprung. '
          'Kraftausdauer ist, wie lange man eine Last immer wieder bewegen '
          'kann. Jede davon wird etwas anders trainiert — und in diesem '
          'Gebiet geht es um alle drei.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was bringt einen Muskel dazu, sich anzupassen?',
      options: <String>[
        'Eine Last, die immer genau gleich bleibt',
        'Eine Last, die er noch nicht gewohnt ist',
        'Möglichst viele Trainingstage ohne Pause',
      ],
      correctIndex: 1,
      explanation: 'Ohne neuen Reiz gibt es keinen Grund zur Anpassung. Die '
          'Steigerung darf klein sein, aber sie muss da sein.',
    ),
    Question(
      prompt: 'Wann wird der Muskel tatsächlich stärker?',
      options: <String>[
        'In der Erholung nach dem Training',
        'Während der letzten Wiederholung',
        'Sobald das Training anstrengend wird',
      ],
      correctIndex: 0,
      explanation:
          'Das Training setzt den Reiz, die Erholung baut auf. Direkt nach '
          'dem Training ist der Muskel schwächer als vorher.',
    ),
    Question(
      prompt: 'Was beschreibt die Kraftausdauer?',
      options: <String>[
        'Wie viel Gewicht man ein einziges Mal hebt',
        'Wie schnell man beim Sprung Kraft aufbaut',
        'Wie lange man eine Last wiederholt bewegt',
      ],
      correctIndex: 2,
      explanation:
          'Das Erste ist die Maximalkraft, das Zweite die Schnellkraft. '
          'Kraftausdauer misst das Durchhalten.',
    ),
  ],
);

const Lesson ernaehrungPage = Lesson(
  id: 'koerper-11-ernaehrung',
  title: 'Ernährung',
  summary: 'Was Essen dem Körper liefert: Energie und Baustoff.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Drei große Nährstoffe',
      body: 'Eiweiß, Kohlenhydrate und Fett liefern fast die ganze Energie aus '
          'dem Essen. Kohlenhydrate und Fett sind vor allem Brennstoff. '
          'Eiweiß ist dazu Baustoff: Aus ihm baut der Körper Muskeln, Enzyme '
          'und vieles mehr. Keiner der drei ist böse — es kommt auf Menge '
          'und Herkunft an.',
    ),
    LessonSection(
      heading: 'Die kleinen Dinge',
      body: 'Vitamine und Mineralstoffe liefern kaum Energie, sind aber für '
          'fast jeden Vorgang im Körper nötig. Man braucht sie in kleinen '
          'Mengen, dafür regelmäßig. Wer abwechslungsreich isst, mit viel '
          'Gemüse und Obst, deckt die meisten davon ohne Nachrechnen.',
    ),
    LessonSection(
      heading: 'Die Energiebilanz',
      body: 'Der Körper verbraucht auch in Ruhe Energie — das ist der '
          'Grundumsatz. Dazu kommt, was Bewegung kostet. Wer dauerhaft mehr '
          'isst, als er verbraucht, speichert den Rest. Das ist keine Frage '
          'der Moral, sondern eine Rechnung, die über Wochen aufgeht, nicht '
          'über einen einzelnen Tag.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Welcher Nährstoff ist vor allem Baustoff für Muskeln?',
      options: <String>[
        'Eiweiß',
        'Zucker',
        'Wasser',
      ],
      correctIndex: 0,
      explanation:
          'Kohlenhydrate und Fett sind vor allem Brennstoff. Eiweiß liefert '
          'die Bausteine, aus denen der Körper Gewebe baut.',
    ),
    Question(
      prompt: 'Was zeichnet Vitamine und Mineralstoffe aus?',
      options: <String>[
        'Sie liefern den größten Teil der täglichen Energie',
        'Sie werden nur beim Sport überhaupt benötigt',
        'Sie werden in kleinen Mengen, aber stetig gebraucht',
      ],
      correctIndex: 2,
      explanation:
          'Energie liefern sie kaum. Gebraucht werden sie trotzdem jeden '
          'Tag, für fast jeden Vorgang im Körper.',
    ),
    Question(
      prompt: 'Was ist der Grundumsatz?',
      options: <String>[
        'Was der Körper beim Sport zusätzlich verbraucht',
        'Was der Körper in völliger Ruhe verbraucht',
        'Was man an einem Tag höchstens essen darf',
      ],
      correctIndex: 1,
      explanation:
          'Auch im Liegen arbeiten Herz, Gehirn und Organe. Bewegung kommt '
          'obendrauf.',
    ),
  ],
);

const Lesson schlafRegenerationPage = Lesson(
  id: 'koerper-12-schlaf-regeneration',
  title: 'Schlaf & Regeneration',
  summary: 'Wie sich der Körper erholt, und was ihn dabei stört.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Schlaf hat Phasen',
      body: 'Eine Nacht besteht aus mehreren Zyklen von etwa anderthalb '
          'Stunden. In jedem wechseln leichter Schlaf, Tiefschlaf und '
          'REM-Schlaf, in dem man am lebhaftesten träumt. Der Tiefschlaf '
          'liegt eher früh in der Nacht, der REM-Schlaf eher gegen Morgen. '
          'Wer die Nacht kürzt, verliert also nicht von allem gleich viel.',
    ),
    LessonSection(
      heading: 'Die innere Uhr',
      body: 'Der Körper folgt einem Rhythmus von ungefähr vierundzwanzig '
          'Stunden. Gestellt wird diese Uhr vor allem durch Licht: Helles '
          'Licht am Morgen macht wach, Dunkelheit am Abend lässt den Körper '
          'Melatonin ausschütten, das Signal für die Nacht. Helle Bildschirme '
          'spät am Abend schieben dieses Signal nach hinten.',
    ),
    LessonSection(
      heading: 'Erholung ist mehr als Schlaf',
      body: 'Auch am Tag braucht der Körper Phasen, in denen nichts verlangt '
          'wird. Ruhe, ein Spaziergang oder lockere Bewegung helfen, sich '
          'von Belastung zu erholen. In diesem Gebiet geht es darum, wie '
          'Schlaf, Stress und Pausen zusammenhängen — und wo man ansetzt.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wie ist eine Nacht Schlaf aufgebaut?',
      options: <String>[
        'Aus einem einzigen langen Tiefschlaf am Stück',
        'Aus mehreren Zyklen von je etwa anderthalb Stunden',
        'Aus Traumphasen allein, die sich immer wiederholen',
      ],
      correctIndex: 1,
      explanation: 'In jedem Zyklus wechseln leichter Schlaf, Tiefschlaf und '
          'REM-Schlaf. Ihr Anteil verschiebt sich über die Nacht.',
    ),
    Question(
      prompt: 'Was stellt die innere Uhr vor allem?',
      options: <String>[
        'Das Mittagessen',
        'Die Raumwärme',
        'Das Tageslicht',
      ],
      correctIndex: 2,
      explanation:
          'Licht am Morgen macht wach, Dunkelheit am Abend lässt Melatonin '
          'steigen. Deshalb verschieben helle Bildschirme am Abend die Uhr.',
    ),
    Question(
      prompt: 'Was gehört neben dem Schlaf zur Erholung?',
      options: <String>[
        'Ruhige Phasen am Tag',
        'Mehr Training am Tag',
        'Kürzere Nächte dafür',
      ],
      correctIndex: 0,
      explanation:
          'Erholung braucht Zeiten, in denen nichts verlangt wird — auch '
          'tagsüber, nicht nur nachts.',
    ),
  ],
);

const Lesson selbstentwicklungPage = Lesson(
  id: 'geist-10-selbstentwicklung',
  title: 'Selbstentwicklung',
  summary: 'Sich selbst verstehen, um sich gezielt zu verändern.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Erst hinsehen',
      body: 'Veränderung beginnt mit der Frage, wie es gerade ist — nicht, wie '
          'es sein sollte. Wer ehrlich beobachtet, wann er aufschiebt, was '
          'ihm Kraft gibt und was sie nimmt, hat einen Ausgangspunkt. Ohne '
          'ihn arbeitet man an einem Bild von sich, das nicht stimmt.',
    ),
    LessonSection(
      heading: 'Ziele und Systeme',
      body: 'Ein Ziel sagt, wo man hinwill. Ein System sagt, was man jeden Tag '
          'tut. Zwei Menschen können dasselbe Ziel haben und ganz '
          'unterschiedlich weit kommen — der Unterschied liegt fast immer im '
          'System. Das Ziel gibt die Richtung, das System macht die Strecke.',
    ),
    LessonSection(
      heading: 'Worum es hier geht',
      body: 'In diesem Gebiet geht es um die Werkzeuge dafür: wie Gedanken '
          'wirken, wie man Unbehagen aushält, was Motivation wirklich ist. '
          'Kein Teil davon verlangt, ein anderer Mensch zu werden. Es geht '
          'darum, mit dem Menschen, der man ist, besser umzugehen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Womit beginnt gezielte Veränderung?',
      options: <String>[
        'Mit einem ehrlichen Blick darauf, wie es gerade ist',
        'Mit einem möglichst großen und mutigen Ziel für alles',
        'Mit dem Vorsatz, ab morgen ein neuer Mensch zu sein',
      ],
      correctIndex: 0,
      explanation:
          'Ohne Ausgangspunkt arbeitet man an einem Bild von sich, das '
          'nicht stimmt. Erst hinsehen, dann ändern.',
    ),
    Question(
      prompt: 'Was unterscheidet ein System von einem Ziel?',
      options: <String>[
        'Ein System ist immer viel größer als ein Ziel',
        'Ein System ist das, was man jeden Tag tut',
        'Ein System braucht man erst nach dem Ziel',
      ],
      correctIndex: 1,
      explanation:
          'Das Ziel gibt die Richtung vor. Wie weit man kommt, entscheidet '
          'das, was man täglich tut.',
    ),
    Question(
      prompt: 'Was verlangt Selbstentwicklung laut dieser Seite nicht?',
      options: <String>[
        'Sich selbst ehrlich zu beobachten',
        'Täglich etwas Kleines zu wiederholen',
        'Ein ganz anderer Mensch zu werden',
      ],
      correctIndex: 2,
      explanation:
          'Es geht darum, mit dem Menschen, der man ist, besser umzugehen — '
          'nicht darum, ihn auszutauschen.',
    ),
  ],
);

const Lesson beziehungenPage = Lesson(
  id: 'gesellschaft-10-beziehungen',
  title: 'Beziehungen',
  summary: 'Warum andere Menschen kein Beiwerk sind.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Menschen brauchen Menschen',
      body: 'Enge Beziehungen gehören zu den stärksten Einflüssen auf '
          'Gesundheit und Zufriedenheit, die die Forschung kennt. Dauerhafte '
          'Einsamkeit belastet den Körper ähnlich wie andere bekannte '
          'Risiken. Freundschaft ist deshalb kein Luxus für die Zeit, die '
          'übrig bleibt.',
    ),
    LessonSection(
      heading: 'Vertrauen entsteht im Kleinen',
      body: 'Vertrauen wächst selten durch große Gesten. Es wächst in vielen '
          'kleinen Momenten: zuhören, sich melden, halten, was man zugesagt '
          'hat. Jeder davon ist unscheinbar. Zusammen entscheiden sie, ob '
          'jemand da ist, wenn es darauf ankommt.',
    ),
    LessonSection(
      heading: 'Konflikte gehören dazu',
      body: 'Wo Menschen einander nahe sind, gibt es auch Reibung. Eine gute '
          'Beziehung ist nicht eine ohne Streit, sondern eine, in der Streit '
          'nichts kaputt macht. In diesem Gebiet geht es um Umfeld, '
          'Zugehörigkeit, Grenzen — und darum, um Hilfe zu bitten.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Welche Rolle spielen enge Beziehungen für die Gesundheit?',
      options: <String>[
        'Kaum eine, solange man sich gut ernährt',
        'Eine große, Einsamkeit belastet den Körper',
        'Nur eine im Alter, vorher ist es egal',
      ],
      correctIndex: 1,
      explanation:
          'Beziehungen gehören zu den stärksten Einflüssen auf Gesundheit, '
          'die man kennt — in jedem Alter.',
    ),
    Question(
      prompt: 'Wodurch wächst Vertrauen vor allem?',
      options: <String>[
        'Durch eine große Geste zur rechten Zeit',
        'Durch teure Geschenke zu jedem Anlass',
        'Durch viele kleine, verlässliche Momente',
      ],
      correctIndex: 2,
      explanation:
          'Zuhören, sich melden, Zusagen halten — einzeln unscheinbar, '
          'zusammen die Grundlage.',
    ),
    Question(
      prompt: 'Was macht eine gute Beziehung aus?',
      options: <String>[
        'Dass Streit darin nichts kaputt macht',
        'Dass es darin nie Streit geben darf',
        'Dass einer immer zuerst nachgibt',
      ],
      correctIndex: 0,
      explanation:
          'Reibung gehört zur Nähe. Entscheidend ist, wie man damit umgeht.',
    ),
  ],
);

const Lesson medienPage = Lesson(
  id: 'gesellschaft-11-medien',
  title: 'Medien & Information',
  summary: 'Wer entscheidet, was du zu sehen bekommst.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Aufmerksamkeit ist das Produkt',
      body: 'Viele Plattformen kosten kein Geld. Bezahlt wird mit Zeit und '
          'Aufmerksamkeit, die an Werbekunden weiterverkauft werden. Daraus '
          'folgt ein einfaches Ziel: Du sollst möglichst lange bleiben. '
          'Alles, was du dort siehst, ist auch daraufhin ausgewählt.',
    ),
    LessonSection(
      heading: 'Was der Algorithmus zeigt',
      body: 'Empfehlungen zeigen nicht, was wichtig oder wahr ist, sondern was '
          'Menschen wie dich bisher gehalten hat. Das sind oft Dinge, die '
          'aufregen, überraschen oder bestätigen, was man schon glaubt. So '
          'kann ein Bild der Welt entstehen, das schiefer ist als die Welt.',
    ),
    LessonSection(
      heading: 'Quellen prüfen',
      body:
          'Wer etwas behauptet, woher weiß er es, und was hat er davon? Diese '
          'zwei Fragen helfen bei fast jeder Nachricht. In diesem Gebiet '
          'geht es um Werbung, Desinformation, Informationsblasen — und '
          'darum, wie Vergleiche mit anderen im Netz auf einen wirken.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Womit bezahlt man bei vielen kostenlosen Plattformen?',
      options: <String>[
        'Mit Zeit und Aufmerksamkeit',
        'Mit einer versteckten Gebühr',
        'Mit gar nichts, sie sind frei',
      ],
      correctIndex: 0,
      explanation:
          'Die Aufmerksamkeit wird an Werbekunden verkauft. Deshalb ist das '
          'Ziel der Plattform, dass du bleibst.',
    ),
    Question(
      prompt: 'Was zeigen Empfehlungen vor allem?',
      options: <String>[
        'Was nachweislich am wichtigsten ist',
        'Was Menschen wie dich bisher gehalten hat',
        'Was zufällig gerade neu erschienen ist',
      ],
      correctIndex: 1,
      explanation:
          'Ausgewählt wird nach dem, was bindet — nicht nach dem, was wahr '
          'oder wichtig ist.',
    ),
    Question(
      prompt: 'Welche Frage hilft bei fast jeder Nachricht?',
      options: <String>[
        'Wie viele Menschen sie schon geteilt haben',
        'Ob sie mit einem Bild versehen worden ist',
        'Woher der Absender es weiß und was er davon hat',
      ],
      correctIndex: 2,
      explanation:
          'Viele Teilungen sagen nur, dass etwas bewegt — nicht, ob es '
          'stimmt. Herkunft und Absicht sagen mehr.',
    ),
  ],
);

const Lesson denkenPage = Lesson(
  id: 'wissenschaft-10-denken',
  title: 'Wissenschaftliches Denken',
  summary: 'Nicht was man weiß, sondern wie man es herausfindet.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Prüfen statt glauben',
      body: 'Wissenschaft ist weniger ein Haufen Fakten als eine Methode: eine '
          'Vermutung aufstellen, sie so prüfen, dass sie scheitern könnte, '
          'und dem Ergebnis glauben statt dem Wunsch. Diese Methode lässt '
          'sich auf fast alles anwenden, auch auf den eigenen Alltag.',
    ),
    LessonSection(
      heading: 'Eine gute Behauptung kann scheitern',
      body: 'Eine Aussage, die zu jedem denkbaren Ergebnis passt, sagt nichts. '
          '„Dieses Mittel hilft, wenn man fest daran glaubt" lässt sich nie '
          'widerlegen — hilft es nicht, hat man eben nicht genug geglaubt. '
          'Brauchbar wird eine Behauptung erst, wenn man sagen kann, was sie '
          'widerlegen würde.',
    ),
    LessonSection(
      heading: 'Wissen ist vorläufig',
      body:
          'Was heute als gesichert gilt, kann sich mit besseren Daten ändern. '
          'Das ist keine Schwäche, sondern der Kern der Sache. In diesem '
          'Gebiet geht es um Quellen, Ursachen, Stichproben und Studien — und '
          'darum, sich selbst zu testen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was ist Wissenschaft vor allem?',
      options: <String>[
        'Eine große Sammlung fester Fakten',
        'Eine Methode, Vermutungen zu prüfen',
        'Die Meinung der meisten Fachleute',
      ],
      correctIndex: 1,
      explanation:
          'Fakten sind das Ergebnis. Der Kern ist die Methode, mit der man '
          'zu ihnen kommt.',
    ),
    Question(
      prompt: 'Wann ist eine Behauptung brauchbar?',
      options: <String>[
        'Wenn sie zu jedem möglichen Ergebnis passt',
        'Wenn viele Menschen sie schon lange glauben',
        'Wenn man sagen kann, was sie widerlegen würde',
      ],
      correctIndex: 2,
      explanation:
          'Was zu allem passt, sagt nichts voraus. Erst die Möglichkeit zu '
          'scheitern macht eine Aussage prüfbar.',
    ),
    Question(
      prompt: 'Warum ändert sich wissenschaftliches Wissen manchmal?',
      options: <String>[
        'Weil bessere Daten alte Annahmen ersetzen',
        'Weil Forschende sich gern widersprechen',
        'Weil frühere Forschung stets falsch war',
      ],
      correctIndex: 0,
      explanation:
          'Vorläufigkeit ist der Kern der Methode: Man hält fest, was die '
          'Daten tragen, und ändert es, wenn sie mehr zeigen.',
    ),
  ],
);

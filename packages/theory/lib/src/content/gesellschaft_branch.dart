import '../branch.dart';
import '../lesson.dart';

/// Zweig „Gesellschaft" — Umfeld, Zugehörigkeit, Grenzen.
///
/// Der letzte Zweig des ersten Baums. Er behandelt den Faktor, der die
/// anderen drei überschreibt: Wer sich umgibt, wie er lebt, muss weniger
/// kämpfen.
const TheoryBranch gesellschaftBranch = TheoryBranch(
  id: 'gesellschaft',
  name: 'Gesellschaft',
  description:
      'Umfeld, Zugehörigkeit, Grenzen. Der Teil des Fortschritts, der nicht '
      'im Kopf des Einzelnen entschieden wird.',
  unlockLevel: 5,
  lessons: <Lesson>[_umfeld, _zugehoerigkeit, _grenzen],
);

const Lesson _umfeld = Lesson(
  id: 'gesellschaft-01-umfeld',
  title: 'Du wirst zum Durchschnitt deiner Umgebung',
  summary: 'Warum Verhalten ansteckender ist, als es sich anfühlt.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Verhalten überträgt sich',
      body: 'Essgewohnheiten, Rauchen, Sport, sogar die Einstellung zu Geld — '
          'all das ähnelt sich innerhalb von Gruppen weit über den Zufall '
          'hinaus. Das passiert nicht durch Überredung, sondern durch '
          'Normalität: Was im Umfeld üblich ist, wird zum Maßstab dafür, was '
          'man selbst für normal hält.',
    ),
    LessonSection(
      heading: 'Nähe zählt mehr als Absicht',
      body: 'Entscheidend ist nicht, wen man bewundert, sondern mit wem man '
          'Zeit verbringt. Ein Vorbild, das man nur liest, verändert wenig. '
          'Drei Kollegen, mit denen man täglich Mittag isst, verändern viel '
          '— unabhängig davon, ob man das will.',
    ),
    LessonSection(
      heading: 'Umgebung ist wählbar',
      body: 'Das klingt entmutigend, ist aber der stärkste Hebel im ganzen '
          'Baum. Wer sein Umfeld ändert, muss sich anschließend deutlich '
          'seltener zusammenreißen — die neue Normalität übernimmt einen '
          'Teil der Arbeit. Das ist dieselbe Logik wie beim Auslöser einer '
          'Gewohnheit, nur eine Stufe größer.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wie überträgt sich Verhalten in Gruppen hauptsächlich?',
      options: <String>[
        'Durch bewusste Überredung',
        'Durch offenen Wettbewerb',
        'Darüber, was als normal gilt',
        'Durch klare Absprachen vorab',
      ],
      correctIndex: 2,
      explanation: 'Was im Umfeld üblich ist, wird zum Maßstab für das eigene '
          'Normal. Überredung braucht es dafür nicht.',
    ),
    Question(
      prompt: 'Was prägt stärker: ein bewundertes Vorbild oder tägliche '
          'Kollegen?',
      options: <String>[
        'Die Kollegen, weil Nähe mehr zählt als Absicht',
        'Das Vorbild, weil es bewusst gewählt ist',
        'Beides prägt am Ende ungefähr gleich stark',
        'Weder noch — nur die eigene Einstellung zählt',
      ],
      correctIndex: 0,
      explanation:
          'Wer täglich anwesend ist, verschiebt den Maßstab. Ein Vorbild, '
          'das man nur liest, tut das kaum.',
    ),
    Question(
      prompt: 'Warum ist das Umfeld ein Hebel und keine Ausrede?',
      options: <String>[
        'Weil es sich im Alltag ohnehin nicht ändern lässt',
        'Weil man es sich zu einem großen Teil aussuchen kann',
        'Weil Willenskraft am Ende stärker wirkt als es',
        'Weil es am Ende nur bequeme Ausreden dafür liefert',
      ],
      correctIndex: 1,
      explanation: 'Eine geänderte Umgebung übernimmt einen Teil der Arbeit — '
          'dieselbe Logik wie beim Auslöser, nur eine Stufe größer.',
    ),
  ],
);

const Lesson _zugehoerigkeit = Lesson(
  id: 'gesellschaft-02-zugehoerigkeit',
  title: 'Zugehörigkeit hält länger als Vorsatz',
  summary: 'Warum Gewohnheiten in Gruppen überleben und allein abreißen.',
  unlocksHabit: 'Einem Menschen täglich eine echte Frage stellen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Zwei Kräfte statt einer',
      body: 'Wer allein trainiert, hält es durch, solange die Motivation '
          'reicht. Wer in einer Gruppe trainiert, hält es auch dann durch, '
          'wenn sie nicht reicht — weil jemand fragt, wo er war. Die '
          'Gewohnheit hängt dann nicht mehr allein am eigenen Willen, '
          'sondern zusätzlich an einer Beziehung.',
    ),
    LessonSection(
      heading: 'Die richtige Gruppe erkennen',
      body: 'Nützlich ist eine Gruppe, in der das gewünschte Verhalten '
          'normal ist und niemand dafür bewundert wird. Wo Laufen '
          'selbstverständlich ist, läuft man mit. Wo es als Leistung gilt, '
          'bleibt es eine Anstrengung, die man erbringen oder lassen kann.',
    ),
    LessonSection(
      heading: 'Sichtbarkeit verpflichtet',
      body: 'Schon eine einzige Person, die Bescheid weiß, verändert das '
          'Verhalten messbar. Es braucht keine Gruppe und keinen Vertrag — '
          'es reicht, dass jemand nachfragen könnte. Genau das macht ein '
          'geteilter Fortschritt in dieser App: Er macht sichtbar, was sonst '
          'nur im eigenen Kopf stattfindet.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was hält eine Gewohnheit in der Gruppe zusätzlich am Leben?',
      options: <String>[
        'Der Wettbewerb um Bestleistungen',
        'Die geteilten Kosten der Gruppe',
        'Der feste Termin für sich allein',
        'Die Beziehung — jemand fragt nach',
      ],
      correctIndex: 3,
      explanation: 'Allein trägt nur die Motivation. In der Gruppe kommt eine '
          'Beziehung dazu, die auch dann trägt, wenn Motivation fehlt.',
    ),
    Question(
      prompt: 'Woran erkennt man eine nützliche Gruppe?',
      options: <String>[
        'Das gewünschte Verhalten ist dort selbstverständlich',
        'Das gewünschte Verhalten gilt dort als besondere Leistung',
        'Sie ist möglichst groß und steht wirklich jedem offen',
        'Sie trifft sich möglichst oft und regelmäßig',
      ],
      correctIndex: 0,
      explanation:
          'Wird das Verhalten bewundert, bleibt es eine Anstrengung. Ist '
          'es normal, macht man es einfach mit.',
    ),
    Question(
      prompt: 'Wie viele Mitwisser braucht es, damit Sichtbarkeit wirkt?',
      options: <String>[
        'Eine ganze Gruppe',
        'Mindestens eine Handvoll',
        'Eine einzige Person reicht',
        'Sichtbarkeit wirkt gar nicht',
      ],
      correctIndex: 2,
      explanation:
          'Es reicht, dass jemand nachfragen könnte. Ein Vertrag oder eine '
          'Gruppe ist dafür nicht nötig.',
    ),
  ],
);

const Lesson _grenzen = Lesson(
  id: 'gesellschaft-03-grenzen',
  title: 'Nein sagen, ohne zu streiten',
  summary: 'Warum jedes Ja anderswo ein Nein ist.',
  unlocksHabit: 'Vor jeder Zusage einmal durchatmen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Jedes Ja ist ein Nein',
      body: 'Zeit lässt sich nicht vermehren. Wer zusagt, sagt damit '
          'gleichzeitig etwas anderem ab — nur ist das andere im Moment der '
          'Zusage nicht im Raum. Deshalb fällt Zusagen leicht und das '
          'Ergebnis später schwer. Die Frage ist nie „Will ich das tun?", '
          'sondern „Wovon nehme ich die Zeit?"',
    ),
    LessonSection(
      heading: 'Kurz, klar, ohne Begründungskette',
      body: 'Lange Rechtfertigungen laden zum Verhandeln ein: Jeder Grund, den '
          'man nennt, lässt sich entkräften. Ein Nein ohne Begründung wirkt '
          'zunächst härter, führt aber seltener zu Streit. „Das geht bei mir '
          'nicht" ist vollständig. Wer möchte, ergänzt eine Alternative — '
          'aber keine Verteidigung.',
    ),
    LessonSection(
      heading: 'Der Preis des Dauer-Ja',
      body: 'Wer nie ablehnt, wirkt eine Weile verlässlich und wird danach '
          'unzuverlässig — weil irgendwann etwas platzt. Das kostet mehr '
          'Vertrauen als ein rechtzeitiges Nein. Ein kurzer Moment vor der '
          'Zusage genügt meist, um beides zu vermeiden.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was ist die eigentliche Frage bei einer Anfrage?',
      options: <String>[
        'Will ich das überhaupt tun?',
        'Wovon nehme ich die Zeit?',
        'Wer genau hat gefragt?',
        'Wie lange dauert das wohl?',
      ],
      correctIndex: 1,
      explanation:
          'Zeit lässt sich nicht vermehren. Jedes Ja ist zugleich ein Nein '
          'zu etwas, das im Moment der Zusage nicht im Raum steht.',
    ),
    Question(
      prompt: 'Warum lädt eine ausführliche Begründung zum Verhandeln ein?',
      options: <String>[
        'Weil sie auf den anderen sehr unhöflich wirkt',
        'Weil sie im Gespräch einfach zu lange dauert',
        'Weil jeder genannte Grund entkräftet werden kann',
        'Weil sie für den anderen unglaubwürdig klingt',
      ],
      correctIndex: 2,
      explanation:
          'Wer Gründe liefert, liefert Angriffsflächen. Ein kurzes Nein '
          'wirkt härter, führt aber seltener zu Streit.',
    ),
    Question(
      prompt: 'Was passiert langfristig bei jemandem, der nie ablehnt?',
      options: <String>[
        'Er wird unzuverlässig, weil irgendwann etwas platzt',
        'Er gilt auf Dauer als besonders verlässlicher Mensch',
        'Er bekommt mit der Zeit deutlich weniger Anfragen',
        'Er lernt mit der Zeit, schneller zu arbeiten',
      ],
      correctIndex: 0,
      explanation: 'Ein geplatzter Termin kostet mehr Vertrauen als ein '
          'rechtzeitiges Nein.',
    ),
  ],
);

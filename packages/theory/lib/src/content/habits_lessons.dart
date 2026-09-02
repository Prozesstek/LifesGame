import '../lesson.dart';

/// Die fünf Lektionen des Zweigs „Gewohnheiten“, in Reihenfolge.
///
/// Reiner Inhalt, keine Logik. Wer hier schreibt, braucht kein Flutter und
/// keine laufende App — `dart test` im Package prüft die Struktur.
const List<Lesson> habitsLessons = <Lesson>[
  _systemeSchlagenVorsaetze,
  _dieSchleife,
  _zweiMinuten,
  _nieZweimal,
  _identitaet,
];

// ---------------------------------------------------------------------------
// 1
// ---------------------------------------------------------------------------

const Lesson _systemeSchlagenVorsaetze = Lesson(
  id: 'habits-01-systeme',
  title: 'Systeme schlagen Vorsätze',
  summary: 'Warum ein klares Ziel allein fast nie reicht.',
  unlocksHabit: 'Drei Aufgaben für morgen festlegen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Wissen ist selten das Problem',
      body: 'Fast jeder weiß, was er tun müsste: sich mehr bewegen, früher '
          'ins Bett, weniger am Handy hängen. Trotzdem passiert es nicht. '
          'Das liegt nicht an fehlender Einsicht, sondern daran, dass die '
          'Einsicht an einem müden Dienstagabend nichts entscheidet. '
          'Entschieden wird durch das, was in dem Moment am nächsten liegt.',
    ),
    LessonSection(
      heading: 'Ein Ziel sagt nicht, was du heute tust',
      body: '„Zehn Kilo abnehmen“ ist ein Ergebnis, keine Handlung. Es legt '
          'nicht fest, wann du losgehst, wie lange, und was passiert, wenn '
          'es regnet. Ein System beantwortet genau diese Fragen im Voraus, '
          'damit du sie nicht jedes Mal neu verhandelst. Verhandeln kostet '
          'Kraft, und die ist abends am knappsten.',
    ),
    LessonSection(
      heading: 'Der Maßstab verschiebt sich',
      body: 'Wer in Zielen denkt, ist bis zum Ziel erfolglos und danach '
          'orientierungslos. Wer in Systemen denkt, hat heute Abend eine '
          'klare Antwort auf die Frage, ob der Tag gezählt hat: Habe ich '
          'getan, was ich mir vorgenommen hatte? Genau das ist es, was '
          'diese App abhakt — nicht das Ergebnis, sondern die Wiederholung.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Warum reicht ein klar formuliertes Ziel meist nicht aus?',
      options: <String>[
        'Weil ein Ziel nicht festlegt, was du heute konkret tust',
        'Weil Ziele fast immer zu ehrgeizig gesteckt werden',
        'Weil Ziele schriftlich festgehalten werden müssen',
        'Weil Ziele mit der Zeit die Motivation eher senken',
      ],
      correctIndex: 0,
      explanation:
          'Ein Ziel beschreibt ein Ergebnis. Die Lücke zwischen Ergebnis '
          'und heutigem Abend füllt es nicht — das macht erst ein System, '
          'das Zeitpunkt, Ort und Umfang vorab festlegt.',
    ),
    Question(
      prompt: 'Was ist der praktische Vorteil, Entscheidungen vorab zu '
          'treffen?',
      options: <String>[
        'Man kann sie später gegenüber anderen besser begründen',
        'Man wird dadurch ganz von selbst deutlich motivierter',
        'Man braucht danach im Alltag überhaupt keine Pausen',
        'Man spart Kraft, weil man im Moment nicht neu verhandelt',
      ],
      correctIndex: 3,
      explanation: 'Jede offene Entscheidung kostet Willenskraft, und die ist '
          'ausgerechnet dann knapp, wenn die Gewohnheit ansteht. Vorab '
          'festgelegt, entfällt die Verhandlung.',
    ),
    Question(
      prompt: 'Woran misst jemand seinen Fortschritt, der in Systemen denkt?',
      options: <String>[
        'Am erreichten Endergebnis nach einem ganzen Jahr',
        'Daran, ob er heute getan hat, was vorgesehen war',
        'Am Vergleich mit den Ergebnissen der anderen',
        'An der Höhe seiner Motivation an diesem Tag',
      ],
      correctIndex: 1,
      explanation:
          'Die Wiederholung ist der Maßstab. Das Ergebnis folgt daraus, '
          'lässt sich aber tageweise nicht steuern — die Wiederholung schon.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// 2
// ---------------------------------------------------------------------------

const Lesson _dieSchleife = Lesson(
  id: 'habits-02-schleife',
  title: 'Die Schleife hinter jeder Gewohnheit',
  summary: 'Auslöser, Routine, Belohnung — und wo du eingreifen kannst.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Drei Teile, immer dieselben',
      body: 'Jede Gewohnheit läuft in derselben Schleife ab. Ein Auslöser '
          'startet sie: eine Uhrzeit, ein Ort, ein Gefühl, eine andere '
          'Handlung. Dann folgt die Routine, das eigentliche Verhalten. '
          'Am Ende steht eine Belohnung, die dem Gehirn sagt: Das war '
          'brauchbar, merk dir den Auslöser.',
    ),
    LessonSection(
      heading: 'Der Auslöser ist der Hebel',
      body: 'An der Routine herumzuschrauben ist mühsam — sie kostet Kraft, '
          'jedes Mal. Am Auslöser zu arbeiten ist billiger. Wer die '
          'Laufschuhe abends neben die Tür stellt, hat den Auslöser '
          'sichtbar gemacht. Wer das Handy aus dem Schlafzimmer verbannt, '
          'hat einen entfernt. Beides wirkt, ohne dass man morgens '
          'disziplinierter sein müsste.',
    ),
    LessonSection(
      heading: 'Ankoppeln statt neu erfinden',
      body: 'Der verlässlichste Auslöser ist etwas, das du ohnehin jeden Tag '
          'tust. „Nach dem Zähneputzen mache ich zehn Kniebeugen“ ist '
          'stabiler als „Ich mache morgens Sport“, weil das Zähneputzen '
          'bereits fest sitzt. Die neue Gewohnheit erbt die Verlässlichkeit '
          'der alten.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Aus welchen drei Teilen besteht eine Gewohnheitsschleife?',
      options: <String>[
        'Vorsatz, Plan, Kontrolle',
        'Auslöser, Routine, Belohnung',
        'Wunsch, Anstrengung, Ergebnis',
        'Ziel, Zwischenziel, Abschluss',
      ],
      correctIndex: 1,
      explanation: 'Der Auslöser startet, die Routine ist das Verhalten, die '
          'Belohnung sorgt dafür, dass sich das Gehirn den Auslöser merkt.',
    ),
    Question(
      prompt: 'Warum lohnt es sich, am Auslöser anzusetzen statt an der '
          'Routine?',
      options: <String>[
        'Weil die Routine für die ganze Gewohnheit unwichtig ist',
        'Weil Auslöser deutlich mehr Belohnung mit sich bringen',
        'Weil man eine feste Routine im Nachhinein nicht ändern kann',
        'Weil der Auslöser sich einmalig ändern lässt und danach wirkt',
      ],
      correctIndex: 3,
      explanation:
          'Die Umgebung einmal umzustellen wirkt jeden Tag weiter. Sich '
          'jeden Tag zusammenzureißen wirkt nur an diesem einen Tag.',
    ),
    Question(
      prompt: 'Was macht „Nach dem Zähneputzen zehn Kniebeugen“ stabiler '
          'als „Morgens Sport machen“?',
      options: <String>[
        'Es hängt an einer Handlung, die bereits fest sitzt',
        'Es ist anstrengender und damit deutlich wirksamer',
        'Es nennt eine feste Uhrzeit am frühen Morgen',
        'Es ist insgesamt das erheblich kleinere Ziel',
      ],
      correctIndex: 0,
      explanation: 'Die neue Gewohnheit koppelt an eine bestehende an und erbt '
          'deren Verlässlichkeit. „Morgens“ ist dagegen kein Auslöser, '
          'sondern ein Zeitraum.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// 3
// ---------------------------------------------------------------------------

const Lesson _zweiMinuten = Lesson(
  id: 'habits-03-zwei-minuten',
  title: 'Zwei Minuten reichen',
  summary: 'Wie man die Einstiegshürde so klein macht, dass sie hält.',
  unlocksHabit: 'Zwei Minuten lesen',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der teuerste Teil ist der Anfang',
      body: 'Nicht das Training ist schwer, sondern das Anziehen der Schuhe. '
          'Nicht das Lesen, sondern das Aufschlagen des Buchs. Wer schon '
          'angefangen hat, macht meistens weiter — die Hürde liegt fast '
          'immer am Anfang, nicht in der Mitte.',
    ),
    LessonSection(
      heading: 'Schrumpfen, bis es lächerlich wirkt',
      body: 'Die Zwei-Minuten-Regel: Formuliere die Gewohnheit so klein, dass '
          'sie in zwei Minuten erledigt ist. „Eine Seite lesen.“ „Die '
          'Sportsachen anziehen.“ Das fühlt sich zu wenig an, und genau '
          'das ist der Punkt — was zu klein zum Scheitern ist, überlebt '
          'auch schlechte Tage.',
    ),
    LessonSection(
      heading: 'Erst die Wiederholung, dann der Umfang',
      body: 'Zwei Minuten trainieren keine Ausdauer, aber sie etablieren die '
          'Handlung. Wer sechs Wochen lang jeden Tag zwei Minuten liest, '
          'hat etwas, das man ausbauen kann. Wer sechs Wochen lang '
          'vorhatte, eine Stunde zu lesen, hat nichts. Der Umfang lässt '
          'sich später erhöhen, die verlorenen Wochen nicht.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wo sitzt bei den meisten Gewohnheiten die eigentliche Hürde?',
      options: <String>[
        'In der Mitte, wenn es anstrengend wird',
        'Am Ende, kurz vor dem letzten Abschluss',
        'Am Anfang, beim Einstieg in die Handlung',
        'Bei der Planung am Abend des Vortags',
      ],
      correctIndex: 2,
      explanation: 'Wer angefangen hat, macht meist weiter. Deshalb zielt die '
          'Zwei-Minuten-Regel genau auf den Einstieg.',
    ),
    Question(
      prompt: 'Was ist der Sinn davon, eine Gewohnheit lächerlich klein zu '
          'formulieren?',
      options: <String>[
        'Sie bringt dann schneller Ergebnisse',
        'Sie überlebt auch schlechte Tage',
        'Sie ist leichter zu messen',
        'Sie erfordert weniger Planung',
      ],
      correctIndex: 1,
      explanation:
          'Eine Gewohnheit, die zu klein zum Scheitern ist, reißt auch '
          'dann nicht ab, wenn der Tag schlecht lief. Die Kette bleibt '
          'ganz — und darum geht es am Anfang.',
    ),
    Question(
      prompt: 'Was kommt zuerst: Umfang oder Wiederholung?',
      options: <String>[
        'Der Umfang — sonst bringt die ganze Sache gar nichts',
        'Die Wiederholung — der Umfang lässt sich später erhöhen',
        'Beides gleichzeitig, sonst dauert es viel zu lang',
        'Das hängt allein vom jeweiligen Ziel und Umfang ab',
      ],
      correctIndex: 1,
      explanation:
          'Eine etablierte Handlung lässt sich ausbauen. Eine Handlung, '
          'die nie stattgefunden hat, nicht.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// 4
// ---------------------------------------------------------------------------

const Lesson _nieZweimal = Lesson(
  id: 'habits-04-nie-zweimal',
  title: 'Nie zweimal hintereinander',
  summary: 'Was einen Ausrutscher von einem Abbruch unterscheidet.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der erste Ausfall ist ein Unfall',
      body: 'Jeder verpasst Tage. Krankheit, Reise, ein Tag, an dem alles '
          'schiefgeht. Ein einzelner ausgelassener Tag verändert an einer '
          'Gewohnheit fast nichts — die Wirkung entsteht über Wochen, nicht '
          'über einen Dienstag.',
    ),
    LessonSection(
      heading: 'Der zweite ist der Anfang vom Ende',
      body: 'Gefährlich wird der Tag danach. Zweimal ausgelassen ist keine '
          'Ausnahme mehr, sondern das neue Muster. Deshalb die Regel: nie '
          'zweimal hintereinander. Nicht „nie auslassen“ — das hält '
          'niemand ein und macht den ersten Ausfall zur Niederlage.',
    ),
    LessonSection(
      heading: 'Alles-oder-nichts kostet mehr als der Ausfall',
      body: 'Wer eine Kette von 60 Tagen reißen sieht und daraufhin ganz '
          'aufhört, hat sich für den einen verlorenen Tag mit sechzig '
          'bestraft. Der Wiedereinstieg am nächsten Tag ist deshalb '
          'wichtiger als die perfekte Serie. In dieser App wird ein '
          'verpasster Tag nicht bestraft — der Bonus fehlt einfach.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wie lautet die Regel für verpasste Tage?',
      options: <String>[
        'Nie einen einzigen Tag auslassen',
        'Verpasste Tage am Wochenende nachholen',
        'Nie zweimal hintereinander auslassen',
        'Nach drei Ausfällen neu anfangen',
      ],
      correctIndex: 2,
      explanation: '„Nie auslassen“ hält niemand durch und macht den ersten '
          'Ausfall zur Niederlage. „Nie zweimal“ lässt Raum für schlechte '
          'Tage, ohne das Muster zu verlieren.',
    ),
    Question(
      prompt: 'Warum ist der zweite ausgelassene Tag gefährlicher als der '
          'erste?',
      options: <String>[
        'Weil aus der Ausnahme ein neues Muster wird',
        'Weil der Rückstand dann einfach zu groß wird',
        'Weil die Belohnung dann endgültig ausbleibt',
        'Weil man den Auslöser danach vergisst',
      ],
      correctIndex: 0,
      explanation: 'Einmal ist ein Unfall, zweimal ist der Anfang einer neuen '
          'Gewohnheit — nämlich der, es nicht zu tun.',
    ),
    Question(
      prompt: 'Was ist der eigentliche Schaden am Alles-oder-nichts-Denken?',
      options: <String>[
        'Es macht die ganze Gewohnheit auf Dauer viel anstrengender',
        'Es verwandelt einen verlorenen Tag in einen kompletten Abbruch',
        'Es verhindert, dass man den Fortschritt überhaupt misst',
        'Es führt auf Dauer zu vollkommen unrealistischen Zielen',
      ],
      correctIndex: 1,
      explanation:
          'Wer nach einem Ausfall ganz aufhört, bestraft sich für einen '
          'Tag mit allen folgenden. Der Wiedereinstieg zählt mehr als die '
          'ungebrochene Serie.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// 5
// ---------------------------------------------------------------------------

const Lesson _identitaet = Lesson(
  id: 'habits-05-identitaet',
  title: 'Wer du sein willst',
  summary: 'Warum Gewohnheiten haltbarer werden, wenn sie zu jemandem '
      'gehören.',
  unlocksHabit: 'Abendnotiz: ein Beleg für heute',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Zwei Arten, dasselbe zu wollen',
      body: '„Ich versuche, mit dem Rauchen aufzuhören“ und „Ich bin kein '
          'Raucher“ beschreiben dieselbe Absicht, aber nicht dieselbe '
          'Person. Im ersten Satz kämpft jemand gegen sich selbst. Im '
          'zweiten stellt sich die Frage gar nicht mehr.',
    ),
    LessonSection(
      heading: 'Jede Wiederholung ist ein Beleg',
      body: 'Man wird nicht durch eine Entscheidung zu jemandem, sondern '
          'durch die Sammlung kleiner Belege. Jedes Mal Sport ist ein '
          'Beleg dafür, sportlich zu sein. Kein einzelner davon überzeugt, '
          'aber sie summieren sich zu etwas, das sich nicht mehr wie '
          'Anstrengung anfühlt, sondern wie eine Tatsache.',
    ),
    LessonSection(
      heading: 'Rückwärts denken',
      body: 'Statt zu fragen „Was will ich erreichen?“ frage: „Wer müsste '
          'ich sein, damit das selbstverständlich ist?“ — und dann: „Was '
          'tut diese Person heute?“ Diese Frage liefert direkt die '
          'Gewohnheit. Sie ist auch der Grund, warum in dieser App der '
          'Charakter mitwächst: Der Fortschritt gehört zu jemandem.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was unterscheidet „Ich versuche aufzuhören“ von „Ich bin '
          'kein Raucher“?',
      options: <String>[
        'Der zweite Satz ist einfach das deutlich festere Ziel',
        'Der erste Satz ist am Ende die ehrlichere Beschreibung',
        'Zwischen beiden gibt es keinen praktischen Unterschied',
        'Der zweite Satz beschreibt eine Person statt eines Kampfs',
      ],
      correctIndex: 3,
      explanation: 'Im ersten Satz steht die Entscheidung jedes Mal neu zur '
          'Debatte. Im zweiten ist sie Teil der Person und stellt sich '
          'nicht mehr.',
    ),
    Question(
      prompt: 'Welche Rolle spielt die einzelne Wiederholung für die '
          'Identität?',
      options: <String>[
        'Sie entscheidet ganz allein über den Erfolg',
        'Sie ist am Ende nur eine symbolische Geste',
        'Sie ist ein Beleg, der sich mit anderen summiert',
        'Sie ersetzt das eigentliche Ziel vollständig',
      ],
      correctIndex: 2,
      explanation: 'Kein einzelner Beleg überzeugt. Die Summe schon — deshalb '
          'zählt Häufigkeit mehr als Intensität.',
    ),
    Question(
      prompt: 'Welche Frage führt am direktesten zu einer konkreten '
          'Gewohnheit?',
      options: <String>[
        'Wer müsste ich sein — und was tut diese Person heute?',
        'Was genau will ich in einem Jahr erreicht haben?',
        'Was hat bei anderen Menschen bisher funktioniert?',
        'Wie viel Zeit habe ich am Tag dafür überhaupt übrig?',
      ],
      correctIndex: 0,
      explanation: 'Die Frage nach der Person übersetzt sich direkt in eine '
          'Handlung für heute. Die Frage nach dem Ergebnis tut das nicht.',
    ),
  ],
);

/// Die Themen unter **Psychologie** (ADR-0050).
///
/// Issue #54 hängt dieses Gebiet an Experimente — Asch, Milgram, den
/// Bystander-Effekt. Jede Seite erzählt deshalb einen Versuch und zieht
/// daraus, was er über den Alltag sagt. Wo ein berühmter Befund später
/// eingeschränkt wurde, steht das mit da: Eine App über Wissenschaft darf
/// keine Legenden weitererzählen.
///
/// **Entwürfe von Claude, gegengelesen von Frederik** (ADR-0050, Punkt 3).
library;

import '../lesson.dart';

const Lesson aschPage = Lesson(
  id: 'psych-01-asch',
  title: 'Die Macht der Mehrheit',
  summary: 'Warum Menschen einer Gruppe folgen, obwohl sie es besser sehen.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Drei Linien',
      body: 'In den 1950er-Jahren ließ Solomon Asch Versuchspersonen eine '
          'einfache Frage beantworten: Welche von drei Linien ist so lang '
          'wie eine vierte? Die Antwort war offensichtlich. Die anderen im '
          'Raum waren aber eingeweiht und nannten in manchen Runden '
          'einstimmig eine falsche Linie.',
    ),
    LessonSection(
      heading: 'Was geschah',
      body: 'In etwa einem Drittel dieser Runden schloss sich die '
          'Versuchsperson der falschen Mehrheit an, und rund drei von vier '
          'taten es mindestens einmal. Viele sagten hinterher, sie hätten '
          'gezweifelt, aber nicht auffallen wollen. Der Druck einer Gruppe '
          'wirkt auch dann, wenn niemand ihn ausspricht.',
    ),
    LessonSection(
      heading: 'Ein Verbündeter genügt',
      body: 'Sobald eine einzige andere Person die richtige Antwort gab, '
          'brach die Anpassung stark ein. Für den Alltag heißt das: Wer in '
          'einer Runde als Erster widerspricht, macht es allen anderen '
          'leichter. Und wer selbst zweifelt, ist selten der Einzige.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was war an der Aufgabe in Aschs Versuch besonders?',
      options: <String>[
        'Die richtige Antwort war völlig offensichtlich',
        'Die Aufgabe war so schwer, dass alle rieten',
        'Die Linien wurden nur für Sekunden gezeigt',
      ],
      correctIndex: 0,
      explanation:
          'Gerade weil die Antwort eindeutig war, zeigt der Versuch die '
          'Wirkung der Gruppe und nicht bloße Unsicherheit.',
    ),
    Question(
      prompt:
          'Wie viele Versuchspersonen folgten mindestens einmal der Mehrheit?',
      options: <String>[
        'Kaum jemand, fast alle blieben standhaft',
        'Rund drei von vier Versuchspersonen',
        'Ausnahmslos jede einzelne Person',
      ],
      correctIndex: 1,
      explanation:
          'Etwa drei Viertel passten sich mindestens einmal an, in rund '
          'einem Drittel aller kritischen Runden.',
    ),
    Question(
      prompt: 'Was schwächte die Anpassung am stärksten?',
      options: <String>[
        'Eine noch größere Gruppe von Eingeweihten',
        'Ein Geldpreis für jede falsche Antwort',
        'Eine einzige Person mit der richtigen Antwort',
      ],
      correctIndex: 2,
      explanation:
          'Ein Verbündeter reicht, damit die Anpassung stark einbricht. '
          'Der erste Widerspruch ist der schwerste.',
    ),
  ],
);

const Lesson milgramPage = Lesson(
  id: 'psych-02-milgram',
  title: 'Gehorsam',
  summary: 'Wie weit Menschen gehen, wenn eine Autorität es verlangt.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Versuch',
      body: 'Stanley Milgram ließ Anfang der 1960er-Jahre Versuchspersonen '
          'einem anderen Menschen scheinbar Stromstöße geben, die mit jeder '
          'falschen Antwort stärker wurden. Der „Schüler" war ein '
          'Schauspieler und bekam keinen Strom, aber er schrie und '
          'protestierte. Ein Versuchsleiter im Kittel sagte nur ruhig: '
          '„Bitte fahren Sie fort."',
    ),
    LessonSection(
      heading: 'Das Ergebnis',
      body: 'In der bekanntesten Fassung gingen rund zwei Drittel bis zur '
          'höchsten Stufe. Die meisten waren dabei sichtlich gequält und '
          'protestierten — und machten trotzdem weiter. Böse Absicht war '
          'selten das Problem, sondern das Gefühl, die Verantwortung liege '
          'bei jemand anderem.',
    ),
    LessonSection(
      heading: 'Was die Varianten zeigen',
      body: 'Milgram veränderte den Aufbau vielfach. Saß das Opfer im selben '
          'Raum, oder gab der Versuchsleiter Anweisungen nur per Telefon, '
          'sank der Gehorsam deutlich. Weigerten sich andere Teilnehmer, '
          'weigerten sich viele mit. Heute gilt der Versuch als ethisch '
          'grenzwertig — die Frage, die er stellt, ist geblieben.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wer war der „Schüler" in Milgrams Versuch?',
      options: <String>[
        'Ein zufällig ausgewählter zweiter Teilnehmer',
        'Ein eingeweihter Schauspieler ohne Stromstöße',
        'Der Versuchsleiter selbst in anderer Kleidung',
      ],
      correctIndex: 1,
      explanation:
          'Die Stromstöße waren nicht echt. Die Versuchspersonen hielten sie '
          'aber für echt — darauf kommt es an.',
    ),
    Question(
      prompt: 'Was trieb die meisten zum Weitermachen?',
      options: <String>[
        'Das Gefühl, die Verantwortung liege woanders',
        'Echte Freude daran, einem Fremden wehzutun',
        'Die Angst, selbst hart bestraft zu werden',
      ],
      correctIndex: 0,
      explanation:
          'Die meisten litten sichtlich. Sie gaben die Verantwortung an die '
          'Autorität ab, statt sie selbst zu tragen.',
    ),
    Question(
      prompt: 'Wann sank der Gehorsam deutlich?',
      options: <String>[
        'Wenn der Versuchsleiter einen Kittel trug',
        'Wenn die Stromstöße sehr langsam stiegen',
        'Wenn andere Teilnehmer sich offen weigerten',
      ],
      correctIndex: 2,
      explanation: 'Weigerung anderer, Nähe zum Opfer und eine ferne Autorität '
          'senkten den Gehorsam — wie der Verbündete bei Asch.',
    ),
  ],
);

const Lesson bystanderPage = Lesson(
  id: 'psych-03-bystander',
  title: 'Warum keiner hilft',
  summary: 'Der Bystander-Effekt — und was an ihm übertrieben wurde.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Verantwortung verteilt sich',
      body: 'In Versuchen von Darley und Latané Ende der 1960er-Jahre halfen '
          'Menschen einem scheinbar Kranken seltener und später, je mehr '
          'andere mutmaßlich zuhörten. Die Erklärung: Mit jedem weiteren '
          'Zeugen fühlt sich jeder Einzelne weniger zuständig. Man nennt '
          'das Verantwortungsdiffusion.',
    ),
    LessonSection(
      heading: 'Eine Legende weniger',
      body: 'Oft wird dazu der Fall von Kitty Genovese erzählt, bei dem 38 '
          'Nachbarn tatenlos zugesehen haben sollen. Diese Zahl hat sich '
          'als stark übertrieben erwiesen. Und Auswertungen echter '
          'Aufnahmen von Konflikten auf der Straße zeigen: Meist greift '
          'doch jemand ein, und in größeren Gruppen sogar eher.',
    ),
    LessonSection(
      heading: 'Was hilft',
      body: 'Wer Hilfe braucht, spricht am besten eine Person direkt an: „Sie '
          'in der blauen Jacke, rufen Sie bitte den Notruf." Damit ist die '
          'Zuständigkeit geklärt. Und wer zusieht, kann sich fragen, ob '
          'wirklich schon jemand hilft, oder ob nur alle darauf warten.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was beschreibt die Verantwortungsdiffusion?',
      options: <String>[
        'Mit mehr Zeugen fühlt sich jeder weniger zuständig',
        'Mit mehr Zeugen wird die Lage immer gefährlicher',
        'Mit mehr Zeugen helfen alle schneller als allein',
      ],
      correctIndex: 0,
      explanation:
          'Die Zuständigkeit verteilt sich auf viele — und am Ende fühlt '
          'sich keiner gemeint.',
    ),
    Question(
      prompt: 'Was ist an der Geschichte der 38 Zeugen dran?',
      options: <String>[
        'Sie ist bis ins letzte Detail genau belegt',
        'Die Zahl hat sich als stark übertrieben erwiesen',
        'Es waren in Wahrheit sogar deutlich mehr Zeugen',
      ],
      correctIndex: 1,
      explanation:
          'Die berühmte Zahl stimmt so nicht. Der Effekt in Versuchen ist '
          'real, die Legende darum ist es nicht.',
    ),
    Question(
      prompt: 'Wie bittet man in einer Menge am besten um Hilfe?',
      options: <String>[
        'Möglichst laut in die ganze Runde rufen',
        'Abwarten, bis jemand von selbst kommt',
        'Eine bestimmte Person direkt ansprechen',
      ],
      correctIndex: 2,
      explanation: 'Wer direkt gemeint ist, fühlt sich zuständig. Das hebt die '
          'Verteilung der Verantwortung auf.',
    ),
  ],
);

const Lesson gedaechtnisPage = Lesson(
  id: 'psych-04-gedaechtnis',
  title: 'Erinnerung ist kein Video',
  summary: 'Das Gedächtnis baut jede Erinnerung neu zusammen.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Ein Wort verändert den Unfall',
      body: 'Elizabeth Loftus zeigte Versuchspersonen in den 1970er-Jahren '
          'Filme von Autounfällen. Fragte man, wie schnell die Autos waren, '
          'als sie „ineinanderkrachten", schätzten die Leute höher als bei '
          '„zusammenstießen". Eine Woche später erinnerten sich mehr von '
          'ihnen an zerbrochenes Glas — das es im Film nicht gab.',
    ),
    LessonSection(
      heading: 'Erinnern heißt neu bauen',
      body: 'Das Gedächtnis speichert keine Aufnahme, die man später abspielt. '
          'Es speichert Bruchstücke und setzt sie beim Erinnern neu '
          'zusammen, ergänzt um das, was plausibel scheint. Jedes Erinnern '
          'kann die Erinnerung dabei ein wenig verändern.',
    ),
    LessonSection(
      heading: 'Was daraus folgt',
      body: 'Sich sicher zu fühlen, heißt nicht, recht zu haben. Das zeigt '
          'sich vor Gericht, wo Zeugenaussagen falsch sein können, obwohl '
          'niemand lügt, und im Streit darüber, wer was gesagt hat. Wer '
          'etwas Wichtiges behalten will, schreibt es früh auf.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was änderte in Loftus\' Versuch die Erinnerung an den Unfall?',
      options: <String>[
        'Die Farbe der Autos im gezeigten Film',
        'Das Wort in der Frage nach der Geschwindigkeit',
        'Die Länge der Pause vor der ersten Frage',
      ],
      correctIndex: 1,
      explanation:
          'Ein stärkeres Wort in der Frage führte zu höheren Schätzungen '
          'und sogar zu erinnertem Glas, das es nie gab.',
    ),
    Question(
      prompt: 'Wie arbeitet das Gedächtnis beim Erinnern?',
      options: <String>[
        'Es spielt eine genaue Aufnahme wieder ab',
        'Es löscht alles, was älter als ein Jahr ist',
        'Es setzt Bruchstücke jedes Mal neu zusammen',
      ],
      correctIndex: 2,
      explanation:
          'Erinnern ist Rekonstruieren. Was plausibel scheint, füllt die '
          'Lücken — und das Ergebnis fühlt sich trotzdem echt an.',
    ),
    Question(
      prompt:
          'Was sagt ein starkes Gefühl der Gewissheit über eine Erinnerung?',
      options: <String>[
        'Wenig darüber, ob sie wirklich stimmt',
        'Dass sie mit Sicherheit genau stimmt',
        'Dass sie aus der frühen Kindheit stammt',
      ],
      correctIndex: 0,
      explanation:
          'Gewissheit und Genauigkeit hängen schwächer zusammen, als man '
          'denkt. Aufschreiben hilft mehr als Sicherheit.',
    ),
  ],
);

const Lesson emotionenPage = Lesson(
  id: 'psych-05-emotionen',
  title: 'Gefühle regulieren',
  summary: 'Warum Umdeuten besser wirkt als Runterschlucken.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Gefühle sind Signale',
      body: 'Angst, Wut oder Trauer sind keine Fehler, sondern Hinweise: Etwas '
          'ist wichtig, bedrohlich oder verloren. Regulieren heißt nicht, '
          'sie abzuschalten, sondern zu beeinflussen, wie stark sie werden '
          'und was man daraufhin tut.',
    ),
    LessonSection(
      heading: 'Umdeuten statt Unterdrücken',
      body: 'Die Forschung von James Gross unterscheidet zwei Wege. Wer ein '
          'Gefühl nur unterdrückt, zeigt es nach außen weniger, fühlt es '
          'aber kaum schwächer und ist hinterher oft erschöpfter. Wer die '
          'Lage umdeutet — „die Prüfung ist eine Gelegenheit, nicht ein '
          'Urteil" —, fühlt tatsächlich anders.',
    ),
    LessonSection(
      heading: 'Benennen hilft',
      body: 'Schon das Gefühl in Worte zu fassen, „ich bin gerade wütend", '
          'dämpft es messbar. Wer genauer benennen kann, als nur „schlecht", '
          'hat mehr Möglichkeiten, damit umzugehen: Enttäuschung verlangt '
          'etwas anderes als Erschöpfung.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was heißt es, ein Gefühl zu regulieren?',
      options: <String>[
        'Es vollständig und dauerhaft abzuschalten',
        'Seine Stärke und die eigene Reaktion zu steuern',
        'Es allen anderen möglichst sofort mitzuteilen',
      ],
      correctIndex: 1,
      explanation:
          'Gefühle sind Signale. Regulieren beeinflusst, wie stark sie '
          'werden und was man daraus macht.',
    ),
    Question(
      prompt: 'Was bewirkt bloßes Unterdrücken meist?',
      options: <String>[
        'Man zeigt weniger, fühlt aber kaum weniger',
        'Das Gefühl verschwindet sofort ganz',
        'Man fühlt danach deutlich mehr Freude',
      ],
      correctIndex: 0,
      explanation:
          'Nach außen wird es leiser, innen kaum — und es kostet Kraft. '
          'Umdeuten verändert das Gefühl selbst.',
    ),
    Question(
      prompt: 'Warum hilft es, ein Gefühl genau zu benennen?',
      options: <String>[
        'Weil man es danach nie wieder spüren muss',
        'Weil andere einen dann nicht mehr fragen',
        'Weil es dämpft und passendere Wege eröffnet',
      ],
      correctIndex: 2,
      explanation:
          'Benennen dämpft das Gefühl, und ein genauer Name zeigt, was '
          'gerade wirklich gebraucht wird.',
    ),
  ],
);

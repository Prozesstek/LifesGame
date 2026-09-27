/// Die Themen unter **Ausdauer & Fitness** (ADR-0050).
///
/// Das zweite befüllte Gebiet, und die zweite Hälfte der alten
/// Schieflage: Neben Stärke hatte auch Ausdauer die wenigsten
/// Gewohnheitsvorlagen (Konzeptrunde 18.08.). Zahlen stehen als
/// Größenordnung da, nicht als Rezept.
///
/// **Entwürfe von Claude, gegengelesen von Frederik** (ADR-0050, Punkt 3).
library;

import '../lesson.dart';

const Lesson ausdauerPage = Lesson(
  id: 'koerper-13-ausdauer',
  title: 'Ausdauer & Fitness',
  summary: 'Wie lange der Körper durchhält — und wie man das ändert.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Ausdauer ist Versorgung',
      body: 'Ausdauer heißt, eine Belastung lange durchzuhalten. Dafür müssen '
          'Herz, Lunge und Blutgefäße die Muskeln laufend mit Sauerstoff '
          'versorgen, und die Muskeln müssen ihn verwerten können. Beides '
          'lässt sich trainieren — erstaunlich schnell, und in jedem Alter.',
    ),
    LessonSection(
      heading: 'Mehr als Sport',
      body: 'Gute Ausdauer zeigt sich nicht nur beim Laufen. Treppen, Tragen, '
          'ein langer Tag auf den Beinen werden leichter. Und kaum eine '
          'einzelne Größe hängt so deutlich mit einem langen, gesunden Leben '
          'zusammen wie die Ausdauerfähigkeit.',
    ),
    LessonSection(
      heading: 'Worum es hier geht',
      body: 'In diesem Gebiet geht es darum, wie das Herz arbeitet, was die '
          'Obergrenze der Ausdauer bestimmt, warum lockeres Training so '
          'wichtig ist, wofür harte Intervalle gut sind und woher der Körper '
          'seine Energie nimmt.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was muss für gute Ausdauer vor allem funktionieren?',
      options: <String>[
        'Die Versorgung der Muskeln mit Sauerstoff',
        'Ein möglichst großer Vorrat an Muskelmasse',
        'Eine besonders schnelle Reaktion der Nerven',
      ],
      correctIndex: 0,
      explanation:
          'Herz, Lunge und Gefäße liefern Sauerstoff, die Muskeln verwerten '
          'ihn. An beiden Enden lässt sich trainieren.',
    ),
    Question(
      prompt: 'Wann lässt sich Ausdauer verbessern?',
      options: <String>[
        'Nur in der Jugend, danach kaum noch',
        'In jedem Alter und oft recht schnell',
        'Nur mit teurer Ausrüstung im Verein',
      ],
      correctIndex: 1,
      explanation:
          'Ausdauer reagiert in jedem Alter auf Training, oft schon nach '
          'wenigen Wochen spürbar.',
    ),
    Question(
      prompt: 'Womit hängt gute Ausdauer deutlich zusammen?',
      options: <String>[
        'Mit einer höheren Körpergröße im Alter',
        'Mit einem schnelleren Denken beim Lesen',
        'Mit einem längeren und gesünderen Leben',
      ],
      correctIndex: 2,
      explanation: 'Die Ausdauerfähigkeit gehört zu den stärksten einzelnen '
          'Zusammenhängen mit Gesundheit und Lebenserwartung.',
    ),
  ],
);

const Lesson herzPage = Lesson(
  id: 'ausdauer-01-herz',
  title: 'Das Herz als Motor',
  summary: 'Was der Puls über die Ausdauer verrät.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Was der Puls misst',
      body: 'Der Puls zählt, wie oft das Herz in der Minute schlägt. Bei '
          'Belastung steigt er, weil die Muskeln mehr Blut brauchen. Ein '
          'trainiertes Herz pumpt mit jedem Schlag mehr Blut und kommt '
          'deshalb für dieselbe Arbeit mit weniger Schlägen aus.',
    ),
    LessonSection(
      heading: 'Der Ruhepuls',
      body: 'In Ruhe liegt der Puls bei Erwachsenen meist zwischen 60 und 100 '
          'Schlägen. Ausdauertrainierte liegen oft darunter. Morgens nach '
          'dem Aufwachen gemessen, ist er ein einfacher Hinweis auf den '
          'Trainingsstand — und ein ungewohnt hoher Wert manchmal ein '
          'Zeichen, dass der Körper noch mit Erholung beschäftigt ist.',
    ),
    LessonSection(
      heading: 'Der Maximalpuls',
      body: 'Nach oben hat der Puls eine Grenze, die mit dem Alter sinkt. Die '
          'Faustregel „220 minus Alter" ist nur eine grobe Schätzung; '
          'einzelne Menschen liegen deutlich darüber oder darunter. Anders '
          'als der Ruhepuls lässt sich der Maximalpuls durch Training kaum '
          'verändern.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt:
          'Warum schlägt ein trainiertes Herz für dieselbe Arbeit seltener?',
      options: <String>[
        'Weil es mit jedem Schlag mehr Blut pumpt',
        'Weil trainierte Muskeln kein Blut brauchen',
        'Weil das Blut sich im Training verdünnt',
      ],
      correctIndex: 0,
      explanation:
          'Mehr Blut je Schlag heißt weniger Schläge für dieselbe Menge. '
          'Das senkt auch den Ruhepuls.',
    ),
    Question(
      prompt: 'Wann misst man den Ruhepuls am aussagekräftigsten?',
      options: <String>[
        'Direkt nach einem harten Training am Abend',
        'Morgens gleich nach dem Aufwachen im Liegen',
        'Nach dem Mittagessen mit einem starken Kaffee',
      ],
      correctIndex: 1,
      explanation:
          'Morgens ist der Körper am ruhigsten, und der Wert lässt sich von '
          'Tag zu Tag vergleichen.',
    ),
    Question(
      prompt: 'Was stimmt über die Faustregel „220 minus Alter"?',
      options: <String>[
        'Sie gilt für jeden Menschen aufs Schlagen genau',
        'Sie steigt mit jedem Jahr an Training weiter an',
        'Sie ist nur eine grobe Schätzung für den Maximalpuls',
      ],
      correctIndex: 2,
      explanation:
          'Viele liegen deutlich daneben. Und der Maximalpuls selbst ändert '
          'sich durch Training kaum.',
    ),
  ],
);

const Lesson vo2maxPage = Lesson(
  id: 'ausdauer-02-vo2max',
  title: 'VO₂max, die Obergrenze',
  summary: 'Wie viel Sauerstoff der Körper höchstens verwerten kann.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Was die Zahl bedeutet',
      body: 'VO₂max ist die größte Menge Sauerstoff, die der Körper bei voller '
          'Anstrengung pro Minute aufnehmen und verwerten kann, meist '
          'angegeben je Kilogramm Körpergewicht. Sie ist so etwas wie der '
          'Hubraum der Ausdauer: Sie legt fest, wie viel Leistung aus dem '
          'Sauerstoff höchstens herauszuholen ist.',
    ),
    LessonSection(
      heading: 'Sie lässt sich trainieren',
      body: 'Ein Teil der VO₂max ist angeboren. Untrainierte verbessern sie '
          'durch regelmäßiges Ausdauertraining aber oft deutlich, vor allem '
          'in den ersten Monaten. Mit dem Alter sinkt sie langsam — bei '
          'Menschen, die trainieren, spürbar langsamer.',
    ),
    LessonSection(
      heading: 'Warum sie mehr als Sport ist',
      body: 'Eine höhere VO₂max hängt in großen Studien eng mit einem '
          'geringeren Sterberisiko zusammen, und zwar stärker als viele '
          'bekannte Risikofaktoren. Der größte Gewinn liegt dabei nicht bei '
          'Spitzensportlern, sondern bei denen, die von sehr wenig auf '
          'etwas mehr kommen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was beschreibt die VO₂max?',
      options: <String>[
        'Wie schnell das Herz höchstens schlagen kann',
        'Wie viel Sauerstoff der Körper höchstens verwertet',
        'Wie viel Luft man in einem Atemzug halten kann',
      ],
      correctIndex: 1,
      explanation:
          'Sie misst Aufnahme und Verwertung von Sauerstoff unter voller '
          'Last — nicht den Puls und nicht das Lungenvolumen allein.',
    ),
    Question(
      prompt:
          'Wer verbessert seine VO₂max durch Training meist am deutlichsten?',
      options: <String>[
        'Wer bisher kaum trainiert hat',
        'Wer schon jahrelang Profi ist',
        'Niemand, sie ist ganz angeboren',
      ],
      correctIndex: 0,
      explanation:
          'Ein Teil ist angeboren, aber gerade Untrainierte legen in den '
          'ersten Monaten oft deutlich zu.',
    ),
    Question(
      prompt: 'Wo liegt der größte gesundheitliche Gewinn?',
      options: <String>[
        'Bei Spitzensportlern, die noch mehr trainieren',
        'Bei allen genau gleich, egal von wo sie starten',
        'Bei denen, die von sehr wenig auf etwas mehr kommen',
      ],
      correctIndex: 2,
      explanation:
          'Der Schritt aus der untersten Gruppe heraus bringt am meisten. '
          'Man muss dafür kein Athlet werden.',
    ),
  ],
);

const Lesson grundlagePage = Lesson(
  id: 'ausdauer-03-grundlage',
  title: 'Locker und lang',
  summary: 'Warum das meiste Ausdauertraining leicht sein sollte.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Das Fundament',
      body: 'Grundlagenausdauer entsteht vor allem durch lange, ruhige '
          'Einheiten. Dabei passen sich Herz, Gefäße und Muskeln an: mehr '
          'kleine Blutgefäße, mehr Kraftwerke in den Zellen, bessere '
          'Fettverbrennung. Das ist nicht spektakulär, aber es trägt alles '
          'andere.',
    ),
    LessonSection(
      heading: 'Woran man das Tempo erkennt',
      body: 'Ein einfacher Test: Im lockeren Bereich kann man noch in ganzen '
          'Sätzen sprechen, auch wenn man merkt, dass man sich bewegt. Wer '
          'nur noch einzelne Wörter herausbekommt, ist zu schnell. Viele '
          'laufen ihre ruhigen Einheiten zu hart und ihre harten zu weich.',
    ),
    LessonSection(
      heading: 'Viel leicht, wenig hart',
      body: 'Ausdauersportler verbringen meist den größten Teil ihrer '
          'Trainingszeit, oft um die achtzig Prozent, in diesem lockeren '
          'Bereich. Das ist kein Zeichen von Bequemlichkeit: Nur so bleibt '
          'genug Erholung übrig, um die wenigen harten Einheiten wirklich '
          'hart zu machen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Woran erkennt man, dass man im lockeren Bereich ist?',
      options: <String>[
        'Man bekommt nur noch einzelne Wörter heraus',
        'Man kann noch in ganzen Sätzen sprechen',
        'Man schwitzt überhaupt nicht dabei',
      ],
      correctIndex: 1,
      explanation:
          'Sprechen in ganzen Sätzen geht noch. Einzelne Wörter heißt: zu '
          'schnell für eine ruhige Einheit.',
    ),
    Question(
      prompt: 'Wie viel ihrer Zeit trainieren Ausdauersportler meist locker?',
      options: <String>[
        'Kaum etwas, fast jede Einheit ist hart',
        'Ziemlich genau die Hälfte ihrer Zeit',
        'Den größten Teil, oft um achtzig Prozent',
      ],
      correctIndex: 2,
      explanation:
          'Der Großteil ist locker. Nur so bleibt Kraft für die wenigen '
          'harten Einheiten.',
    ),
    Question(
      prompt: 'Was baut lockeres Training im Körper auf?',
      options: <String>[
        'Mehr Blutgefäße und Kraftwerke in den Zellen',
        'Vor allem mehr Muskelmasse an den Beinen',
        'Ausschließlich eine stärkere Atemmuskulatur',
      ],
      correctIndex: 0,
      explanation:
          'Mehr kleine Gefäße und mehr Mitochondrien — die Grundlage, auf '
          'der alles andere steht.',
    ),
  ],
);

const Lesson intervallPage = Lesson(
  id: 'ausdauer-04-intervalle',
  title: 'Intervalltraining',
  summary: 'Kurz und hart — wofür das gut ist und wie oft.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Hart, Pause, hart',
      body: 'Beim Intervalltraining wechseln sich harte Abschnitte und Pausen '
          'ab, etwa viermal vier Minuten zügig mit jeweils drei Minuten '
          'lockerem Traben dazwischen. Die Pausen erlauben es, insgesamt '
          'länger in einem hohen Bereich zu arbeiten, als man es am Stück '
          'schaffen würde.',
    ),
    LessonSection(
      heading: 'Wofür es gut ist',
      body: 'Intervalle heben besonders wirksam die VO₂max, also die '
          'Obergrenze der Ausdauer. Sie sind zeitsparend: Eine halbe Stunde '
          'mit Intervallen fordert den Körper stärker als eine Stunde '
          'gemütliches Laufen. Sie ersetzen die lockeren Einheiten aber '
          'nicht, sie ergänzen sie.',
    ),
    LessonSection(
      heading: 'Wie oft',
      body: 'Harte Intervalle kosten viel Erholung. Ein bis zwei solcher '
          'Einheiten pro Woche reichen den meisten; mehr führt schnell dazu, '
          'dass alle Einheiten mittelmäßig werden. Wer neu anfängt, baut '
          'erst ein paar Wochen Grundlage auf.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wozu dienen die Pausen zwischen den harten Abschnitten?',
      options: <String>[
        'Sie verkürzen die Einheit, damit sie schneller vorbei ist',
        'Sie erlauben mehr Zeit im hohen Bereich als am Stück',
        'Sie sorgen dafür, dass der Puls gar nicht erst steigt',
      ],
      correctIndex: 1,
      explanation:
          'Mit Pausen hält man insgesamt länger hohe Intensität durch, als '
          'es in einem Stück ginge.',
    ),
    Question(
      prompt: 'Welche Rolle haben Intervalle neben lockerem Training?',
      options: <String>[
        'Sie ergänzen es, sie ersetzen es nicht',
        'Sie ersetzen lockeres Training völlig',
        'Sie sind nur für Profis überhaupt sinnvoll',
      ],
      correctIndex: 0,
      explanation:
          'Die Grundlage bleibt der größte Teil. Intervalle setzen oben '
          'einen zusätzlichen Reiz.',
    ),
    Question(
      prompt:
          'Wie viele harte Intervalleinheiten reichen den meisten pro Woche?',
      options: <String>[
        'Jeden Tag eine, sonst wirkt es nicht',
        'Gar keine, Intervalle schaden meist',
        'Ein bis zwei, mehr kostet zu viel Erholung',
      ],
      correctIndex: 2,
      explanation:
          'Sie fordern viel Erholung. Zu viele machen am Ende alle Einheiten '
          'mittelmäßig.',
    ),
  ],
);

const Lesson energiePage = Lesson(
  id: 'ausdauer-05-energie',
  title: 'Woher die Energie kommt',
  summary: 'ATP, mit und ohne Sauerstoff — und was Laktat wirklich ist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Die eine Währung',
      body: 'Jede Muskelbewegung wird mit ATP bezahlt, einem Molekül, das '
          'Energie kurzfristig speichert. Davon hat der Muskel nur für '
          'wenige Sekunden Vorrat. Alles, was länger dauert, hängt daran, '
          'wie schnell der Körper ATP nachproduzieren kann.',
    ),
    LessonSection(
      heading: 'Mit und ohne Sauerstoff',
      body: 'Ohne Sauerstoff, anaerob, geht die Nachproduktion schnell, '
          'reicht aber nur für kurze, harte Belastungen wie einen Sprint. '
          'Mit Sauerstoff, aerob, ist sie langsamer, kann dafür aber '
          'stundenlang laufen, aus Kohlenhydraten und Fett. Die meisten '
          'Belastungen nutzen beide Wege, nur in anderem Verhältnis.',
    ),
    LessonSection(
      heading: 'Laktat ist nicht der Feind',
      body: 'Bei harter Belastung entsteht vermehrt Laktat. Es ist kein '
          'Abfall, sondern wird weiterverwertet, auch als Brennstoff, und '
          'ist nach einer Belastung meist innerhalb von etwa einer Stunde '
          'wieder abgebaut. Mit dem Muskelkater der nächsten Tage hat es '
          'deshalb nichts zu tun.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wofür reicht der ATP-Vorrat im Muskel?',
      options: <String>[
        'Für einen ganzen Tag',
        'Für wenige Sekunden',
        'Für etwa eine Stunde',
      ],
      correctIndex: 1,
      explanation:
          'Der Vorrat ist winzig. Alles Weitere hängt an der Nachproduktion.',
    ),
    Question(
      prompt: 'Was zeichnet die Energiegewinnung mit Sauerstoff aus?',
      options: <String>[
        'Sie ist langsamer, hält aber stundenlang durch',
        'Sie ist am schnellsten und nur für Sprints da',
        'Sie nutzt ausschließlich Eiweiß als Brennstoff',
      ],
      correctIndex: 0,
      explanation:
          'Aerob ist langsam, aber ausdauernd, und nutzt Kohlenhydrate und '
          'Fett. Für Sprints ist der schnelle Weg ohne Sauerstoff da.',
    ),
    Question(
      prompt: 'Was stimmt über Laktat?',
      options: <String>[
        'Es ist ein Abfall, der den Muskel vergiftet',
        'Es verursacht den Muskelkater der Folgetage',
        'Es wird weiterverwertet und rasch abgebaut',
      ],
      correctIndex: 2,
      explanation:
          'Laktat wird verwertet, auch als Brennstoff, und ist bald wieder '
          'weg. Muskelkater hat andere Ursachen.',
    ),
  ],
);

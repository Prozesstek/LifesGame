/// **Gewohnheiten** unter Selbstentwicklung — das erste Gebiet, das aus
/// dem wächst, was Frederik gerade liest (*Die 1%-Methode*, James Clear).
///
/// Drei Ebenen tief: das Überkapitel, darunter die vier Regeln, darunter
/// je Regel eine Seite. Befüllt sind die ersten zwei Regeln. Die Seiten
/// setzen das Handbuch voraus („Die Schleife hinter jeder Gewohnheit“)
/// und wiederholen es nicht.
library;

import '../lesson.dart';

// ---------------------------------------------------------------------------
// Überkapitel
// ---------------------------------------------------------------------------

const Lesson gewohnheitenPage = Lesson(
  id: 'gewohnheiten-01-ueberblick',
  title: 'Gewohnheiten',
  summary: 'Was dein Alltag von selbst tut, entscheidet mehr als dein Wille.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der größte Teil läuft von allein',
      body: 'Ein großer Teil dessen, was du an einem Tag tust, ist nicht '
          'entschieden, sondern gewohnt: der Griff zum Handy nach dem '
          'Aufwachen, der Weg in die Küche, das Getränk zum Essen. '
          'Gewohnheiten sind die Handlungen, die das Gehirn so oft '
          'wiederholt hat, dass es nicht mehr nachdenken muss.',
    ),
    LessonSection(
      heading: 'Kleine Schritte summieren sich',
      body: 'Eine einzelne Wiederholung ändert fast nichts. Ein Prozent '
          'besser an einem Tag sieht man nicht. Über ein Jahr aber wird '
          'aus vielen unsichtbaren Schritten ein sichtbarer Unterschied — '
          'in beide Richtungen. Deshalb lohnt es sich, auf die kleinen, '
          'täglichen Dinge zu achten statt auf den großen Vorsatz.',
    ),
    LessonSection(
      heading: 'Worum es hier geht',
      body: 'Das Handbuch hat die Schleife erklärt: Auslöser, Routine, '
          'Belohnung. Dieses Gebiet geht weiter und fragt, an welchen '
          'Stellen der Schleife man eingreifen kann — und wie das im '
          'eigenen Alltag aussieht, in der eigenen Wohnung.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was macht eine Handlung zur Gewohnheit?',
      options: <String>[
        'Sie wurde so oft wiederholt, dass man nicht mehr nachdenkt',
        'Sie wurde einmal bewusst und fest für immer beschlossen',
        'Sie macht so viel Spaß, dass man sie gern und oft tut',
        'Sie wurde von anderen Menschen gelobt und bestätigt',
      ],
      correctIndex: 0,
      explanation: 'Gewohnheit ist Wiederholung, bis das Nachdenken '
          'entfällt. Ein Beschluss allein macht noch keine.',
    ),
    Question(
      prompt: 'Warum zählt ein Prozent am Tag, obwohl man es nicht sieht?',
      options: <String>[
        'Weil man es an einem einzigen Tag doch deutlich merkt',
        'Weil kleine Schritte sich über Monate aufsummieren',
        'Weil andere Menschen den Unterschied sofort bemerken',
        'Weil große Veränderungen grundsätzlich schaden',
      ],
      correctIndex: 1,
      explanation: 'Einzeln unsichtbar, zusammen sichtbar — und das gilt '
          'für gute wie für schlechte Gewohnheiten.',
    ),
    Question(
      prompt: 'Was fragt dieses Gebiet über das Handbuch hinaus?',
      options: <String>[
        'Wie man ganz ohne jede Gewohnheit auskommen kann',
        'Warum Gewohnheiten für Erwachsene kaum wichtig sind',
        'An welcher Stelle der Schleife man eingreifen kann',
        'Welche Gewohnheiten andere Menschen besser haben',
      ],
      correctIndex: 2,
      explanation: 'Die Schleife ist bekannt. Jetzt geht es um die Hebel '
          'an jeder ihrer Stellen.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Die vier Regeln
// ---------------------------------------------------------------------------

const Lesson vierRegelnPage = Lesson(
  id: 'gewohnheiten-02-vier-regeln',
  title: 'Die vier Regeln',
  summary: 'Offensichtlich, attraktiv, einfach, befriedigend.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Vier Stellen, vier Hebel',
      body: 'James Clear teilt die Schleife in vier Schritte: Auslöser, '
          'Verlangen, Reaktion, Belohnung. Zu jedem gehört eine Regel. '
          'Mach es offensichtlich — damit der Auslöser auffällt. Mach es '
          'attraktiv — damit du es willst. Mach es einfach — damit das '
          'Tun wenig kostet. Mach es befriedigend — damit du wiederkommst.',
    ),
    LessonSection(
      heading: 'Umgedreht gegen schlechte Gewohnheiten',
      body: 'Dieselben Regeln funktionieren rückwärts. Was du loswerden '
          'willst, machst du unsichtbar, unattraktiv, schwierig und '
          'unbefriedigend. Wer weniger Süßes essen will, kauft es nicht '
          'ein — dann steht es nicht im Schrank, und die Frage, ob man '
          'widersteht, stellt sich gar nicht erst.',
    ),
    LessonSection(
      heading: 'Nicht mehr Willenskraft, sondern bessere Umstände',
      body: 'Keine der vier Regeln verlangt, dass du dich mehr '
          'zusammenreißt. Sie alle verändern die Lage, in der du '
          'entscheidest. Das ist der Kern: Wer seine Umstände gestaltet, '
          'braucht im entscheidenden Moment weniger Disziplin.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Welche Regel gehört zum Verlangen?',
      options: <String>[
        'Mach es befriedigend',
        'Mach es attraktiv',
        'Mach es einfach',
        'Mach es offensichtlich',
      ],
      correctIndex: 1,
      explanation: 'Offensichtlich gehört zum Auslöser, attraktiv zum '
          'Verlangen, einfach zur Reaktion, befriedigend zur Belohnung.',
    ),
    Question(
      prompt: 'Wie helfen die Regeln gegen eine schlechte Gewohnheit?',
      options: <String>[
        'Man wendet sie genau gleich an, nur viel häufiger',
        'Man dreht sie um: unsichtbar, unattraktiv, schwierig',
        'Man ersetzt sie durch einen besonders strengen Plan',
        'Man ignoriert sie und setzt ganz auf Willenskraft',
      ],
      correctIndex: 1,
      explanation: 'Rückwärts angewandt machen die Regeln das Unerwünschte '
          'unsichtbar, unattraktiv, schwierig und unbefriedigend.',
    ),
    Question(
      prompt: 'Was verändern alle vier Regeln?',
      options: <String>[
        'Die Lage, in der du entscheidest',
        'Die Menge deiner Willenskraft',
        'Das Ziel, das du dir gesetzt hast',
        'Die Meinung anderer über dich',
      ],
      correctIndex: 0,
      explanation: 'Sie gestalten die Umstände, damit im Moment der '
          'Entscheidung weniger Disziplin nötig ist.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// 1. Regel: Mach es offensichtlich
// ---------------------------------------------------------------------------

const Lesson offensichtlichPage = Lesson(
  id: 'gewohnheiten-03-offensichtlich',
  title: 'Mach es offensichtlich',
  summary: 'Stell hin, was du öfter tun willst — genau dorthin, wo du bist.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Was du siehst, entscheidet mit',
      body: 'In einer Krankenhauskantine in Boston stellte die Ärztin Anne '
          'Thorndike Wasserflaschen zusätzlich in Kühlschränke neben die '
          'Kassen und in Körbe überall im Raum. Sonst änderte sich '
          'nichts. In den Monaten danach wurde deutlich mehr Wasser '
          'gekauft und weniger Limonade. Niemand hatte sich vorgenommen, '
          'gesünder zu trinken — das Wasser stand einfach da.',
    ),
    LessonSection(
      heading: 'Die Wohnung umstellen',
      body: 'Dasselbe geht zu Hause. Eine volle Wasserflasche auf dem '
          'Schreibtisch wird öfter getrunken als eine im Schrank. Gemüse '
          'vorne im Kühlschrank auf Augenhöhe wird eher gegessen als das '
          'in der Schublade unten. Das Buch auf dem Kopfkissen wird eher '
          'gelesen als das im Regal. Der Auslöser ist dann nicht ein '
          'Vorsatz, sondern ein Gegenstand, an dem du vorbeikommst.',
    ),
    LessonSection(
      heading: 'Ein Ort, eine Sache — und das Gegenteil verstecken',
      body: 'Hilfreich ist, wenn ein Platz für eine Sache steht: der Stuhl '
          'am Fenster zum Lesen, der Tisch zum Arbeiten. Und umgekehrt: '
          'Was du seltener tun willst, räumst du aus dem Blick. Das Handy '
          'in einem anderen Zimmer, die Süßigkeiten hinten im Schrank. '
          'Kleine Umstellungen, die jeden Tag von selbst wirken.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was änderte sich in der Kantine, damit mehr Wasser '
          'gekauft wurde?',
      options: <String>[
        'Das Wasser wurde deutlich billiger als die Limonade',
        'Plakate erklärten, warum Wasser gesünder ist',
        'Das Wasser stand an mehr Stellen gut sichtbar',
        'Limonade wurde für einige Monate ganz verboten',
      ],
      correctIndex: 2,
      explanation: 'Weder Preis noch Verbot noch Aufklärung — nur der Ort. '
          'Was im Blick steht, wird öfter gewählt.',
    ),
    Question(
      prompt: 'Wohin gehört das Gemüse, wenn du mehr davon essen willst?',
      options: <String>[
        'In die unterste Schublade, damit es frisch bleibt',
        'Vorne in den Kühlschrank, auf Augenhöhe',
        'In einen Schrank, zu den anderen Vorräten',
        'Auf den Einkaufszettel für die nächste Woche',
      ],
      correctIndex: 1,
      explanation: 'Sichtbar und griffbereit wird es zum Auslöser. In der '
          'Schublade wird es vergessen.',
    ),
    Question(
      prompt: 'Wie wendest du die Regel gegen das Handy am Abend an?',
      options: <String>[
        'Du legst es abends in ein anderes Zimmer',
        'Du nimmst dir fest vor, es nicht anzufassen',
        'Du legst es gut sichtbar neben das Bett',
        'Du stellst dir einen Wecker zum Weglegen',
      ],
      correctIndex: 0,
      explanation: 'Umgedreht heißt die Regel: unsichtbar machen. Was nicht '
          'in Reichweite liegt, löst nichts aus.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// 2. Regel: Mach es attraktiv
// ---------------------------------------------------------------------------

const Lesson attraktivPage = Lesson(
  id: 'gewohnheiten-04-attraktiv',
  title: 'Mach es attraktiv',
  summary: 'Häng das, was du tun musst, an etwas, das du tun willst.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Die Vorfreude zieht, nicht die Belohnung',
      body: 'Dopamin gilt als Botenstoff des Glücks, treibt aber vor allem '
          'das Wollen an. Es steigt nicht erst, wenn die Belohnung da ist, '
          'sondern schon, wenn sie sich ankündigt: beim Geruch des '
          'Kaffees, beim Ton der Nachricht. Diese Erwartung bringt dich '
          'in Bewegung. Eine Gewohnheit, auf die du dich freust, beginnst '
          'du deshalb leichter als eine, die du nur für richtig hältst.',
    ),
    LessonSection(
      heading: 'Das Versuchungsbündel',
      body: 'Daraus folgt ein einfacher Griff: Verbinde, was du tun musst, '
          'mit etwas, das du ohnehin willst. Die Lieblingsserie nur auf '
          'dem Heimtrainer. Der Podcast nur beim Aufräumen. Zusammen mit '
          'der Kopplung ergibt das einen ganzen Satz: Nach dem Frühstück '
          'lese ich zwei Minuten — und danach gibt es den Kaffee. Die '
          'Belohnung muss klein sein und sofort kommen. Ein Ausflug am '
          'Wochenende zieht am Montagmorgen niemanden vom Sofa.',
    ),
    LessonSection(
      heading: 'Die Menschen um dich herum',
      body: 'Attraktiv ist auch, was die eigene Gruppe für normal hält. '
          'Menschen übernehmen Gewohnheiten von denen, die ihnen nah '
          'sind, von der Mehrheit und von denen, die sie bewundern. Wer '
          'laufen will, hat es in einer Laufgruppe leichter als allein: '
          'Dort ist Laufen nichts Besonderes, sondern das, was man eben '
          'tut. Such dir Umgebungen, in denen dein Wunschverhalten der '
          'Normalfall ist.',
    ),
    LessonSection(
      heading: 'Umdeuten — und umdrehen',
      body: 'Oft genügt ein anderes Wort. „Ich muss trainieren“ beschreibt '
          'eine Last, „ich darf trainieren“ eine Gelegenheit, und beides '
          'meint dieselbe halbe Stunde. Gegen eine schlechte Gewohnheit '
          'wirkt die Regel rückwärts: Mach sie unattraktiv. Führ dir vor '
          'Augen, was sie dich kostet, statt was sie dir für den Moment '
          'gibt.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wann steigt das Verlangen nach einer Belohnung am stärksten?',
      options: <String>[
        'Erst lange nachdem die Belohnung vorbei ist',
        'Schon wenn sie sich deutlich ankündigt',
        'Nur wenn andere dabei zusehen können',
        'Genau in dem Moment, in dem man sie hat',
      ],
      correctIndex: 1,
      explanation: 'Die Erwartung bringt in Bewegung. Deshalb hilft es, '
          'wenn an einer Gewohnheit etwas hängt, auf das man sich freut.',
    ),
    Question(
      prompt: 'Welches Beispiel ist ein Versuchungsbündel?',
      options: <String>[
        'Die Laufschuhe abends sichtbar neben die Tür stellen',
        'Sich am Jahresende einen großen Urlaub versprechen',
        'Die Lieblingsserie nur auf dem Heimtrainer schauen',
        'Sich fest vornehmen, diesmal wirklich durchzuhalten',
      ],
      correctIndex: 2,
      explanation: 'Müssen und Wollen hängen zusammen, und die Belohnung '
          'kommt sofort. Die Schuhe an der Tür gehören zur ersten Regel.',
    ),
    Question(
      prompt: 'Warum hilft eine Laufgruppe beim Dranbleiben?',
      options: <String>[
        'Dort ist Laufen das, was alle ohnehin tun',
        'Dort läuft man automatisch schneller als allein',
        'Dort wird jedes Fehlen mit einer Strafe belegt',
        'Dort braucht man keinen eigenen Plan mehr',
      ],
      correctIndex: 0,
      explanation: 'Was die eigene Gruppe für normal hält, wirkt '
          'anziehend. Man übernimmt, was die Menschen um einen herum tun.',
    ),
  ],
);

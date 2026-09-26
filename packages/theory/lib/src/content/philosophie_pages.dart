/// **Philosophie**: Einführung und fünf Themen (ADR-0050).
///
/// Ausgewählt nach dem, was sich im Alltag verwenden lässt: Stoizismus
/// als Werkzeug gegen Grübeln, Ethik als Sprache für schwierige
/// Entscheidungen, Fehlschlüsse als Schutz in Diskussionen. Zitate sind
/// sinngemäß wiedergegeben, wo der genaue Wortlaut strittig ist.
///
/// **Entwürfe von Claude, gegengelesen von Frederik** (ADR-0050, Punkt 3).
library;

import '../lesson.dart';

const Lesson philosophiePage = Lesson(
  id: 'geist-11-philosophie',
  title: 'Philosophie',
  summary: 'Die Kunst, gründlich über die großen Fragen nachzudenken.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Fragen, die nicht verschwinden',
      body: 'Was ist ein gutes Leben? Was darf ich tun? Woher weiß ich, dass '
          'etwas wahr ist? Solche Fragen lassen sich nicht messen wie ein '
          'Puls. Philosophie ist der Versuch, sie trotzdem sorgfältig zu '
          'beantworten — mit Gründen statt mit Bauchgefühl.',
    ),
    LessonSection(
      heading: 'Werkzeug, kein Museum',
      body: 'Vieles, was Denker vor über zweitausend Jahren schrieben, ist '
          'erstaunlich praktisch. Die Stoiker schrieben Anleitungen gegen '
          'Sorgen, Aristoteles über Gewohnheiten und Charakter. Wer sie '
          'liest, bekommt keine fertigen Antworten, aber bessere Fragen.',
    ),
    LessonSection(
      heading: 'Worum es hier geht',
      body: 'In diesem Gebiet geht es um den Stoizismus, um drei Arten, über '
          'richtig und falsch nachzudenken, um typische Denkfehler in '
          'Diskussionen, um Sokrates und seine Fragen und um die Frage '
          'nach Freiheit und Sinn.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wie versucht die Philosophie, große Fragen zu beantworten?',
      options: <String>[
        'Mit sorgfältigen Gründen statt mit Bauchgefühl',
        'Mit Messungen im Labor wie bei einem Experiment',
        'Mit der Meinung, die die meisten Menschen teilen',
      ],
      correctIndex: 0,
      explanation: 'Solche Fragen lassen sich selten messen. Philosophie prüft '
          'stattdessen Gründe und Gegengründe.',
    ),
    Question(
      prompt: 'Was bekommt man laut dieser Seite, wenn man Philosophen liest?',
      options: <String>[
        'Fertige Antworten für jede Lebenslage',
        'Vor allem Wissen über alte Geschichte',
        'Bessere Fragen statt fertiger Antworten',
      ],
      correctIndex: 2,
      explanation:
          'Die alten Texte sind oft praktisch, aber sie nehmen einem das '
          'Denken nicht ab.',
    ),
    Question(
      prompt: 'Worüber schrieben die Stoiker unter anderem?',
      options: <String>[
        'Über den Bau von Tempeln und Straßen',
        'Über den Umgang mit Sorgen und Ärger',
        'Über die Bewegung der fernen Planeten',
      ],
      correctIndex: 1,
      explanation:
          'Ihre Schriften sind zu einem guten Teil Anleitungen, mit dem '
          'eigenen Kopf besser umzugehen.',
    ),
  ],
);

const Lesson stoizismusPage = Lesson(
  id: 'philo-01-stoizismus',
  title: 'Was in deiner Macht steht',
  summary: 'Der Kern des Stoizismus in einer einzigen Unterscheidung.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Die Unterscheidung',
      body: 'Der Stoiker Epiktet, selbst einst ein Sklave, begann sein '
          'Handbüchlein mit einem Gedanken: Manches liegt in unserer Macht, '
          'anderes nicht. In unserer Macht sind unser Urteil, unsere '
          'Absichten, unser Handeln. Nicht in unserer Macht sind der Körper '
          'ganz, der Ruf, das Wetter, was andere tun.',
    ),
    LessonSection(
      heading: 'Warum das beruhigt',
      body: 'Viel Ärger entsteht, weil wir uns an Dingen abarbeiten, die wir '
          'nicht ändern können: am Stau, an einer Absage, an der Laune eines '
          'anderen. Die Stoiker empfehlen, die Kraft dorthin zu lenken, wo '
          'sie etwas bewirkt — auf die eigene Reaktion. Das ist keine '
          'Gleichgültigkeit, sondern Sparsamkeit mit Energie.',
    ),
    LessonSection(
      heading: 'Ein Kaiser mit Notizbuch',
      body: 'Mark Aurel, römischer Kaiser, schrieb abends Notizen an sich '
          'selbst, die heute als „Selbstbetrachtungen" gelesen werden. Er '
          'erinnerte sich darin immer wieder an dieselben Grundsätze. Auch '
          'für einen Kaiser war Gelassenheit also keine Eigenschaft, sondern '
          'eine tägliche Übung.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was liegt nach Epiktet in unserer Macht?',
      options: <String>[
        'Unser Ruf bei anderen Menschen',
        'Unser Urteil und unser Handeln',
        'Das Wetter am nächsten Morgen',
      ],
      correctIndex: 1,
      explanation:
          'Urteil, Absicht und Handeln gehören uns. Ruf, Wetter und das '
          'Verhalten anderer nicht.',
    ),
    Question(
      prompt: 'Wohin empfehlen die Stoiker die eigene Kraft zu lenken?',
      options: <String>[
        'Auf die eigene Reaktion, wo sie etwas bewirkt',
        'Auf den Stau, damit er sich schneller auflöst',
        'Auf andere, damit sie sich endlich ändern',
      ],
      correctIndex: 0,
      explanation:
          'Nicht Gleichgültigkeit, sondern Sparsamkeit: Kraft dorthin, wo '
          'sie tatsächlich wirkt.',
    ),
    Question(
      prompt: 'Was zeigen Mark Aurels Selbstbetrachtungen?',
      options: <String>[
        'Dass Kaiser von Natur aus gelassen waren',
        'Dass er nur Befehle für sein Heer notierte',
        'Dass Gelassenheit eine tägliche Übung ist',
      ],
      correctIndex: 2,
      explanation:
          'Er musste sich dieselben Grundsätze immer wieder vorsagen — wie '
          'eine Gewohnheit, die gepflegt werden will.',
    ),
  ],
);

const Lesson ethikPage = Lesson(
  id: 'philo-02-ethik',
  title: 'Folgen, Pflichten, Charakter',
  summary: 'Drei Arten, über richtig und falsch nachzudenken.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Auf die Folgen schauen',
      body: 'Der Utilitarismus, geprägt von Bentham und Mill, fragt: Welche '
          'Handlung bringt insgesamt das meiste Wohl und das wenigste Leid? '
          'Richtig ist, was die besten Folgen hat. Das ist klar und '
          'rechenbar — kann aber Einzelne opfern, wenn es der Summe dient.',
    ),
    LessonSection(
      heading: 'Auf die Pflicht schauen',
      body: 'Immanuel Kant hielt dagegen: Manche Dinge darf man nicht tun, '
          'egal was dabei herauskommt. Ein Grundsatz von ihm lautet sinngemäß: '
          'Behandle Menschen nie bloß als Mittel, sondern immer auch als '
          'Zweck. Lügen ist dann falsch, selbst wenn es im Moment nützt.',
    ),
    LessonSection(
      heading: 'Auf den Menschen schauen',
      body: 'Aristoteles fragt weniger „Was soll ich jetzt tun?" als „Was für '
          'ein Mensch will ich werden?". Tugenden wie Mut entstehen durch '
          'Übung und liegen in der Mitte zwischen zwei Fehlern, beim Mut '
          'zwischen Feigheit und Tollkühnheit. Charakter ist bei ihm im '
          'Grunde eine Sammlung von Gewohnheiten.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Wonach beurteilt der Utilitarismus eine Handlung?',
      options: <String>[
        'Nach der Absicht, mit der sie geschieht',
        'Nach ihren Folgen für das Wohl aller',
        'Nach der Tradition, aus der sie stammt',
      ],
      correctIndex: 1,
      explanation:
          'Richtig ist, was insgesamt am meisten Wohl und am wenigsten Leid '
          'bringt.',
    ),
    Question(
      prompt: 'Was verlangt Kant im Umgang mit Menschen?',
      options: <String>[
        'Sie nie bloß als Mittel zu behandeln',
        'Sie immer nach ihrem Nutzen zu wählen',
        'Sie nur nach Regeln des Staates zu richten',
      ],
      correctIndex: 0,
      explanation:
          'Ein Mensch ist bei Kant immer auch ein Zweck an sich — und darf '
          'nicht bloß benutzt werden.',
    ),
    Question(
      prompt: 'Wo liegt eine Tugend wie Mut nach Aristoteles?',
      options: <String>[
        'Ganz am äußersten Rand der Tollkühnheit',
        'Irgendwo, wo die Mehrheit gerade steht',
        'In der Mitte zwischen zwei Fehlern',
      ],
      correctIndex: 2,
      explanation:
          'Mut liegt zwischen Feigheit und Tollkühnheit — und entsteht durch '
          'Übung, nicht durch Einsicht allein.',
    ),
  ],
);

const Lesson fehlschluessePage = Lesson(
  id: 'philo-03-fehlschluesse',
  title: 'Fehlschlüsse erkennen',
  summary: 'Drei Tricks, die in fast jeder Diskussion auftauchen.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Der Strohmann',
      body: 'Statt das Argument des anderen anzugreifen, greift man eine '
          'verzerrte, schwächere Fassung davon an. „Du willst weniger '
          'Fleisch essen? Also soll keiner mehr grillen dürfen." Der '
          'Strohmann fällt leicht um — nur hat ihn niemand aufgestellt. '
          'Gegenmittel: das Argument des anderen erst so gut wiedergeben, '
          'dass er zustimmt.',
    ),
    LessonSection(
      heading: 'Der Angriff auf die Person',
      body: 'Hier wird nicht die Aussage geprüft, sondern der, der sie macht: '
          '„Du rauchst doch selbst, was weißt du schon über Gesundheit." '
          'Ob jemand sich an seinen Rat hält, sagt nichts darüber, ob der '
          'Rat stimmt. Ein Argument steht oder fällt mit seinen Gründen.',
    ),
    LessonSection(
      heading: 'Das falsche Dilemma',
      body: 'Es werden nur zwei Möglichkeiten angeboten, obwohl es mehr gibt: '
          '„Entweder du trainierst jeden Tag, oder du kannst es gleich '
          'lassen." Wer solche Sätze bemerkt, fragt nach dem Dritten. Oft '
          'liegt die vernünftige Antwort genau dort.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was macht ein Strohmann-Argument?',
      options: <String>[
        'Es widerlegt die stärkste Fassung eines Arguments',
        'Es greift eine verzerrte, schwächere Fassung an',
        'Es gibt dem anderen am Ende einfach recht',
      ],
      correctIndex: 1,
      explanation: 'Angegriffen wird etwas, das so niemand gesagt hat. Das '
          'Gegenmittel ist, den anderen erst fair wiederzugeben.',
    ),
    Question(
      prompt: 'Warum ist „Du rauchst doch selbst" kein gutes Gegenargument?',
      options: <String>[
        'Weil es über die Person, nicht die Aussage urteilt',
        'Weil Raucher grundsätzlich immer recht behalten',
        'Weil über Gesundheit gar nicht gestritten wird',
      ],
      correctIndex: 0,
      explanation:
          'Ob jemand seinen Rat befolgt, ändert nichts daran, ob der Rat '
          'stimmt.',
    ),
    Question(
      prompt: 'Wie begegnet man einem falschen Dilemma?',
      options: <String>[
        'Man wählt schnell eine der zwei Möglichkeiten',
        'Man lehnt beide ab und beendet das Gespräch',
        'Man fragt nach weiteren Möglichkeiten dazwischen',
      ],
      correctIndex: 2,
      explanation: 'Zwei Optionen sind oft nur die bequemste Darstellung. Die '
          'vernünftige liegt häufig dazwischen.',
    ),
  ],
);

const Lesson sokratesPage = Lesson(
  id: 'philo-04-sokrates',
  title: 'Fragen statt behaupten',
  summary: 'Was Sokrates auf dem Marktplatz von Athen tat.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Ein Mann, der nichts aufschrieb',
      body: 'Sokrates lebte im fünften Jahrhundert vor Christus in Athen und '
          'hat selbst kein einziges Buch geschrieben. Was wir über ihn '
          'wissen, stammt vor allem von seinem Schüler Platon. Sokrates '
          'redete lieber: auf dem Markt, mit jedem, der stehen blieb.',
    ),
    LessonSection(
      heading: 'Die Methode',
      body: 'Statt zu belehren, stellte er Fragen. Was ist Mut? Was ist '
          'Gerechtigkeit? Mit jeder Antwort fragte er nach, bis sich '
          'Widersprüche zeigten. Am Ende wussten die Gesprächspartner oft '
          'weniger als vorher — aber sie wussten jetzt, dass sie es nicht '
          'wussten.',
    ),
    LessonSection(
      heading: 'Wissen um das Nichtwissen',
      body: 'Sokrates hielt sich nur insofern für weise, als er seine eigene '
          'Unwissenheit kannte. Für den Alltag ist das ein nützlicher '
          'Grundsatz: Wer weiß, wo sein Wissen endet, fragt nach, statt zu '
          'raten. Und wer einem anderen etwas klarmachen will, erreicht '
          'mit guten Fragen oft mehr als mit Behauptungen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Woher wissen wir das meiste über Sokrates?',
      options: <String>[
        'Aus seinen eigenen, zahlreichen Büchern',
        'Aus den Schriften seines Schülers Platon',
        'Aus Inschriften auf dem Markt von Athen',
      ],
      correctIndex: 1,
      explanation:
          'Sokrates schrieb selbst nichts. Unser Bild von ihm stammt vor '
          'allem aus Platons Dialogen.',
    ),
    Question(
      prompt: 'Wie ging Sokrates in Gesprächen vor?',
      options: <String>[
        'Er hielt lange Vorträge über seine Lehre',
        'Er stellte Fragen, bis Widersprüche auftauchten',
        'Er ließ andere reden und schwieg die ganze Zeit',
      ],
      correctIndex: 1,
      explanation:
          'Nachfragen statt belehren — bis sich zeigte, wo eine Antwort '
          'nicht trug.',
    ),
    Question(
      prompt: 'Worin sah Sokrates seine eigene Weisheit?',
      options: <String>[
        'Darin, seine eigene Unwissenheit zu kennen',
        'Darin, auf jede Frage eine Antwort zu haben',
        'Darin, mehr Bücher als alle anderen zu kennen',
      ],
      correctIndex: 0,
      explanation:
          'Zu wissen, wo das eigene Wissen endet, war für ihn der Anfang '
          'jeder Einsicht.',
    ),
  ],
);

const Lesson existenzialismusPage = Lesson(
  id: 'philo-05-existenzialismus',
  title: 'Freiheit und Sinn',
  summary: 'Was Sartre und Camus über ein Leben ohne Anleitung sagten.',
  sections: <LessonSection>[
    LessonSection(
      heading: 'Erst da, dann bestimmt',
      body: 'Jean-Paul Sartre fasste den Existenzialismus in einen Satz: Die '
          'Existenz geht der Essenz voraus. Ein Messer wird für einen Zweck '
          'gemacht, ein Mensch nicht. Er ist zuerst da und bestimmt erst '
          'durch sein Handeln, wer er ist. Keine Natur und kein Plan nimmt '
          'ihm diese Entscheidung ab.',
    ),
    LessonSection(
      heading: 'Zur Freiheit verurteilt',
      body: 'Das klingt nach Befreiung und ist auch eine Last. Wer frei ist, '
          'ist verantwortlich — auch für das, was er aus Bequemlichkeit '
          'unterlässt. „Ich bin eben so" ist für Sartre eine Ausrede: Man '
          'ist, was man immer wieder tut.',
    ),
    LessonSection(
      heading: 'Sisyphos',
      body: 'Albert Camus erzählt von Sisyphos, der auf ewig einen Stein '
          'bergauf rollen muss, der jedes Mal wieder hinabrollt. Das Leben '
          'hat keinen fertigen Sinn, sagt Camus, aber man kann sich dagegen '
          'auflehnen, indem man es trotzdem voll lebt. Sein Schluss: Man '
          'muss sich Sisyphos als glücklichen Menschen vorstellen.',
    ),
  ],
  questions: <Question>[
    Question(
      prompt: 'Was meint „Die Existenz geht der Essenz voraus"?',
      options: <String>[
        'Der Mensch hat von Geburt an einen festen Zweck',
        'Der Mensch bestimmt erst durch sein Handeln, wer er ist',
        'Der Mensch kann an seinem Wesen gar nichts ändern',
      ],
      correctIndex: 1,
      explanation:
          'Anders als ein Werkzeug hat der Mensch keinen vorgegebenen Zweck. '
          'Er macht sich durch das, was er tut.',
    ),
    Question(
      prompt: 'Warum ist Freiheit für Sartre auch eine Last?',
      options: <String>[
        'Weil man für sein Tun und Lassen verantwortlich ist',
        'Weil Freiheit nur für wenige Menschen möglich ist',
        'Weil der Staat jede Freiheit sofort wieder einschränkt',
      ],
      correctIndex: 0,
      explanation: 'Wer frei ist, kann sich nicht hinter „ich bin eben so" '
          'verstecken.',
    ),
    Question(
      prompt: 'Wie sollen wir uns Sisyphos nach Camus vorstellen?',
      options: <String>[
        'Als einen verzweifelten Menschen',
        'Als einen Gott, der bald erlöst wird',
        'Als einen glücklichen Menschen',
      ],
      correctIndex: 2,
      explanation: 'Der Sinn liegt nicht im Ziel, sondern darin, die Aufgabe '
          'trotzdem voll anzunehmen.',
    ),
  ],
);

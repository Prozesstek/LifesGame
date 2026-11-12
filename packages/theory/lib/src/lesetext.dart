/// Wie der Text eines Abschnitts gesetzt wird.
///
/// | im Inhalt | auf der Buchseite |
/// |---|---|
/// | `*leicht*` | kursiv — eine einfache Betonung |
/// | `**Fachbegriff**` | fett — ein Fachbegriff, beim ersten Auftreten |
/// | ein Absatz ganz in `==…==` | ein **Merkkasten** „Merke“ |
/// | `[[merke]] Text` | dasselbe, ausgeschrieben |
/// | `[[definition: Begriff]] Text` | ein Kasten „Definition“, der Begriff als Titel |
/// | `[[beispiel]] Text` | ein Kasten „Beispiel“ |
/// | `[[bild: assets/… \| Unterschrift]]` | eine **Abbildung**, darunter „Abb. 1: …“ |
/// | `[[zier]]` | ein **Zierelement** (❦) als Trenner |
///
/// Absätze trennt eine Leerzeile (`\n\n`). Ein Kasten-Zeichen steht am
/// Anfang seines Absatzes, Bild und Zier stehen allein. Ein Text ohne
/// Zeichen bleibt ein Absatz, nichts betont. Die Zeichen gehören zum
/// Inhalt, deshalb steht ihr Verständnis hier und nicht in der App — und
/// `graph_content_test.dart` prüft jede Seite mit [Lesetext.fehler].
library;

/// Ein Stück Text — gewöhnlich, kursiv oder fett.
final class TextLauf {
  const TextLauf(this.text, {this.betont = false, this.kursiv = false});

  final String text;

  /// Fett: ein Fachbegriff (`**…**`).
  final bool betont;

  /// Kursiv: eine einfache Betonung (`*…*`).
  final bool kursiv;

  @override
  bool operator ==(Object other) =>
      other is TextLauf &&
      other.text == text &&
      other.betont == betont &&
      other.kursiv == kursiv;

  @override
  int get hashCode => Object.hash(text, betont, kursiv);

  @override
  String toString() => betont
      ? '**$text**'
      : kursiv
          ? '*$text*'
          : text;
}

/// Ein Absatz eines Abschnitts.
sealed class Absatz {
  const Absatz(this.laeufe);

  final List<TextLauf> laeufe;

  /// Der Text ohne Zeichen — für den Vorleser und für Tests.
  String get klartext => laeufe.map((l) => l.text).join();
}

/// Gewöhnlicher Text.
final class Fliesstext extends Absatz {
  const Fliesstext(super.laeufe);
}

/// Ein **Kasten** neben dem Fließtext: etwas dunkleres Papier, ein
/// Balken in der Farbe der Seite, oben ein kleines Label.
sealed class Kasten extends Absatz {
  const Kasten(super.laeufe);

  /// Das Label über dem Text, so wie es im Buch steht.
  String get label;

  /// Ein Titel neben dem Label — der Begriff einer Definition.
  String? get titel => null;
}

/// Der eine Satz, der hängen bleiben soll: „Merke“.
final class Merksatz extends Kasten {
  const Merksatz(super.laeufe);

  @override
  String get label => 'Merke';
}

/// Was ein Begriff heißt: „Definition“, der Begriff als Titel.
final class Definition extends Kasten {
  const Definition(super.laeufe, {required this.begriff});

  final String begriff;

  @override
  String get label => 'Definition';

  @override
  String get titel => begriff;

  @override
  String get klartext => '$begriff: ${super.klartext}';
}

/// Ein Fall aus dem Alltag: „Beispiel“.
final class Beispiel extends Kasten {
  const Beispiel(super.laeufe);

  @override
  String get label => 'Beispiel';
}

/// Ein Bild auf der Seite, darunter seine Unterschrift. Die Nummer
/// („Abb. 1“) zählt die App über die ganze Lektion.
final class Abbildung extends Absatz {
  const Abbildung(super.laeufe, {required this.pfad});

  /// Der Pfad des Bilds unter `assets/`.
  final String pfad;
}

/// Ein Zierelement, das einen Gedanken vom nächsten trennt.
final class Zier extends Absatz {
  const Zier() : super(const <TextLauf>[]);
}

/// Liest die Zeichen eines Abschnitts.
abstract final class Lesetext {
  static const String _betont = '**';
  static const String _kursiv = '*';
  static const String _merksatz = '==';

  /// `[[art]]` oder `[[art: wert]]` am Anfang eines Absatzes, danach der
  /// Text.
  static final RegExp _marke =
      RegExp(r'^\[\[\s*([a-zäöü]+)\s*(?::([^\]]*))?\]\]');

  static const Set<String> _arten = <String>{
    'merke',
    'definition',
    'beispiel',
    'bild',
    'zier',
  };

  /// Die Absätze eines Texts. Ein offenes `**` betont bis zum Ende des
  /// Absatzes — [fehler] meldet es.
  static List<Absatz> aus(String text) => <Absatz>[
        for (final roh in _absaetze(text)) _absatz(roh),
      ];

  /// Der ganze Text ohne Zeichen, Absätze durch eine Leerzeile getrennt.
  /// Zierelemente fallen weg, von einer Abbildung bleibt ihre Unterschrift.
  static String klartext(String text) => aus(
        text,
      ).map((a) => a.klartext).where((t) => t.isNotEmpty).join('\n\n');

  /// Was an den Zeichen nicht stimmt — leer, wenn alles geschlossen ist.
  static List<String> fehler(String text) => <String>[
        for (final roh in _absaetze(text)) ..._fehlerIn(roh),
      ];

  static List<String> _fehlerIn(String roh) {
    final marke = _marke.firstMatch(roh);
    final art = marke?.group(1);
    final wert = marke?.group(2)?.trim() ?? '';
    final rest = marke == null ? roh : roh.substring(marke.end).trim();
    return <String>[
      if (art != null && !_arten.contains(art))
        'unbekanntes Zeichen „[[$art]]“: „${_anfang(roh)}“',
      if (art == null && roh.contains('[['))
        '„[[…]]“ nur am Anfang eines Absatzes: „${_anfang(roh)}“',
      if (art == 'definition' && wert.isEmpty)
        'eine Definition ohne Begriff: „${_anfang(roh)}“',
      if ((art == 'merke' || art == 'definition' || art == 'beispiel') &&
          rest.isEmpty)
        'ein leerer Kasten: „${_anfang(roh)}“',
      if (art == 'bild' && !_bildStimmt(wert))
        'ein Bild braucht „Pfad | Unterschrift“: „${_anfang(roh)}“',
      if ((art == 'bild' || art == 'zier') && rest.isNotEmpty)
        '„[[$art]]“ steht allein in seinem Absatz: „${_anfang(roh)}“',
      if (_betont.allMatches(rest).length.isOdd)
        'ein „**“ bleibt offen: „${_anfang(roh)}“',
      if (_ohneFett(rest).split(_kursiv).length.isEven)
        'ein „*“ bleibt offen: „${_anfang(roh)}“',
      if (!_istMerksatz(roh) && roh.contains(_merksatz))
        '„==“ nur um einen ganzen Absatz: „${_anfang(roh)}“',
      if (_istMerksatz(roh) && roh.substring(2, roh.length - 2).trim().isEmpty)
        'ein leerer Merksatz',
    ];
  }

  static bool _bildStimmt(String wert) {
    final teile = wert.split('|');
    return teile.length == 2 &&
        teile[0].trim().startsWith('assets/') &&
        teile[1].trim().isNotEmpty;
  }

  static Absatz _absatz(String roh) {
    if (_istMerksatz(roh)) {
      return Merksatz(_laeufe(roh.substring(2, roh.length - 2).trim()));
    }
    final marke = _marke.firstMatch(roh);
    if (marke == null) return Fliesstext(_laeufe(roh));
    final wert = marke.group(2)?.trim() ?? '';
    final rest = _laeufe(roh.substring(marke.end).trim());
    switch (marke.group(1)) {
      case 'merke':
        return Merksatz(rest);
      case 'definition':
        return Definition(rest, begriff: wert);
      case 'beispiel':
        return Beispiel(rest);
      case 'bild':
        final teile = wert.split('|');
        return Abbildung(
          _laeufe(teile.length > 1 ? teile[1].trim() : ''),
          pfad: teile[0].trim(),
        );
      case 'zier':
        return const Zier();
    }
    // Ein unbekanntes Zeichen bleibt als Text stehen — [fehler] meldet es.
    return Fliesstext(_laeufe(roh));
  }

  static Iterable<String> _absaetze(String text) => text
      .split(RegExp(r'\n\s*\n'))
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty);

  static bool _istMerksatz(String absatz) =>
      absatz.length >= 4 &&
      absatz.startsWith(_merksatz) &&
      absatz.endsWith(_merksatz);

  /// Erst `**` für fett, dann in allem anderen `*` für kursiv.
  static List<TextLauf> _laeufe(String absatz) {
    final teile = absatz.split(_betont);
    return <TextLauf>[
      for (var i = 0; i < teile.length; i++)
        ...(i.isOdd
            ? <TextLauf>[
                if (teile[i].isNotEmpty) TextLauf(teile[i], betont: true),
              ]
            : _kursivIn(teile[i])),
    ];
  }

  static List<TextLauf> _kursivIn(String text) {
    final teile = text.split(_kursiv);
    return <TextLauf>[
      for (var i = 0; i < teile.length; i++)
        if (teile[i].isNotEmpty) TextLauf(teile[i], kursiv: i.isOdd),
    ];
  }

  static String _ohneFett(String text) => text.replaceAll(_betont, '');

  static String _anfang(String absatz) =>
      absatz.length <= 40 ? absatz : '${absatz.substring(0, 40)}…';
}

/// Wie der Text eines Abschnitts gesetzt wird — **zwei Zeichen, mehr
/// nicht.**
///
/// | im Inhalt | auf dem Bildschirm |
/// |---|---|
/// | `**Spannung**` | betont: fett, in der Farbe der Seite |
/// | ein Absatz ganz in `==…==` | ein **Merksatz**: groß, auf eigener Fläche |
///
/// Absätze trennt eine Leerzeile (`\n\n`). Ein Text ohne Zeichen bleibt,
/// wie er ist: ein Absatz, nichts betont. Die Zeichen gehören zum Inhalt,
/// deshalb steht ihr Verständnis hier und nicht in der App — und
/// `content_test.dart` prüft jede Seite darauf, dass keins offen bleibt.
library;

/// Ein Stück Text, betont oder nicht.
final class TextLauf {
  const TextLauf(this.text, {this.betont = false});

  final String text;
  final bool betont;

  @override
  bool operator ==(Object other) =>
      other is TextLauf && other.text == text && other.betont == betont;

  @override
  int get hashCode => Object.hash(text, betont);

  @override
  String toString() => betont ? '**$text**' : text;
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

/// Der eine Satz, der hängen bleiben soll.
final class Merksatz extends Absatz {
  const Merksatz(super.laeufe);
}

/// Liest die Zeichen eines Abschnitts.
abstract final class Lesetext {
  static const String _betont = '**';
  static const String _merksatz = '==';

  /// Die Absätze eines Texts. Ein offenes `**` betont bis zum Ende des
  /// Absatzes — [fehler] meldet es.
  static List<Absatz> aus(String text) => <Absatz>[
        for (final roh in _absaetze(text))
          if (_istMerksatz(roh))
            Merksatz(_laeufe(roh.substring(2, roh.length - 2).trim()))
          else
            Fliesstext(_laeufe(roh)),
      ];

  /// Der ganze Text ohne Zeichen, Absätze durch eine Leerzeile getrennt.
  static String klartext(String text) =>
      aus(text).map((a) => a.klartext).join('\n\n');

  /// Was an den Zeichen nicht stimmt — leer, wenn alles geschlossen ist.
  static List<String> fehler(String text) => <String>[
        for (final roh in _absaetze(text)) ...<String>[
          if (_betont.allMatches(roh).length.isOdd)
            'ein „**“ bleibt offen: „${_anfang(roh)}“',
          if (!_istMerksatz(roh) && roh.contains(_merksatz))
            '„==“ nur um einen ganzen Absatz: „${_anfang(roh)}“',
          if (_istMerksatz(roh) &&
              roh.substring(2, roh.length - 2).trim().isEmpty)
            'ein leerer Merksatz',
        ],
      ];

  static Iterable<String> _absaetze(String text) => text
      .split(RegExp(r'\n\s*\n'))
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty);

  static bool _istMerksatz(String absatz) =>
      absatz.length >= 4 &&
      absatz.startsWith(_merksatz) &&
      absatz.endsWith(_merksatz);

  static List<TextLauf> _laeufe(String absatz) {
    final teile = absatz.split(_betont);
    return <TextLauf>[
      for (var i = 0; i < teile.length; i++)
        if (teile[i].isNotEmpty) TextLauf(teile[i], betont: i.isOdd),
    ];
  }

  static String _anfang(String absatz) =>
      absatz.length <= 40 ? absatz : '${absatz.substring(0, 40)}…';
}

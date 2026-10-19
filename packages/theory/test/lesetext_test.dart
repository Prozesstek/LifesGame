import 'package:test/test.dart';
import 'package:theory/theory.dart';

void main() {
  test('ein Text ohne Zeichen bleibt ein Absatz, nichts betont', () {
    final absaetze = Lesetext.aus('Ein Muskel wächst unter Spannung.');

    expect(absaetze, hasLength(1));
    expect(absaetze.single, isA<Fliesstext>());
    expect(absaetze.single.laeufe, const <TextLauf>[
      TextLauf('Ein Muskel wächst unter Spannung.'),
    ]);
  });

  test('** betont, was dazwischen steht', () {
    final laeufe =
        Lesetext.aus('Das **Signal** ist die Spannung.').single.laeufe;

    expect(laeufe, const <TextLauf>[
      TextLauf('Das '),
      TextLauf('Signal', betont: true),
      TextLauf(' ist die Spannung.'),
    ]);
  });

  test('eine Leerzeile trennt Absätze, == macht einen Merksatz', () {
    final absaetze = Lesetext.aus(
      'Erst der Text.\n\n==Spannung ist das Signal.==\n\nDann **mehr**.',
    );

    expect(absaetze.map((a) => a.runtimeType), <Type>[
      Fliesstext,
      Merksatz,
      Fliesstext,
    ]);
    expect(absaetze[1].klartext, 'Spannung ist das Signal.');
  });

  test('der Klartext hat keine Zeichen mehr', () {
    expect(
      Lesetext.klartext('Das **Signal**.\n\n==Merk dir das.=='),
      'Das Signal.\n\nMerk dir das.',
    );
  });

  test('offene und falsch gesetzte Zeichen werden gemeldet', () {
    expect(Lesetext.fehler('Alles **gut** hier.'), isEmpty);
    expect(Lesetext.fehler('==Ein Merksatz.=='), isEmpty);
    expect(Lesetext.fehler('Ein **offenes Zeichen.'), hasLength(1));
    expect(Lesetext.fehler('Mitten ==im== Satz.'), hasLength(1));
    expect(Lesetext.fehler('====\n\nText.'), isNotEmpty);
  });
}

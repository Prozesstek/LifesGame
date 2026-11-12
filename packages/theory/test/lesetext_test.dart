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

  test('* setzt kursiv, ** bleibt fett', () {
    final laeufe = Lesetext.aus(
      'Das ist *wichtig*, die **Überlastung** auch.',
    ).single.laeufe;

    expect(laeufe, const <TextLauf>[
      TextLauf('Das ist '),
      TextLauf('wichtig', kursiv: true),
      TextLauf(', die '),
      TextLauf('Überlastung', betont: true),
      TextLauf(' auch.'),
    ]);
  });

  test('Kästen: Merke, Definition mit Begriff, Beispiel', () {
    final absaetze = Lesetext.aus(
      '[[merke]] Erst die Last.\n\n'
      '[[definition: Progressive Überlastung]] Die Last steigt.\n\n'
      '[[beispiel]] Jede Woche ein Kilo mehr.',
    );

    expect(absaetze.map((a) => a.runtimeType), <Type>[
      Merksatz,
      Definition,
      Beispiel,
    ]);
    final definition = absaetze[1] as Definition;
    expect(definition.label, 'Definition');
    expect(definition.titel, 'Progressive Überlastung');
    expect(definition.klartext, 'Progressive Überlastung: Die Last steigt.');
    expect((absaetze[2] as Kasten).label, 'Beispiel');
  });

  test('Bild und Zier stehen allein, die Unterschrift bleibt im Klartext', () {
    const text = 'Vorher.\n\n'
        '[[bild: assets/Faehigkeiten/Bestform.png | Der Muskel antwortet]]'
        '\n\n[[zier]]';
    final absaetze = Lesetext.aus(text);

    final bild = absaetze[1] as Abbildung;
    expect(bild.pfad, 'assets/Faehigkeiten/Bestform.png');
    expect(bild.klartext, 'Der Muskel antwortet');
    expect(absaetze[2], isA<Zier>());
    expect(Lesetext.klartext(text), 'Vorher.\n\nDer Muskel antwortet');
    expect(Lesetext.fehler(text), isEmpty);
  });

  test('falsch gesetzte neue Zeichen werden gemeldet', () {
    expect(Lesetext.fehler('Ein *offenes Wort.'), hasLength(1));
    expect(Lesetext.fehler('[[kasten]] Gibt es nicht.'), isNotEmpty);
    expect(Lesetext.fehler('[[definition]] Ohne Begriff.'), isNotEmpty);
    expect(Lesetext.fehler('[[merke]]'), isNotEmpty);
    expect(Lesetext.fehler('[[bild: assets/a.png]]'), isNotEmpty);
    expect(Lesetext.fehler('[[zier]] mit Text'), isNotEmpty);
    expect(Lesetext.fehler('Mitten [[zier]] im Satz.'), isNotEmpty);
  });
}

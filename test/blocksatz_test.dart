import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/silbentrennung.dart';
import 'package:lifes_game/theory/widgets/blocksatz.dart';

/// Der Blocksatz des Lernbuchs: Ein sichtbarer Trennstrich steht nur am
/// Zeilenende, und neben der Initiale geht kein Wort verloren — beides
/// war in der ersten Vorschau (12.11.2026) falsch, weil das Bild einen
/// Stil erbte, den die Probe-Messung nicht kannte.
void main() {
  final trennung = Silbentrennung.aus(
    File(Silbentrennung.pfad).readAsStringSync(),
  );
  const satz =
      'Muskeln wachsen nicht, weil man trainiert, sondern weil sie etwas '
      'gefordert hat, das sie noch nicht gewohnt waren. Deshalb steigert '
      'gutes Training die Anforderung langsam mit mehr Wiederholungen.';
  const stil = TextStyle(fontSize: 17, height: 1.55);

  List<SatzStueck> stuecke(String text) => <SatzStueck>[
    for (final m in RegExp(r'\s+|[^\s]+').allMatches(text))
      SatzStueck(
        m.group(0)!.trim().isEmpty ? m.group(0)! : trennung.trenne(m.group(0)!),
        stil,
      ),
  ];

  Future<void> zeige(WidgetTester tester, Widget kind) async {
    await tester.pumpWidget(
      MaterialApp(
        // Ein geerbter Buchstabenabstand — genau das hat die Probe verfehlt.
        theme: ThemeData(
          textTheme: const TextTheme(bodyMedium: TextStyle(letterSpacing: 1)),
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, child: kind),
          ),
        ),
      ),
    );
  }

  String sichtbar(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((r) => r.text.toPlainText(includePlaceholders: false))
      .join();

  /// Jeder sichtbare Strich steht am Ende seiner Zeile.
  void nurAmZeilenende(WidgetTester tester) {
    for (final element in find.byType(RichText).evaluate()) {
      final absatz = element.renderObject! as RenderParagraph;
      final text = absatz.text.toPlainText(includePlaceholders: false);
      for (var i = text.indexOf('-'); i >= 0; i = text.indexOf('-', i + 1)) {
        if (i + 1 >= text.length) continue;
        double oben(int von) => absatz
            .getBoxesForSelection(
              TextSelection(baseOffset: von, extentOffset: von + 1),
            )
            .first
            .top;
        // Das Zeichen danach steht eine Zeile tiefer.
        expect(
          oben(i + 1),
          greaterThan(oben(i)),
          reason: 'Strich mitten in der Zeile: $text',
        );
      }
    }
  }

  testWidgets('getrennt wird nur am Zeilenende, und mit Strich', (
    tester,
  ) async {
    await zeige(tester, Blocksatz(stuecke: stuecke(satz)));

    final text = sichtbar(tester);
    expect(text, contains('-'), reason: 'bei 300 Punkten wird getrennt');
    nurAmZeilenende(tester);
    expect(text.replaceAll('-', '').replaceAll(Silbentrennung.weich, ''), satz);
  });

  testWidgets('neben der Initiale geht kein Wort verloren', (tester) async {
    final teile = stuecke(satz.substring(1));
    await zeige(
      tester,
      Blocksatz(
        stuecke: teile,
        initiale: const Text('M', style: TextStyle(fontSize: 92)),
      ),
    );

    nurAmZeilenende(tester);
    expect(
      sichtbar(tester)
          .replaceAll('-', '')
          .replaceAll(Silbentrennung.weich, '')
          // Der Platzhalter hinter der dritten Zeile bringt einen Leerraum.
          .replaceAll(RegExp(' +'), ' '),
      satz,
    );
  });
}

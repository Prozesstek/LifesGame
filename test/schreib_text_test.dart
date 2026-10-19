import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/widgets/schreib_text.dart';

/// Ein Abschnitt schreibt sich Wort für Wort — und steht dabei von Anfang
/// an ganz im Layout, nur durchsichtig.
void main() {
  const body =
      'Ein Muskel wächst unter **Spannung**. Das ist alles.\n\n'
      '==Das Signal ist die Spannung.==';

  Future<void> zeige(
    WidgetTester tester, {
    bool aktiv = true,
    bool sofort = false,
    bool ohneBewegung = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: ohneBewegung),
          child: Scaffold(
            body: SchreibText(
              heading: 'Spannung ist das Signal',
              body: body,
              aktiv: aktiv,
              sofort: sofort,
            ),
          ),
        ),
      ),
    );
  }

  /// Die Deckkraft jedes Worts im Text, in seiner Reihenfolge — ohne die
  /// Überschrift, die ihre eigene Bewegung hat.
  List<double> deckkraft(WidgetTester tester) {
    final werte = <double>[];
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      if (text.text.toPlainText() == 'Spannung ist das Signal') continue;
      text.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').trim().isNotEmpty) {
          werte.add(span.style?.color?.a ?? 1);
        }
        return true;
      });
    }
    return werte;
  }

  testWidgets('die Zeichen stehen nicht im Bild, der Text schon', (
    tester,
  ) async {
    await zeige(tester, sofort: true);

    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('=='), findsNothing);
    expect(
      find.text('Ein Muskel wächst unter Spannung. Das ist alles.'),
      findsOneWidget,
    );
    expect(find.text('Das Signal ist die Spannung.'), findsOneWidget);
  });

  testWidgets('am Anfang ist nichts zu sehen, am Ende alles', (tester) async {
    await zeige(tester);
    expect(deckkraft(tester).every((a) => a == 0), isTrue);

    await tester.pump(const Duration(milliseconds: 450));
    final mitten = deckkraft(tester);
    expect(mitten.first, 1);
    expect(mitten.last, 0);

    await tester.pumpAndSettle();
    expect(deckkraft(tester).every((a) => a == 1), isTrue);
  });

  testWidgets('ein Tipp zeigt den ganzen Text', (tester) async {
    await zeige(tester);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byType(SchreibText));
    await tester.pump();

    expect(deckkraft(tester).every((a) => a == 1), isTrue);
  });

  testWidgets('nicht zu sehen, schreibt er nicht', (tester) async {
    await zeige(tester, aktiv: false);
    await tester.pump(const Duration(seconds: 5));

    expect(deckkraft(tester).every((a) => a == 0), isTrue);
  });

  testWidgets('wer Bewegung abgeschaltet hat, bekommt alles sofort', (
    tester,
  ) async {
    await zeige(tester, ohneBewegung: true);
    await tester.pump();

    expect(deckkraft(tester).every((a) => a == 1), isTrue);
  });

  testWidgets('der erste Satz ist größer, der Merksatz am größten', (
    tester,
  ) async {
    await zeige(tester, sofort: true);

    double groesse(String wort) {
      for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
        double? gefunden;
        text.text.visitChildren((span) {
          if (span is TextSpan && span.text == wort) {
            gefunden = span.style?.fontSize;
            return false;
          }
          return true;
        });
        if (gefunden != null) return gefunden!;
      }
      fail('„$wort“ nicht gefunden');
    }

    expect(groesse('Muskel'), greaterThan(groesse('alles.')));
    expect(groesse('Signal'), greaterThan(groesse('Muskel')));
  });
}

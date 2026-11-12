import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/theory/widgets/buch_stil.dart';
import 'package:lifes_game/theory/widgets/schreib_text.dart';

/// Ein Abschnitt schreibt sich Wort für Wort — und steht dabei von Anfang
/// an ganz im Layout, nur durchsichtig.
void main() {
  const body =
      'Ein Muskel wächst unter **Spannung**. Das ist *alles*.\n\n'
      '==Das Signal ist die Spannung.==';

  /// Was nicht mitschreibt: das Label des Kastens und die Zier.
  const fest = <String>{'MERKE', BuchStil.zier};

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
      final klar = text.text.toPlainText();
      if (klar == 'Spannung ist das Signal' || fest.contains(klar)) continue;
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
    expect(find.textContaining('*'), findsNothing);
    // Der erste Buchstabe steht als Initiale, der Vorleser hört den Satz.
    expect(
      find.bySemanticsLabel('Ein Muskel wächst unter Spannung. Das ist alles.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Das Signal ist die Spannung.'),
      findsOneWidget,
    );
    expect(find.text('MERKE'), findsOneWidget);
    expect(find.byKey(SchreibText.zierKey), findsOneWidget);
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

  testWidgets('Initiale groß, Fließtext ab 17, fett und kursiv gesetzt', (
    tester,
  ) async {
    await zeige(tester, sofort: true);

    TextStyle stil(String wort) {
      for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
        TextStyle? gefunden;
        text.text.visitChildren((span) {
          if (span is TextSpan && span.text == wort) {
            gefunden = span.style;
            return false;
          }
          return true;
        });
        final g = gefunden;
        if (g != null) return g;
      }
      fail('„$wort“ nicht gefunden');
    }

    expect(stil('E').fontSize, BuchStil.initialeGroesse);
    expect(stil('in').fontSize, greaterThanOrEqualTo(17));
    expect(stil('Spannung').fontVariations?.single.value, 700);
    expect(stil('alles').fontStyle, FontStyle.italic);
    expect(stil('Muskel').fontStyle, isNot(FontStyle.italic));
  });
}

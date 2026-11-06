import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haustier/haustier.dart';
import 'package:lifes_game/haustier/widgets/haustier_bild.dart';
import 'package:lifes_game/theory/widgets/umblaettern.dart';
import 'package:lifes_game/ui/pulsieren.dart';

/// Zählt, wie oft er malt — der Nachbar, der nicht mitmalen soll.
class _Zaehler extends CustomPainter {
  int mal = 0;

  @override
  void paint(Canvas canvas, Size size) => mal++;

  @override
  bool shouldRepaint(_Zaehler alt) => false;
}

/// Was ohne Ende läuft, liegt auf einer eigenen Ebene. Sonst malt jedes
/// Bild der Animation alles daneben neu — die Startseite mit Berg und
/// Holzrahmen sechzigmal je Sekunde.
void main() {
  Future<_Zaehler> neben(WidgetTester tester, Widget animiert) async {
    final zaehler = _Zaehler();
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[
            CustomPaint(painter: zaehler, size: const Size(100, 100)),
            animiert,
          ],
        ),
      ),
    );
    zaehler.mal = 0;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return zaehler;
  }

  testWidgets('Pulsieren malt den Nachbarn nicht mit', (tester) async {
    Pulsieren.pulsiert = true;
    addTearDown(() => Pulsieren.pulsiert = false);

    final zaehler = await neben(
      tester,
      const Pulsieren(aktiv: true, child: SizedBox.square(dimension: 40)),
    );
    expect(zaehler.mal, 0);
  });

  testWidgets('das Haustier malt den Nachbarn nicht mit', (tester) async {
    HaustierBild.lebt = true;
    addTearDown(() => HaustierBild.lebt = false);

    final zaehler = await neben(
      tester,
      HaustierBild(
        art: HaustierArt.values.first,
        stufe: HaustierStufe.values.first,
        laune: HaustierLaune.values.first,
      ),
    );
    expect(zaehler.mal, 0);
  });

  testWidgets('das Buchpapier malt nicht mit, wenn der Text wechselt', (
    tester,
  ) async {
    Widget seite(String text) => MaterialApp(
      home: SizedBox(
        width: 300,
        height: 500,
        child: BuchPapier(child: Text(text)),
      ),
    );
    await tester.pumpWidget(seite('eins'));
    final papier = find.descendant(
      of: find.byType(BuchPapier),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter != null,
      ),
    );
    final ebene = tester.renderObject<RenderRepaintBoundary>(
      find.ancestor(of: papier, matching: find.byType(RepaintBoundary)).first,
    );
    final vorher =
        ebene.debugSymmetricPaintCount + ebene.debugAsymmetricPaintCount;

    for (final text in <String>['eins zwei', 'eins zwei drei']) {
      await tester.pumpWidget(seite(text));
    }
    expect(
      ebene.debugSymmetricPaintCount + ebene.debugAsymmetricPaintCount,
      vorher,
    );
  });
}

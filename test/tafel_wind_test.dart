import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/lagerfeuer/widgets/feuer_bild.dart';
import 'package:lifes_game/lagerfeuer/widgets/karten_feuer.dart';
import 'package:lifes_game/ui/anschlagtafel.dart';
import 'package:lifes_game/ui/tafel_wind.dart';

/// Der Wind über der Anschlagtafel und das Feuer auf der Karte der
/// Startseite (16.11.2026) — beide **nur Darstellung**, und beide sollen
/// wenig kosten: Der Wind tut zwischen zwei Stößen nichts, das Feuer malt
/// gedrosselt und nur sich selbst.
void main() {
  group('TafelWind.winkel', () {
    test('vor und nach dem Stoß hängt jeder Zettel still', () {
      for (final versatz in <double>[0, 0.5, 1]) {
        expect(TafelWind.winkel(0, versatz: versatz), 0);
        expect(TafelWind.winkel(1, versatz: versatz), 0);
      }
    });

    test('der Ausschlag bleibt klein', () {
      for (var t = 0.0; t <= 1; t += 0.01) {
        expect(
          TafelWind.winkel(t).abs(),
          lessThanOrEqualTo(TafelWind.ausschlag),
        );
      }
    });

    test('der Stoß kommt beim letzten Zettel später an', () {
      expect(TafelWind.winkel(0.1), isNot(0));
      expect(TafelWind.winkel(0.1, versatz: 1), 0);
      expect(TafelWind.winkel(0.6, versatz: 1), isNot(0));
    });
  });

  group('auf der Tafel', () {
    Widget tafel() {
      return const MaterialApp(
        home: Scaffold(
          body: TafelWind(
            child: Anschlagtafel(child: Steckbrief(child: Text('Zettel'))),
          ),
        ),
      );
    }

    double winkelImBild(WidgetTester tester) {
      final drehung = tester.widget<Transform>(
        find
            .ancestor(of: find.text('Zettel'), matching: find.byType(Transform))
            .last,
      );
      // sin des Winkels steht in der Matrix.
      return drehung.transform.entry(1, 0);
    }

    testWidgets('ohne Wind steht alles, und nichts läuft weiter', (
      tester,
    ) async {
      await tester.pumpWidget(tafel());
      await tester.pump(const Duration(seconds: 30));

      expect(winkelImBild(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('ein Stoß lässt den Zettel flattern und geht vorbei', (
      tester,
    ) async {
      TafelWind.weht = true;
      addTearDown(() => TafelWind.weht = false);
      await tester.pumpWidget(tafel());

      // Bis zum ersten Stoß läuft kein Takt.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      expect(winkelImBild(tester), 0);

      await tester.pump(TafelWind.erster);
      await tester.pump(const Duration(milliseconds: 200));
      expect(winkelImBild(tester), isNot(0));

      // Danach hängt er wieder still — bis zum nächsten.
      await tester.pump(TafelWind.dauer + const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
      expect(winkelImBild(tester), 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('wer Bewegung abgeschaltet hat, bekommt keinen Wind', (
      tester,
    ) async {
      TafelWind.weht = true;
      addTearDown(() => TafelWind.weht = false);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: tafel(),
        ),
      );
      await tester.pump(TafelWind.erster + const Duration(seconds: 1));

      expect(winkelImBild(tester), 0);
    });
  });

  group('KartenFeuer', () {
    Widget karte(void Function() nachbarMalt) {
      return MaterialApp(
        home: Center(
          child: SizedBox(
            width: 340,
            height: 68,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(painter: _Zaehler(nachbarMalt)),
                ),
                const Positioned.fill(child: KartenFeuer(brennt: true)),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('in Tests steht das Feuer', (tester) async {
      await tester.pumpWidget(karte(() {}));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('es flackert in eigener Ebene: der Nachbar malt nicht mit', (
      tester,
    ) async {
      FeuerBild.flackert = true;
      addTearDown(() => FeuerBild.flackert = false);
      var gemalt = 0;
      await tester.pumpWidget(karte(() => gemalt++));
      final vorher = gemalt;

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tester.takeException(), isNull);
      expect(gemalt, vorher);
    });
  });
}

class _Zaehler extends CustomPainter {
  _Zaehler(this.malt);

  final void Function() malt;

  @override
  void paint(Canvas canvas, Size size) => malt();

  @override
  bool shouldRepaint(_Zaehler alt) => false;
}

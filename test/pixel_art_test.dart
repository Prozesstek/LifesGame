import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/ui/gold_icon.dart';
import 'package:lifes_game/ui/pixel_art.dart';

/// Wie eine Zeichnung skaliert wird.
///
/// **Die Regel ist gerechnet und nicht angesehen.** Ob eine Münze
/// zerfressen aussieht, sieht man auf einem Screenshot erst, wenn man
/// weiß, wonach man sucht — die Grenze dagegen ist eine Zahl und lässt
/// sich festhalten.
void main() {
  group('Hart skalieren nur oberhalb der Zeichengröße', () {
    test('eine Kampfkachel bleibt hart', () {
      // 88 Punkte auf einem Handy mit dreifacher Dichte: jeder
      // gezeichnete Bildpunkt bekommt vier echte.
      expect(PixelArt.qualityFor(88, 3), FilterQuality.none);
    });

    test('der Knopfkreis auch im Browser ohne Vergrößerung', () {
      // 72 Punkte bei einfacher Dichte sind 72 echte Pixel für 64
      // gezeichnete — knapp, aber keiner fällt weg.
      expect(PixelArt.qualityFor(HubCircle.diameter, 1), FilterQuality.none);
    });

    test('die Goldmünze wird weich gezeichnet', () {
      // 18 Punkte bei einfacher Dichte: 64 gezeichnete Bildpunkte auf 18
      // echten. Hart skaliert fiele jeder dritte weg.
      expect(PixelArt.qualityFor(18, 1), FilterQuality.medium);
    });

    test('auf einem dichten Bildschirm darf dieselbe Münze hart bleiben', () {
      // 18 × 4 = 72 echte Pixel — dort geht nichts mehr verloren.
      expect(PixelArt.qualityFor(18, 4), FilterQuality.none);
    });

    test('genau an der Grenze wird hart skaliert', () {
      expect(
        PixelArt.qualityFor(PixelArt.artSize.toDouble(), 1),
        FilterQuality.none,
      );
      expect(
        PixelArt.qualityFor(PixelArt.artSize - 1, 1),
        FilterQuality.medium,
      );
    });
  });

  group('Fehlt die Datei, steht der Rückfall da', () {
    testWidgets('statt eines geworfenen Fehlers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PixelArt(
            assetPath: 'assets/gibt-es-nicht.png',
            side: 24,
            fallback: Text('Ersatz'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ersatz'), findsOneWidget);
    });

    testWidgets('auch bei der Goldmünze', (tester) async {
      // Sie ist wirklich abgelegt — der Test prüft hier nur, dass das
      // Widget baut und nicht wirft.
      await tester.pumpWidget(const MaterialApp(home: GoldIcon()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

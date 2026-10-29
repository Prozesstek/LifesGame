import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/home/home_screen.dart';
import 'package:lifes_game/home/widgets/hub_circle.dart';
import 'package:lifes_game/ui/bereich_zeichen.dart';

/// Wie weit das Bild [pfad] von seiner Mitte reicht, in halben
/// Bildbreiten — der äußerste Bildpunkt, der sichtbar ist.
Future<double> _gemessen(String pfad) async {
  final daten = await rootBundle.load(pfad);
  final codec = await ui.instantiateImageCodec(daten.buffer.asUint8List());
  final bild = (await codec.getNextFrame()).image;
  final rgba = (await bild.toByteData())!;
  final b = bild.width;
  final h = bild.height;
  var weiteste = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < b; x++) {
      if (rgba.getUint8((y * b + x) * 4 + 3) <= 40) continue;
      // Die äußere Ecke des Bildpunkts, nicht seine Mitte.
      final dx = (x + 0.5 - b / 2).abs() + 0.5;
      final dy = (y + 0.5 - h / 2).abs() + 0.5;
      weiteste = math.max(weiteste, math.sqrt(dx * dx + dy * dy));
    }
  }
  return weiteste / (b / 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keine Reichweite ist kleiner als gemessen', () async {
    for (final pfad in BereichZeichen.alle) {
      final gemessen = await _gemessen(pfad);
      expect(
        BereichZeichen.reichweite(pfad),
        greaterThanOrEqualTo(gemessen),
        reason: '$pfad reicht bis ${gemessen.toStringAsFixed(3)}',
      );
    }
  });

  test('jedes Zeichen bleibt innerhalb seines Kreises', () {
    // Die Pergamentfläche von ButtonBG.png endet bei 0,875 der halben
    // Breite, 16 von 128 Bildpunkten sind Rand.
    const flaeche = 0.875;
    for (final size in <double>[
      HubCircle.diameter,
      HomeScreen.bottomCircleSize,
    ]) {
      for (final pfad in BereichZeichen.alle) {
        final seite = HubCircle.symbolSideFor(pfad, size);
        final reicht = BereichZeichen.reichweite(pfad) * seite / 2;
        expect(reicht, lessThan(flaeche * size / 2), reason: pfad);
      }
    }
  });

  test('die Schwerter werden kleiner, der Helm bleibt groß', () {
    const size = HubCircle.diameter;
    expect(
      HubCircle.symbolSideFor(BereichZeichen.kampf, size),
      lessThan(HubCircle.symbolSideFor(BereichZeichen.charakter, size)),
    );
    expect(
      HubCircle.symbolSideFor(BereichZeichen.charakter, size),
      closeTo(size * HubCircle.symbolAnteil, 0.001),
    );
  });
}

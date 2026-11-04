import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifes_game/ui/holz.dart';
import 'package:lifes_game/ui/holz_teile.dart';

/// Planke, Knopf, Seil und Balken — gemalt wie der Rahmen (ADR-0099).
void main() {
  test('die Planke hat abgeschrägte Ecken und Messingnägel an den Enden', () {
    const m = PlankenMaler();
    const w = 60, h = 23;
    expect(m.farbe(0, 0, w, h), isNull, reason: 'Ecke abgeschrägt');
    expect(m.farbe(w - 1, h - 1, w, h), isNull);
    expect(m.farbe(3, h ~/ 2 - 1, w, h), HolzTon.messingHell);
    expect(m.farbe(w - 5, h ~/ 2 - 1, w, h), HolzTon.messingHell);
    // Licht oben, Schatten unten.
    expect(m.farbe(w ~/ 2, 1, w, h), HolzTon.glanz);
    expect(m.farbe(w ~/ 2, h - 2, w, h), HolzTon.tief);
  });

  test('gedrückt dreht der Knopf sein Licht um', () {
    const auf = KnopfMaler(), zu = KnopfMaler(gedrueckt: true);
    const s = 14;
    expect(auf.farbe(6, 1, s, s), HolzTon.glanz);
    expect(zu.farbe(6, 1, s, s), HolzTon.tief);
    expect(auf.farbe(6, s - 2, s, s), HolzTon.tief);
    expect(zu.farbe(6, s - 2, s, s), HolzTon.licht);
  });

  test('das Seil hängt an einem Messingring, mit einem Knoten je Ende', () {
    const m = SeilMaler();
    const w = 61, h = 23;
    final farben = <Color>{
      for (var y = 0; y < 9; y++)
        for (var x = 25; x < 36; x++) ?m.farbe(x, y, w, h),
    };
    expect(farben, contains(HolzTon.messing));
    expect(m.farbe(3, h - 2, w, h), isNotNull, reason: 'Knoten links');
    expect(m.farbe(w - 4, h - 2, w, h), isNotNull, reason: 'Knoten rechts');
  });

  test(
    'der Balken lässt innen eine Rinne frei, gleich weit von beiden Enden',
    () {
      const m = BalkenMaler();
      const w = 80, h = BalkenMaler.hoehe;
      const y = BalkenMaler.rinneOben + 2;
      expect(m.farbe(BalkenMaler.rinneLinks, y, w, h), HolzTon.rinne);
      expect(m.farbe(w - 1 - BalkenMaler.rinneRechts, y, w, h), HolzTon.rinne);
      expect(
        m.farbe(BalkenMaler.rinneLinks - 1, y, w, h),
        isNot(HolzTon.rinne),
      );
      expect(BalkenMaler.rinneLinks, BalkenMaler.rinneRechts);
      // Messingkappen an beiden Enden.
      expect(m.farbe(2, y, w, h), HolzTon.messing);
      expect(m.farbe(w - 3, y, w, h), HolzTon.messing);
    },
  );

  test('zu klein: malt nichts und wirft nicht', () {
    for (final maler in <CustomPainter>[
      const PlankenMaler(),
      const KnopfMaler(),
      const SeilMaler(),
      const BalkenMaler(),
    ]) {
      final recorder = ui.PictureRecorder();
      maler.paint(Canvas(recorder), const Size(3, 3));
      recorder.endRecording().dispose();
    }
  });

  testWidgets('ein Balken füllt sich so weit, wie sein Wert sagt', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 210,
            child: HolzBalken(value: 0.5, color: Color(0xFF4F9440)),
          ),
        ),
      ),
    );
    final fuellung = tester.widget<Positioned>(find.byType(Positioned).last);
    const rinne = 210.0 - BalkenMaler.rinneLinks - BalkenMaler.rinneRechts;
    expect(fuellung.width, closeTo(rinne / 2, 0.001));
    expect(fuellung.left, BalkenMaler.rinneLinks.toDouble());
  });
}
